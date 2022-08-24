// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Challenge3 {
    function deposit() external payable;
    function withdraw() external;
    function setWithdrawer(address) external payable;
}
