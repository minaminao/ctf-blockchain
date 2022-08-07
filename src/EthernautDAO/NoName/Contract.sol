// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    uint public lastXDigits;
    uint public mod;
    bool public done;
    address public winner;

    constructor(uint digits, uint m) {
        lastXDigits = digits;
        mod = m;
        done = false;
    }

    function cantCallMe() public {
        require(done == false, "Already done");
        uint res = block.number % mod;
        require(res == lastXDigits, "Can't call me !");
        winner = msg.sender;
        done = true;
    }
}