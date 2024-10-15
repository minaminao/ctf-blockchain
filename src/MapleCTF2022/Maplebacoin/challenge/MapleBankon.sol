//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./MapleBaCoin.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MapleBankon is Ownable {
    MapleBaCoin public immutable mpbc;

    mapping(address => bool) syrupTree;
    mapping(address => uint256) balances;

    constructor(address mpbc_addr) Ownable(msg.sender) {
        mpbc = MapleBaCoin(mpbc_addr);
    }

    function receiveCoin(address from, uint256 amount) external {
        if (msg.sender != address(mpbc)) {
            return;
        }
        balances[from] += amount;
    }

    function withdraw(uint256 amount) external {
        if (balances[msg.sender] >= amount) {
            mpbc.transfer(msg.sender, amount);
            unchecked {
                if (balances[msg.sender] - amount < balances[msg.sender]) {
                    balances[msg.sender] -= amount;
                } else {
                    balances[msg.sender] = 0;
                }
            }
        }
    }

    function tap() external {
        if (!syrupTree[msg.sender]) {
            syrupTree[msg.sender] = true;
            mpbc.transfer(msg.sender, 1);
        }
    }
}
