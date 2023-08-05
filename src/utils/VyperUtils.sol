// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";

contract VyperUtils {
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function deploy(string memory fileName) public payable returns (address addr) {
        bytes memory code = compile(fileName);
        uint256 value = msg.value;

        assembly {
            addr := create(value, add(code, 0x20), mload(code))
        }
    }

    function compile(string memory fileName) public returns (bytes memory code) {
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = fileName;
        code = vm.ffi(cmds);
    }

    function compileRuntime(string memory fileName) public returns (bytes memory code) {
        string[] memory cmds = new string[](3);
        cmds[0] = "vyper";
        cmds[1] = fileName;
        cmds[2] = "-f bytecode_runtime";
        code = vm.ffi(cmds);
    }
}
