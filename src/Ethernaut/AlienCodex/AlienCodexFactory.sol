// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Ethernaut/Level.sol";
import "forge-std/Script.sol";
import "forge-std/Vm.sol";
import "./AlienCodex-08.sol";

contract AlienCodexFactory is Level {
    function createInstance(address _player) public payable override returns (address) {
        _player;

        address VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
        Vm vm = Vm(VM_ADDRESS);

        // https://book.getfoundry.sh/cheatcodes/get-code#examples
        bytes memory bytecode = abi.encodePacked(vm.getCode("AlienCodex.sol:AlienCodex"));
        address instanceAddress;
        assembly {
            instanceAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        return instanceAddress;
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        AlienCodex instance = AlienCodex(_instance);
        return instance.owner() == _player;
    }
}
