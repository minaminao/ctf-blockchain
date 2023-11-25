// SPDX-License-Identifier: MIT
// from: https://github.com/waterfall-mkt/curta/blob/main/src/Curta.sol
pragma solidity ^0.8.13;

import {ICurta} from "./ICurta.sol";
import {IPuzzle} from "./IPuzzle.sol";

contract Curta is ICurta {
    uint32 public puzzleId;
    mapping(uint32 => PuzzleData) public getPuzzle;

    function solve(uint32 _puzzleId, uint256 _solution) external payable {
        PuzzleData memory puzzleData = getPuzzle[_puzzleId];
        IPuzzle puzzle = puzzleData.puzzle;

        if (!puzzle.verify(puzzle.generate(msg.sender), _solution)) {
            revert IncorrectSolution();
        }

        emit SolvePuzzle({id: _puzzleId, solver: msg.sender, solution: _solution, phase: 0});
    }

    function addPuzzle(IPuzzle _puzzle, uint256 /* _tokenId */ ) external {
        uint32 curPuzzleId = ++puzzleId;
        unchecked {
            getPuzzle[curPuzzleId] =
                PuzzleData({puzzle: _puzzle, addedTimestamp: uint40(block.timestamp), firstSolveTimestamp: 0});
        }
    }

    function setPuzzleId(uint32 _puzzleId) external {
        puzzleId = _puzzleId;
    }
}
