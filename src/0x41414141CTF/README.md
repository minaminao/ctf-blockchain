# 0x41414141 CTF

Network: Rinkeby

**Table of Contents**
- [sanity check](#sanity-check)
- [secure enclave](#secure-enclave)
- [crackme.sol](#crackmesol)
- [Crypto Casino](#crypto-casino)
- [Rich Club](#rich-club)

## sanity check

Address: `0x5CDd53b4dFe8AE92d73F40894C67c1a6da82032d`

```solidity
pragma solidity ^0.7.0;

contract sanity_check {
    function welcome() public pure returns (string memory) {
        return "flag{}";
    }
}
```

**Exploit**
```sh
$ cast call 0x5CDd53b4dFe8AE92d73F40894C67c1a6da82032d "welcome()(string memory)"
flag{1t_1s_jus7_th3_st@rt}
```

## secure enclave

Address: `0x9B0780E30442df1A00C6de19237a43d4404C5237`

```solidity
pragma solidity ^0.6.0;

contract secure_enclave {
    event pushhh(string alert_text);

    struct Secret {
        address owner;
        string secret_text;
    }

    mapping(address => Secret) private secrets;

    function set_secret(string memory text) public {
        secrets[msg.sender] = Secret(msg.sender, text);
        emit pushhh(text);
    }

    function get_secret() public view returns (string memory) {
        return secrets[msg.sender].secret_text;
    }
}
```

**Exploit**
Decode logs using Web3.py.

```python
# https://www.quicknode.com/docs/ethereum/eth_getLogs
import os
from web3 import Web3, HTTPProvider

w3 = Web3(HTTPProvider(os.environ["RPC_RINKEBY"]))
logs = w3.eth.get_logs({'address': '0x9B0780E30442df1A00C6de19237a43d4404C5237', "fromBlock": hex(7917381), "toBlock": hex(7917398)})

for log in logs:
    print(bytes.fromhex(log["data"][2:])[0x40:])
```

```sh
$ python src/0x41414141CTF/SecureEnclave/exploit.py
b'first\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b'dope\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b'test test test\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b'll\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b'flag{3v3ryth1ng_1s_BACKD00R3D_0020}\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b'wow\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
b"that's truly super cool\x00\x00\x00\x00\x00\x00\x00\x00\x00"
b'aaaaaa\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
```

## crackme.sol

```solidity
pragma solidity ^0.6.0;

contract crack_me {
    function gib_flag(uint256 arg1, string memory arg2, uint256 arg3) public view returns (uint256[]) {
        //arg3 is a overflow
        require(arg3 > 0, "positive nums only baby");
        if ((arg1 ^ 0x70) == 20) {
            if (keccak256(bytes(decrypt(arg2))) == keccak256(bytes("offshift ftw"))) {
                uint256 check3 = arg3 + 1;
                if (check3 < 1) {
                    return flag;
                }
            }
        }
        return "you lost babe";
    }

    function decrypt(string memory encrypted_text) private pure returns (string memory) {
        uint256 length = bytes(encrypted_text).length;
        for (uint256 i = 0; i < length; i++) {
            bytes1 char = bytes(encrypted_text)[i];
            assembly {
                char := byte(0, char)
                if and(gt(char, 0x60), lt(char, 0x6E)) { 
                    char := add(0x7B, sub(char, 0x61)) 
                }
                if iszero(eq(char, 0x20)) {
                    mstore8(add(add(encrypted_text, 0x20), mul(i, 1)), sub(char, 16)) 
                }
            }
        }
        return encrypted_text;
    }
}
```

**Exploit**
Use a decompiler because the flag is embedded.

```sh
$ python src/0x41414141CTF/Crackme/exploit.py
C0ngr@75_Y0u_CR@CK3D_m3854
```

## Crypto Casino

Address: 0x186d5d064545f6211dD1B5286aB2Bc755dfF2F59

```solidity
pragma solidity ^0.6.0;

contract casino {
    bytes32 private seed;
    mapping(address => uint256) public consecutiveWins;

    constructor() {
        seed = keccak256("satoshi nakmoto");
    }

    function bet(uint256 guess) public {
        uint256 num = uint256(keccak256(abi.encodePacked(seed, block.number))) ^ 0x539;
        if (guess == num) {
            consecutiveWins[msg.sender] = consecutiveWins[msg.sender] + 1;
        } else {
            consecutiveWins[msg.sender] = 0;
        }
    }

    function done() public view returns (uint16[] memory) {
        if (consecutiveWins[msg.sender] > 1) {
            return [];
        }
    }
}
```

**Exploit**

Call `done` using Foundry cheatcodes without calling `bet`.

```solidity
interface IChallenge {
    function done() external view returns (uint16[] memory);
}

contract Exploit is Script {
    function run() public {
        address target = 0x186d5d064545f6211dD1B5286aB2Bc755dfF2F59;
        
        bytes32 slot = bytes32(uint256(1));
        bytes32 consecutiveWinsSlot = keccak256(bytes.concat(bytes32(uint256(uint160(address(this)))), slot));
        vm.store(target, consecutiveWinsSlot, bytes32(uint256(2)));
        IChallenge(target).done();
    }
}
```

```sh
$ python src/0x41414141CTF/CryptoCasino/decode.py
flag{D3CN7R@l1Z3D_C@51N0S_5uck531}⏎ 
```

## Rich Club
Use Flash Swap.

```
forge script src/0x41414141CTF/RichClub/Exploit.s.sol:ExploitScript -vvvvv
```
