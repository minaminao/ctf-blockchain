// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract VToken is ERC20 {
    // Decimals are set to 18 by default in `ERC20`
    constructor() ERC20("VToken", "VTLK") {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        _mint(vitalik, 100 ether);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address owner, address spender, uint256 amount) public returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }
}
