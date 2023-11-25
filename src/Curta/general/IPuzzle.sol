// SPDX-License-Identifier: MIT
// from https://github.com/waterfall-mkt/curta/blob/main/src/interfaces/IPuzzle.sol
pragma solidity ^0.8.13;

interface IPuzzle {
    function name() external pure returns (string memory);

    function generate(address _seed) external returns (uint256);

    function verify(uint256 _start, uint256 _solution) external returns (bool);
}
