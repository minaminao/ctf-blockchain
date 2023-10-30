// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ISimpleBank.sol";

contract Challenge {
    ISimpleBank public immutable BANK;

    constructor(ISimpleBank bank) {
        BANK = bank;
    }

    function isSolved() external view returns (bool) {
        return address(BANK).balance == 0;
    }
}
