// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Contract.sol";

contract ContractTest is Test {
    address instanceAddress = 0x445D0FA7FA12A85b30525568DFD09C3002F2ADe5;

    function setUp() public {
        string memory RPC_GOERLI = vm.envString("RPC_GOERLI");
        vm.createSelectFork(RPC_GOERLI, 7335645); 
    }

    function test() public {
        Contract instance = Contract(instanceAddress);
        emit log_uint(instance.lastXDigits()); // 100
        emit log_uint(instance.mod()); // 45

        // block.number(7335645) % lastXDigits(100) == mod(45)
        instance.cantCallMe();
    }
}
