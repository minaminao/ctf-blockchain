// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";

library Create {
    address constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm constant vm = Vm(VM_ADDRESS);

    event Log(uint256);

    function create(string memory contractName) external returns (address) {
        return _create(contractName, 0, "");
    }

    function create(string memory contractName, uint256 value) external returns (address) {
        return _create(contractName, value, "");
    }

    function create(string memory contractName, bytes memory data) external returns (address) {
        return _create(contractName, 0, data);
    }

    function create(string memory contractName, uint256 value, bytes memory data) external returns (address) {
        return _create(contractName, value, data);
    }

    function _create(string memory contractName, uint256 value, bytes memory data) internal returns (address) {
        // Ref: https://book.getfoundry.sh/cheatcodes/get-code#examples
        // Example of contractName: AlienCodex.sol:AlienCodex
        bytes memory bytecode = abi.encodePacked(vm.getCode(contractName), data);
        address addr;
        assembly {
            addr := create(value, add(bytecode, 0x20), mload(bytecode))
        }
        return addr;
    }
}
