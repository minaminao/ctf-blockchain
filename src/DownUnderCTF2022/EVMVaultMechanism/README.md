# EVM Vault Mechanism

The goal is not clear, but since the source code of the contract is not given, it can be expected that it is a challenge of reversing the contract.

Foundry Setting:
```
export PRIVATE_KEY=0x1ea9bac3bf81ef823e62965c91b7a737e9520e4071d545e7eaf4e56f43469d80
export INSTANCE_ADDRESS=0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8
export FOUNDRY_ETH_RPC_URL=https://blockchain-evmvault-1a2ea45a5f20b79f-eth.2022.ductf.dev:443/
```

If the blocks are examined using `cast`, several transactions can be found.
Reading those transactions, we can find that the contract is deployed at address `0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8`.

Get the bytecode of the contract:

```
$ cast code 0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8
0x600836101561000e5760006000fd5b610168565b600065069b135a06c38201608081029050650b3abdcef1f18118905080660346d81803d47114159150505b919050565b600081600f526004600f2066fd28448c97d19c8160c81c14159150505b919050565b6000338031813b823f63ff000000811660181c6004600b6007873c600460072060ff811660778114838614670de0b6b3a76400008811607760ff8b1614020202159750505050505050505b919050565b600062ffff00821660081c600d8160071b0160020260ff8460181c166101010260ff60ff8616600202166003014303408083018218600014159450505050505b919050565b6000303f806007526000600060005b6020811015610142576001600187831c1614156101365760ff600751600883021c16830192506001820191505b5b600181019050610109565b50601181146105398306610309140293505050505b919050565b6000600090505b919050565b60003560e01c60043560e01c81637672667981146101cc57634141414181146101ea576342424242811461020e57634343434381146102325763444444448114610256576345454545811461027a57634646464681146102a05760006000fd6102c0565b6113375460ff8114156101e457600165736f6c766564555b506102c0565b6101f382610013565b8015156102085761133754604a811861133755505b506102c0565b61021782610043565b80151561022c576113375460d1811861133755505b506102c0565b61023b82610065565b80151561025057611337546064811861133755505b506102c0565b61025f826100b5565b801515610274576113375460b2811861133755505b506102c0565b610283826100fa565b600181141561029a57611337546063811861133755505b506102c0565b6102a98261015c565b8015156102be576113375460c4811861133755505b505b50005050
```

Decompile this bytecode with `panoramix` to get an overview of the contract:

```py
def storage:
  stor1337 is uint256 at storage 0x1337
  stor736F is uint256 at storage 0x736f6c766564

def unknown46464646() payable: 
  stor1337 = stor1337 xor 196

def unknown76726679() payable: 
  if stor1337 == 255:
      stor736F = 1

def unknown44444444() payable: 
  if not 0 xor block.hash(block.number - 3) + 26:
      stor1337 = stor1337 xor 178

def unknown45454545(uint256 _param1) payable: 
  idx = 0
  while idx < 32:
      idx = idx + 1
      continue 

def unknown42424242(uint32 _param1) payable: 
  if sha3(_param1) % 72057594037927936 >> 200 == 71257443989442972:
      stor1337 = stor1337 xor 209

def unknown41414141(uint256 _param1) payable: 
  if 922318859916401 == 128 * (uint32(_param1) >> 224) + 7263114364611 xor 12346920464881:
      stor1337 = stor1337 xor 74

def unknown43434343() payable: 
  if uint8(caller) == 119 * eth.balance(caller) > 10^18 * ext_code.size(caller) == Mask(8, 24, ext_code.hash(caller)) >> 24 * uint8(sha3(ext_code.copy(caller, 11 len 4))) == 119:
      stor1337 = stor1337 xor 100

def _fallback() payable:
  require calldata.size >= 8
  if uint32(call.func_hash) >> 224 == 1987208825:
      if stor1337 == 255:
          stor736F = 1
  else:
      if uint32(call.func_hash) >> 224 == 1094795585:
          if 922318859916401 == 128 * (uint32(_param1) >> 224) + 7263114364611 xor 12346920464881:
              stor1337 = stor1337 xor 74
      else:
          if uint32(call.func_hash) >> 224 == 1111638594:
              if sha3(uint32(_param1)) % 72057594037927936 >> 200 == 71257443989442972:
                  stor1337 = stor1337 xor 209
          else:
              if uint32(call.func_hash) >> 224 == 1128481603:
                  if uint8(caller) == 119 * eth.balance(caller) > 10^18 * ext_code.size(caller) == Mask(8, 24, ext_code.hash(caller)) >> 24 * uint8(sha3(ext_code.copy(caller, 11 len 4))) == 119:
                      stor1337 = stor1337 xor 100
              else:
                  if uint32(call.func_hash) >> 224 == 1145324612:
                      if not 0 xor block.hash(block.number - 3) + 26:
                          stor1337 = stor1337 xor 178
                  else:
                      if uint32(call.func_hash) >> 224 == 1162167621:
                          idx = 0
                          while idx < 32:
                              idx = idx + 1
                              continue 
                      else:
                          require uint32(call.func_hash) >> 224 == 1179010630
                          stor1337 = stor1337 xor 196
```
The result is quite wrong, but it seems that by setting `0xff` to the value in slot `0x1337` and calling the function whose signature is `0x76726679`, the value in slot `0x736f6c766564` is set to `1` and the flag is gotten.

Find out where to write slot `0x1337` using [erever](https://github.com/minaminao/erever):

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic | grep SSTORE
0x1e3: SSTORE(0x736f6c766564, 0x01)
0x206: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x4a))
0x22a: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xd1))
0x24e: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x64))
0x272: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xb2))
0x298: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x63))
0x2bc: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xc4))
```

There are six locations for the process to write to slot `0x1337` using `SSTORE`.
These `SSTORE`s can be expected to correspond to processes that will be executed once the conditions of each function are satisfied.

List of function signatures and function start locations:

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x168 -n 10
0x168: JUMPDEST
0x180: JUMPI(0x01cc, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x76726679))
0x18b: JUMPI(0x01ea, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x41414141))
0x196: JUMPI(0x020e, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x42424242))
0x1a1: JUMPI(0x0232, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x43434343))
0x1ac: JUMPI(0x0256, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x44444444))
0x1b7: JUMPI(0x027a, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x45454545))
0x1c2: JUMPI(0x02a0, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x46464646))
0x1c7: REVERT(0x00, 0x00)
0x1cb: JUMP(0x02c0)
```


The table is summarized as follows.

| Function Signature | Start Location | XOR  |
| ------------------ | -------------- | ---- |
| 0x41414141         | 0x01cc         | 0x4a |
| 0x42424242         | 0x01ea         | 0xd1 |
| 0x43434343         | 0x020e         | 0x64 |
| 0x44444444         | 0x0232         | 0xb2 |
| 0x45454545         | 0x0256         | 0x63 |
| 0x46464646         | 0x02a0         | 0xc4 |

Calculate which of a set of functions consisting of six functions should be executed to set the slot `0x1337` to `0xff`:
```py
x = [0x4a, 0xd1, 0x64, 0xb2, 0x63, 0xc4]

for mask in range(1 << len(x)):
    t = 0
    for i in range(len(x)):
        if (mask >> i) & 1:
            t ^= x[i]
    if t != 255:
        continue
    for i in range(len(x)):
        if (mask >> i) & 1:
            print(str(i) + " ", end="")
    print()
```

Two candidates were found.
- 0 1 2 
- 0 2 3 4 

It is sufficient to execute either set of functions.

Examine locations where `JUMPI` and `SSTORE` appear in all functions:

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x01ea -n 20 --trace | grep -e JUMPI -e SSTORE
0x1fa: JUMPI(0x0208, ISZERO(ISZERO(ISZERO((0x0346d81803d471 == (((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1))))))
0x206: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x4a))

$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x020e -n 20 --trace | grep -e JUMPI -e SSTORE
0x21e: JUMPI(0x022c, ISZERO(ISZERO(ISZERO((SHR(0xc8, KECCAK256(0x0f, 0x04)) == 0xfd28448c97d19c)))))
0x22a: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xd1))

$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x0232 -n 20 --trace | grep -e JUMPI -e SSTORE
0x242: JUMPI(0x0250, ISZERO(ISZERO(ISZERO((((((CALLER() & 0xff) == 0x77) * (BALANCE(CALLER()) > 0x0de0b6b3a7640000)) * (EXTCODESIZE(CALLER()) == SHR(0x18, (EXTCODEHASH(CALLER()) & 0xff000000)))) * ((KECCAK256(0x07, 0x04) & 0xff) == 0x77))))))
0x24e: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x64))

$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x0256 -n 20 --trace | grep -e JUMPI -e SSTORE
0x266: JUMPI(0x0274, ISZERO(ISZERO(ISZERO((0x00 == ((0x0101 * (SHR(0x18, var_1) & 0xff)) ^ ((0x02 * (0x07 << SHR(0x08, (var_1 & 0xffff00))) + 0x0d)) + BLOCKHASH((NUMBER() - (0x03 + ((0x02 * (var_1 & 0xff)) & 0xff)))))))))))
0x272: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xb2))

$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x027a -n 20 --trace | grep -e JUMPI -e SSTORE
0x112: JUMPI(0x0142, ISZERO((0x00 < 0x20)))
0x120: JUMPI(0x0136, ISZERO(((SHR(0x00, var_1) & 0x01) == 0x01)))
0x112: JUMPI(0x0142, ISZERO(((0x00 + 0x01) < 0x20)))
0x120: JUMPI(0x0136, ISZERO(((SHR((0x00 + 0x01), var_1) & 0x01) == 0x01)))

$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x02a0 -n 20 --trace | grep -e JUMPI -e SSTORE
0x2b0: JUMPI(0x02be, ISZERO(ISZERO(0x00)))
0x2bc: SSTORE(0x1337, (SLOAD(0x1337) ^ 0xc4))
```

The above results show that:
- It is possible to compute parameters that satisfy the condition of the function with the function signature `0x41414141`.
    - `0x0346d81803d471 == (((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1)`: It can be reversed for `var_1`.
- It is not possible to compute parameters that satisfy the condition of the function with the function signature `0x42424242`.
    - `SHR(0xc8, KECCAK256(0x0f, 0x04)) == 0xfd28448c97d19c`: It is difficult to calculate a parameter that satisfy this.
- It is possible to compute parameters that satisfy the following conditions of the function with the function signature `0x43434343`.
    - `CALLER() & 0xff) == 0x77`
    - `BALANCE(CALLER()) > 0x0de0b6b3a7640000`
    - `EXTCODESIZE(CALLER()) == SHR(0x18, (EXTCODEHASH(CALLER()) & 0xff000000))`
    - `KECCAK256(0x07, 0x04) & 0xff) == 0x77))`
- It is possible to compute parameters that satisfy the condition of the function with the function signature `0x44444444`.
    - `(0x00 == ((0x0101 * (SHR(0x18, var_1) & 0xff)) ^ ((0x02 * (0x07 << SHR(0x08, (var_1 & 0xffff00))) + 0x0d)) + BLOCKHASH((NUMBER() - (0x03 + ((0x02 * (var_1 & 0xff)) & 0xff))))))`
- Since the function with the function signature `0x45454545` contains a loop, further investigation is needed for this.
- It is not possible to compute parameters that satisfy the condition of the function with the function signature `0x46464646`.

Thus, of the two candidates, it is correct to execute the functions with the signatures `0x41414141`, `0x43434343`, `0x44444444`, and `0x45454545`.

**Solve `0x41414141`:**

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x01ea -n 5
0x1ea: JUMPDEST
0x1f2: JUMP(0x13)
0x1f3: JUMPDEST
0x1fa: JUMPI(0x0208, ISZERO(ISZERO(var_1)))
0x206: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x4a))
```

It immediately jumped to the location `0x13`.
To follow the process flow from `0x13`, examine it in trace mode of erever, which executes `JUMP`.

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x01ea -n 20 --trace
0x1ea: JUMPDEST
0x1f2: JUMP(0x13)
0x013: JUMPDEST
0x024: POP((var_1 + 0x069b135a06c3))
0x02f: POP(((var_1 + 0x069b135a06c3) * 0x80))
0x03c: POP(0x00)
0x03d: POP((((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1))
0x03e: JUMPDEST
0x041: POP(var_1)
0x042: JUMP(0x01f3)
0x1f3: JUMPDEST
0x1fa: JUMPI(0x0208, ISZERO(ISZERO(ISZERO((0x0346d81803d471 == (((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1))))))
0x206: SSTORE(0x1337, (SLOAD(0x1337) ^ 0x4a))
0x207: POP(SLOAD(0x1337))
0x208: JUMPDEST
0x209: POP(ISZERO((0x0346d81803d471 == (((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1))))
0x20d: JUMP(0x02c0)
0x2c0: JUMPDEST
0x2c1: POP(var_0)
0x2c2: STOP()
```

If `ISZERO(ISZERO(ISZERO((0x0346d81803d471 == (((var_1 + 0x069b135a06c3) * 0x80) ^ 0x0b3abdcef1f1)))))` is not 0, it jumps to `0x0208`.

The `var_1` is the function argument.
`SHR(0xe0, CALLDATALOAD(0x04))` in the result of the following command is `var_1`.

```
$ erever -f src/DownUnderCTF2022/EVMVaultMechanism/contract.txt --symbolic --entrypoint 0x168 -n 2 --show-symbolic-stack
0x168: JUMPDEST
        stack   []
0x180: JUMPI(0x01cc, (SHR(0xe0, CALLDATALOAD(0x00)) == 0x76726679))
        stack   [SHR(0xe0, CALLDATALOAD(0x00)), SHR(0xe0, CALLDATALOAD(0x04)), SHR(0xe0, CALLDATALOAD(0x00))]
```

The argument satisfying the condition can be calculated in Solidity as follows

```solidity
uint256 param1 = ((0x0346d81803d471 ^ 0xb3abdcef1f1) / uint256(0x80) - 0x069b135a06c3) << 224;
```

**Solve `0x43434343`:**

Use the following contract written in Huff.

```js
#define macro MAIN() = takes (0) returns (0) {
    0xe8000000000000000000 // dummy data for `EXTCODESIZE(CALLER()) == SHR(0x18, (EXTCODEHASH(CALLER()) & 0xff000000))`
    0x450000 // dummy data for `KECCAK256(0x07, 0x04) & 0xff) == 0x77))`
    
    0x4343434300000000000000000000000000000000000000000000000000000000 0x00 mstore

    0x00 // retSize
    0x00 // retOffset
    0x08 // argsSize
    0x00 // argsOffset
    0x00 // value
    0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8 // address
    0xffff // gas
    call
}
```

The dummy data was determined by the following Python script.

```py
from Crypto.Hash import keccak

for i in range(256**3):
    k = keccak.new(digest_bits=256)
    data = b"\x62" + i.to_bytes(3, "little")
    k.update(data)
    if k.digest()[-1] == 0x77:
        print(data.hex())
        break

bytecode = bytes.fromhex("6901020304050607080910624500007f434343430000000000000000000000000000000000000000000000000000000060005260006000600860006000736e4198c61c75d1b4d1cbcd00707aac7d76867cf861fffff1")
for i in range(256**10):
    bytecode_ = bytecode.replace(bytes.fromhex("01020304050607080910"), i.to_bytes(10, "little"))
    assert len(bytecode_) == len(bytecode)
    k = keccak.new(digest_bits=256)
    k.update(bytecode_)
    if k.digest()[-4] == len(bytecode):
        print(bytecode_.hex(), k.hexdigest(), hex(len(bytecode)))
        break
```

**Solve `0x44444444`:**

The result of `BLOCKHASH` must be zero to be solved.
The argument satisfying the condition is computed fast using the program written in C++.

```cpp
#include <iostream>
using namespace std;

int main() {
  for (long long x = 0; x < 1LL << 32; x++) {
    long long a = ((((x & 0xffff00) >> 0x08) << 0x07) + 0x0d) * 0x02;
    long long b = ((x >> 0x18) & 0xff) * 0x0101;
    long long c = ((x & 0xff) * 0x02) & 0xff;
    if ((a ^ b) == 0 && c > 0xf0) {
      cout << x << " " << a << " " << b << " " << c << endl;
      break;
    }
  }
  return 0;
}
```

**Solve `0x45454545`:**

The argument satisfying the condition is calculated as follows.

```py
x = bytes.fromhex("6bca38432e686d0a2ab98d1cab5f21998075ffef811b6bb03d52812fa9a8f752")

for mask in range(1 << len(x)):
    t = 0
    c = 0
    for i in range(len(x)):
        if (mask >> i) & 1:
            t += x[len(x) - 1 - i]
            c += 1
    if t % 0x0539 == 0x0309 and c == 0x11:
        print(bin(mask), mask, t, c)
        break
```

**Exploit:**

Therefore, the exploit is:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract ExploitScript is Script {
    address vaultAddress = 0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8;

    function run() public {
        vm.startBroadcast();

        // 0x41414141
        {
            uint256 param1 = ((0x0346d81803d471 ^ 0xb3abdcef1f1) / uint256(0x80) - 0x069b135a06c3) << 224;
            vaultAddress.call(abi.encodeWithSelector(hex"41414141", param1));
        }

        // 0x43434343
        {
            bytes memory creationCode =
                hex"60568060093d393df369e8000000000000000000624500007f434343430000000000000000000000000000000000000000000000000000000060005260006000600860006000736e4198c61c75d1b4d1cbcd00707aac7d76867cf861fffff1";
            for (int256 i = 0; i < 256; i++) {
                address addr;
                assembly {
                    addr := create(0, add(creationCode, 0x20), mload(creationCode))
                }
            }
        }

        // 0x44444444
        {
            uint256 param1 = 436214393 << 224;
            vaultAddress.call(abi.encodeWithSelector(hex"44444444", param1));
        }

        // 0x45454545
        {
            uint256 param1 = 1021951 << 224;
            vaultAddress.call(abi.encodeWithSelector(hex"45454545", param1));
        }

        // 0x76726679
        {
            uint256 param1 = 0xdeadbeaf << 224;
            vaultAddress.call(abi.encodeWithSelector(hex"76726679", param1));
        }
    }
}
```

Flag: `DUCTF{b3y0nd_th3_v4ult_li3s_a_w3ll_d3serv3d_fl4g}`


**Appendix: a code for `forge test --debug`:**
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract ExploitTest is Test {
    address vaultAddress = 0x6E4198C61C75D1B4D1cbcd00707aAC7d76867cF8;

    function setUp() public {
        bytes memory bytecode =
            hex"600836101561000e5760006000fd5b610168565b600065069b135a06c38201608081029050650b3abdcef1f18118905080660346d81803d47114159150505b919050565b600081600f526004600f2066fd28448c97d19c8160c81c14159150505b919050565b6000338031813b823f63ff000000811660181c6004600b6007873c600460072060ff811660778114838614670de0b6b3a76400008811607760ff8b1614020202159750505050505050505b919050565b600062ffff00821660081c600d8160071b0160020260ff8460181c166101010260ff60ff8616600202166003014303408083018218600014159450505050505b919050565b6000303f806007526000600060005b6020811015610142576001600187831c1614156101365760ff600751600883021c16830192506001820191505b5b600181019050610109565b50601181146105398306610309140293505050505b919050565b6000600090505b919050565b60003560e01c60043560e01c81637672667981146101cc57634141414181146101ea576342424242811461020e57634343434381146102325763444444448114610256576345454545811461027a57634646464681146102a05760006000fd6102c0565b6113375460ff8114156101e457600165736f6c766564555b506102c0565b6101f382610013565b8015156102085761133754604a811861133755505b506102c0565b61021782610043565b80151561022c576113375460d1811861133755505b506102c0565b61023b82610065565b80151561025057611337546064811861133755505b506102c0565b61025f826100b5565b801515610274576113375460b2811861133755505b506102c0565b610283826100fa565b600181141561029a57611337546063811861133755505b506102c0565b6102a98261015c565b8015156102be576113375460c4811861133755505b505b50005050";
        vm.etch(vaultAddress, bytecode);
        vm.store(vaultAddress, bytes32(uint256(0x1337)), 0);
    }

    function test41414141() public {
        uint256 param1 = ((0x0346d81803d471 ^ 0xb3abdcef1f1) / uint256(0x80) - 0x069b135a06c3) << 224; // 80486202565115466310871716035167973708900655882045620911654993608634601046016
        vaultAddress.call(abi.encodeWithSelector(hex"41414141", param1));
        assertTrue(vm.load(vaultAddress, bytes32(uint256(0x1337))) > 0);
    }

    function test43434343() public {
        address playerAddress = 0x9B78dD13A201518D87A9f4F9b8165b4Df2B391a4;
        vm.startPrank(playerAddress, playerAddress);
        bytes memory creationCode =
            hex"60568060093d393df369e8000000000000000000624500007f434343430000000000000000000000000000000000000000000000000000000060005260006000600860006000736e4198c61c75d1b4d1cbcd00707aac7d76867cf861fffff1";
        bytes memory runtimeCode =
            hex"69e8000000000000000000624500007f434343430000000000000000000000000000000000000000000000000000000060005260006000600860006000736e4198c61c75d1b4d1cbcd00707aac7d76867cf861fffff1";
        address addr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(bytes1(0xff), playerAddress, bytes32(uint256(402)), keccak256(creationCode))
                    )
                )
            )
        );
        vm.etch(addr, runtimeCode);
        vm.deal(addr, 0x0de0b6b3a7640001);
        addr.call("");
        assertTrue(vm.load(vaultAddress, bytes32(uint256(0x1337))) > 0);
    }

    function test44444444() public {
        uint256 param1 = 436214393 << 224;
        vm.roll(5);
        vaultAddress.call(abi.encodeWithSelector(hex"44444444", param1));
        assertTrue(vm.load(vaultAddress, bytes32(uint256(0x1337))) > 0);
    }

    function test45454545() public {
        uint256 param1 = 1021951 << 224; // 0b11111001011111111111
        vaultAddress.call(abi.encodeWithSelector(hex"45454545", param1));
        assertTrue(vm.load(vaultAddress, bytes32(uint256(0x1337))) > 0);
    }
}
``

