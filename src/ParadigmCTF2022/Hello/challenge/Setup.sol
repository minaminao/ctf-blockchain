pragma solidity ^0.8.0;

import "./Hello.sol";

contract Setup {
    Hello public hello;

    constructor() {
        hello = new Hello();
    }

    function isSolved() public view returns (bool) {
        return hello.solved();
    }
}