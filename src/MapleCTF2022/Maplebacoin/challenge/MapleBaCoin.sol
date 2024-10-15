//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./MapleBankon.sol";

uint256 constant TOTAL_SUPPLY = 1 ether * (10 ** 12);

contract MapleBaCoin is ERC20, Ownable {
    MapleBankon bank;

    constructor() ERC20("MapleBaCoin", "MPBC") Ownable(msg.sender) {
        _mint(address(owner()), TOTAL_SUPPLY);
    }

    function setBank(address bnk) external onlyOwner {
        bank = MapleBankon(bnk);
    }

    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
        if (from != address(0)) {
            require(from == address(bank) || to == address(bank));
            bytes memory func = abi.encodeWithSignature("receiveCoin(address,uint256)", from, amount);
            (bool success,) = to.call(func);
            require(success);
        }
    }
}
