// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

contract Challenge1Test is Test {
    function test() public {
        // 6 bytes
        Solver solver = Solver(HuffDeployer.deploy("HuffChallenge/challenge1/Solver"));
        emit log_uint(address(solver).code.length);

        // 14 gas
        uint32 blockNumber = solver.blockNumber();

        assertEq(blockNumber, block.number);
    }
}

interface Solver {
    function blockNumber() external returns (uint32);
}
