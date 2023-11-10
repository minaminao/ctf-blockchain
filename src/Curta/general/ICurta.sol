// SPDX-License-Identifier: MIT
// from: https://github.com/waterfall-mkt/curta/blob/main/src/interfaces/ICurta.sol
pragma solidity ^0.8.17;
import { IPuzzle } from "./IPuzzle.sol";

interface ICurta {

    error IncorrectSolution();

    event SolvePuzzle(uint32 indexed id, address indexed solver, uint256 solution, uint8 phase);

    struct PuzzleData {
        IPuzzle puzzle;
        uint40 addedTimestamp;
        uint40 firstSolveTimestamp;
    }
    function solve(uint32 _puzzleId, uint256 _solution) external payable;
}
