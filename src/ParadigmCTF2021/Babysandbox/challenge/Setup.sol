pragma solidity ^0.8.0;

import "./Babysandbox.sol";

contract Setup {
    BabySandbox public sandbox;

    constructor() {
        sandbox = new BabySandbox();
    }

    function isSolved() public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(sload(sandbox.slot))
        }
        return size == 0;
    }
}
