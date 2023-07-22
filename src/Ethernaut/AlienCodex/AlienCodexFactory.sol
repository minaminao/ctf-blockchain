// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Ethernaut/Level.sol";
import "./AlienCodex-08.sol";
import "src/utils/Create.sol";

contract AlienCodexFactory is Level {
    function createInstance(address /* player */ ) public payable override returns (address) {
        return Create.create("AlienCodex.sol:AlienCodex", 0);
    }

    function validateInstance(address payable instanceAddr, address playerAddr) public view override returns (bool) {
        AlienCodex instance = AlienCodex(instanceAddr);
        return instance.owner() == playerAddr;
    }
}
