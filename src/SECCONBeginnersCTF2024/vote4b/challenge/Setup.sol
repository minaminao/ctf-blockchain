// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ballot} from "./Ballot.sol";

contract Setup {
    bool public registered;
    Ballot public ballot;

    constructor() {
        ballot = new Ballot(address(this));
    }

    function register() public {
        require(!registered, "Already registered");
        registered = true;
        ballot.registerAsResident(msg.sender);
    }

    function isSolved() public view returns (bool) {
        return ballot.votes(address(this)) >= 10;
    }
}
