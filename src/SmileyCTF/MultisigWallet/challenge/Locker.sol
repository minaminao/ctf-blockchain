// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
/**
 * @title Locker
 * @author BrokenAppendix
 */

struct signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

event LockerDeployed(
    address lockerAddress, uint256 lockId, uint8[] v, bytes32[] r, bytes32[] s, address[] controllers, uint256 threshold
);

// SlockDotIt ECLocker factory
contract Locker {
    uint256 public immutable lockId;
    bytes32 public immutable msgHash;
    address[] public controllers;
    uint256 public immutable threshold;
    uint256 public tokens;

    mapping(bytes32 => bool) public usedSignatures;

    constructor(uint256 _lockId, signature[] memory signatures, address[] memory _controllers, uint256 _threshold) {
        require(_controllers.length >= _threshold && _threshold > 0, "Invalid config");

        lockId = _lockId;
        threshold = _threshold;
        controllers = _controllers;
        tokens = 1;

        // Compute the expected hash
        bytes32 _msgHash;
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28 bytes
            mstore(0x1C, _lockId)
            _msgHash := keccak256(0x00, 0x3c)
        }
        msgHash = _msgHash;

        validateMultiSig(signatures);

        // Flatten signature arrays
        uint8[] memory vArr = new uint8[](signatures.length);
        bytes32[] memory rArr = new bytes32[](signatures.length);
        bytes32[] memory sArr = new bytes32[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            vArr[i] = signatures[i].v;
            rArr[i] = signatures[i].r;
            sArr[i] = signatures[i].s;
        }

        emit LockerDeployed(address(this), lockId, vArr, rArr, sArr, controllers, threshold);
    }

    function distribute(signature[] memory signatures) external {
        validateMultiSig(signatures);
        tokens -= 1;
    }

    function isSolved() external view returns (bool) {
        return tokens == 0;
    }

    function validateMultiSig(signature[] memory signatures) public {
        address[] memory seen = new address[](controllers.length);
        uint256 validCount = 0;
        for (uint256 i = 0; i < signatures.length; i++) {
            address recovered = _isValidSignature(signatures[i]);
            require(!_isInArray(recovered, seen), "Same signer cannot sign multiple times");

            // Ensure no duplicate
            for (uint256 j = 0; j < validCount; j++) {
                require(seen[j] != recovered, "Duplicate signer");
            }

            /// seenの上書きはできるっちゃできる
            /// が、それができるならそもそもdistributeもできる
            seen[validCount] = recovered;
            validCount++;
        }
        require(validCount == threshold, "Not enough valid signers");
    }

    function _isValidSignature(signature memory sig) internal returns (address) {
        uint8 v = sig.v;
        bytes32 r = sig.r;
        bytes32 s = sig.s;
        address _address = ecrecover(msgHash, v, r, s);
        require(_isInArray(_address, controllers), "Signer is not a controller");

        bytes32 signatureHash = keccak256(abi.encode([uint256(r), uint256(s), uint256(v)]));
        require(!usedSignatures[signatureHash], "Signature has already been used");
        usedSignatures[signatureHash] = true;
        return _address;
    }

    function _isInArray(address addr, address[] memory arr) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == addr) return true;
        }
        return false;
    }
}

/**
 * @dev This is the Setup Contract which checks if the challenge is solved or not
 * (not a part of the challenge)
 */

// Private Keys randomly generated online
// Signatures generated in signature_generator.js
// Signatures retrieved by player by reading events in read_signatures.js

contract SetupLocker is Setup {
    constructor(address player_address) payable Setup(player_address) {}

    signature[] signatures;
    address[] controllers;

    function deploy() public override returns (address) {
        uint256 lockId = 0;
        signatures.push(
            signature({
                v: 27,
                r: 0x36ade3c84a9768d762f611fbba09f0f678c55cd73a734b330a9602b7426b18d9,
                s: 0x6f326347e65ae8b25830beee7f3a4374f535a8f6eedb5221efba0f17eceea9a9
            })
        );
        signatures.push(
            signature({
                v: 28,
                r: 0x57f4f9e4f2ef7280c23b31c0360384113bc7aa130073c43bb8ff83d4804bd2a7,
                s: 0x694430205a6b625cc8506e945208ad32bec94583bf4ec116598708f3b65e4910
            })
        );
        signatures.push(
            signature({
                v: 27,
                r: 0xe2e9d4367932529bf0c5c814942d2ff9ae3b5270a240be64b89f839cd4c78d5d,
                s: 0x6c0c845b7a88f5a2396d7f75b536ad577bbdb27ea8c03769a958b2a9d67117d2
            })
        );
        controllers.push(0x9dF23180748A2E168a24F5BBAB2a50eE38A7d309);
        controllers.push(0x8Ab87699287fe024A8b4d53385AC848930b19FfF);
        controllers.push(0x10Bab59adbDd06E90996361181b7d2129A5Eeb5A);
        uint256 threshold = 3;

        Locker _instance = new Locker(lockId, signatures, controllers, threshold);

        /// 作問ミスを修正
        challenge = address(_instance);

        return address(_instance);
    }

    function isSolved() external view override returns (bool) {
        return Locker(challenge).isSolved();
    }
}
