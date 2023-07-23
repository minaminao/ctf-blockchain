// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract InSecureumToken is ERC20 {
    // Decimals are set to 18 by default in `ERC20`
    constructor(uint256 _supply) ERC20("InSecureumToken", "ISEC") {
        _mint(msg.sender, _supply);
    }
}
