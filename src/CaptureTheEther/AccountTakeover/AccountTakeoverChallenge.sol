// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract AccountTakeoverChallenge {
    address owner = 0x6B477781b0e68031109f21887e6B5afEAaEB002b;
    bool public isComplete;

    function authenticate() public {
        require(msg.sender == owner);
        isComplete = true;
    }
}
