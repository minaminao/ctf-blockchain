// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./Lockbox2.sol";

contract Setup {
    Lockbox2 public lockbox2;

    constructor() {
        lockbox2 = new Lockbox2();
    }

    function isSolved() external view returns (bool) {
        return !lockbox2.locked();
    }
}
