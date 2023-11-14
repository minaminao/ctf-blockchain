// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";

library Create {
    address constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm constant vm = Vm(VM_ADDRESS);

    function deploy(string memory contractName) external returns (address) {
        return _deploy(contractName, 0, "");
    }

    function deploy(string memory contractName, uint256 value) external returns (address) {
        return _deploy(contractName, value, "");
    }

    function deploy(string memory contractName, bytes memory data) external returns (address) {
        return _deploy(contractName, 0, data);
    }

    function deploy(string memory contractName, uint256 value, bytes memory data) external returns (address) {
        return _deploy(contractName, value, data);
    }

    function _deploy(string memory contractName, uint256 value, bytes memory data) internal returns (address addr) {
        // Ref: https://book.getfoundry.sh/cheatcodes/get-code#examples
        // Example of contractName: AlienCodex.sol:AlienCodex
        bytes memory bytecode = abi.encodePacked(vm.getCode(contractName), data);
        assembly {
            addr := create(value, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function computeAddr(address deployerAddr, uint256 nonce) public pure returns (address) {
        bytes memory data;
        if (nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployerAddr, bytes1(0x80));
        } else if (nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployerAddr, uint8(nonce));
        } else {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployerAddr, bytes1(0x81), uint16(nonce));
        }
        return address(uint160(uint256(keccak256(data))));
    }
}
