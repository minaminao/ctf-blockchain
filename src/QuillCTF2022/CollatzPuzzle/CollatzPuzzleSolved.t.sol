// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {CollatzPuzzle} from "./challenge/CollatzPuzzle.sol";

interface ICollatzPuzzle {
    function collatzIteration(uint256 n) external pure returns (uint256);
}

contract CollatzPuzzleSolved is Test {
    CollatzPuzzle public puzzle;
    ICollatzPuzzle public solution;

    /// @dev Setup the testing environment.
    function setUp() public {
        puzzle = new CollatzPuzzle();
        solution = ICollatzPuzzle(HuffDeployer.deploy("/QuillCTF2022/CollatzPuzzle/CollatzPuzzleSolution"));
    }

    function testSolution() public {
        assertEq(puzzle.callMe(address(solution)), true);
    }
}
