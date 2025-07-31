// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Ethernaut/Level.sol";
import "./HigherOrder-8.sol";
import "src/utils/Create.sol";

contract HigherOrderFactory is Level {
    function createInstance(address /* _player */) public payable override returns (address) {
        return Create.deploy("HigherOrder.sol:HigherOrder");
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        HigherOrder instance = HigherOrder(_instance);
        return instance.commander() == _player;
    }
}
