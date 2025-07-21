// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Setup {
    address public challenge;
    address public player;

    constructor(address _player) {
        player = _player;
    }

    function deploy() public virtual returns (address);
    function isSolved() external view virtual returns (bool);
}
