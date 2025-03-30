// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Bubble.sol";

contract Bridge {
    address public owner;
    Bubble public immutable bubble;
    mapping(address => uint256) public accounts;

    constructor(Bubble bubble_) {
        owner = msg.sender;
        bubble = bubble_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function deposit(uint256 amount) external {
        bubble.transferFrom(msg.sender, address(this), amount);
        accounts[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(accounts[msg.sender] >= amount, "Insufficient BBL in Bridge");
        accounts[msg.sender] -= amount;
        bubble.transfer(msg.sender, amount);
    }

    function fromBridge(address recipient, uint256 amount) external onlyOwner {
        accounts[recipient] += amount;
    }

    function toBridge(address recipient, uint256 amount) external onlyOwner {
        require(accounts[recipient] >= amount, "Insufficient BBL in Bridge");
        accounts[recipient] -= amount;
    }
}
