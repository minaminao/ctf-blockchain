// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../Ethernaut/Level.sol";
import "./Force.sol";

contract ForceFactory is Level {
    function createInstance(address /* _player */) public payable override returns (address) {
        return address(new Force());
    }

    function validateInstance(address payable _instance, address /* _player */) public view override returns (bool) {
        Force instance = Force(_instance);
        return address(instance).balance > 0;
    }
}
