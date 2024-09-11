pragma solidity ^0.8.25;

import {ZOO} from "./ZOO.sol";

contract Setup {
    ZOO public immutable zoo;

    constructor() payable {
        zoo = new ZOO();
    }

    function isSolved() public view returns (bool) {
        return zoo.isSolved() == 1;
    }
}
