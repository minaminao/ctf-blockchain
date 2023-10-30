// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ISimpleBank {
    function withdraw(bytes32, uint8, bytes32, bytes32) external payable;
}
