// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Token, IToken} from "./Token.sol";
import {Exchange} from "./Exchange.sol";

contract Setup {
    Exchange public immutable target = new Exchange();

    uint256 balance1 = 300_000;
    uint256 balance2 = 300_000;
    uint256 balance3 = 600_000;

    IToken public token1 = new Token(balance1);
    IToken public token2 = new Token(balance2);
    IToken public token3 = new Token(balance3);

    constructor() {
        target.addToken(address(token1));
        target.addToken(address(token2));
        target.addToken(address(token3));

        token1.approve(address(target), balance1);
        token2.approve(address(target), balance2);
        token3.approve(address(target), balance3);

        target.addLiquidity(address(token1), address(token2), balance1 / 3, balance2 / 3);

        target.addLiquidity(address(token1), address(token3), balance1 / 3, balance3 / 3);

        target.addLiquidity(address(token2), address(token3), balance2 / 3, balance3 / 3);
    }

    function isSolved() public view returns (bool) {
        return (
            IToken(token1).balanceOf(address(target)) == 0 && IToken(token2).balanceOf(address(target)) == 0
                && IToken(token3).balanceOf(address(target)) == 0
        );
    }
}
