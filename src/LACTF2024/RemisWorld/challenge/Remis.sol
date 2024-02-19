// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Remis {
    mapping(address => uint256) private balances;

    event Dialogue(string message);

    constructor() {}

    function openAccount() public {
        emit Dialogue("Welcome to Remi's! Here's a token of appreciation for choosing us! <3");
        balances[msg.sender] = 10;
    }

    function sendMoney(uint256 amount, address target) public {
        balances[msg.sender] -= amount;
        balances[target] += amount;
    }

    function orderBurger() public {
        balances[msg.sender] -= 5;
    }

    function postBulletin(string calldata message) public {
        balances[msg.sender] -= 1;
        emit Dialogue(message);
    }

    function checkWallet() public view returns (uint256) {
        return balances[msg.sender];
    }
}
