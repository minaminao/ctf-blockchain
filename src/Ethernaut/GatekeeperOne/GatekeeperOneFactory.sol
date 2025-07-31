// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../Ethernaut/Level.sol";
import "./GatekeeperOne.sol";

contract GatekeeperOneFactory is Level {
    function createInstance(address /* _player */) public payable override returns (address) {
        GatekeeperOne instance = new GatekeeperOne();
        return address(instance);
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        GatekeeperOne instance = GatekeeperOne(_instance);
        return instance.entrant() == _player;
    }
}
