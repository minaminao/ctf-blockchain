// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Ethernaut/Level.sol";
import "./HelloEthernaut.sol";

contract HelloEthernautFactory is Level {
    function createInstance(address /* _player */) public payable override returns (address) {
        return address(new Instance("ethernaut0"));
    }

    function validateInstance(address payable _instance, address /* _player */) public view override returns (bool) {
        Instance instance = Instance(_instance);
        return instance.getCleared();
    }
}
