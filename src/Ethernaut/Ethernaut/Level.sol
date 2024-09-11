// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";

abstract contract Level is Ownable {
    constructor() Ownable(msg.sender) {}
    function createInstance(address _player) public payable virtual returns (address);

    function validateInstance(address payable _instance, address _player) public virtual returns (bool);
}
