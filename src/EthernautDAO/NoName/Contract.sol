// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    uint256 public lastXDigits;
    uint256 public mod;
    bool public done;
    address public winner;

    constructor(uint256 digits, uint256 m) {
        lastXDigits = digits;
        mod = m;
        done = false;
    }

    function cantCallMe() public {
        require(done == false, "Already done");
        uint256 res = block.number % mod;
        require(res == lastXDigits, "Can't call me !");
        winner = msg.sender;
        done = true;
    }
}
