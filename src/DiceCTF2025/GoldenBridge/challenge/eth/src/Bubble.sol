// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Feather.sol";

// A Bubble is a wrapped Feather.
contract Bubble is ERC20 {
    Feather public immutable feather;

    constructor(Feather feather_) ERC20("BUBBLE (wFTH)", "BBL") {
        feather = feather_;
    }

    function wrap(uint256 amount) external {
        feather.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function unwrap(uint256 amount) external {
        _burn(msg.sender, amount);
        feather.transfer(msg.sender, amount);
    }
}
