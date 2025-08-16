pragma solidity 0.8.25;

import {Coin} from "./Coin.sol";

contract ArcadeMachine {
    Coin coin;

    constructor(Coin _coin) {
        coin = _coin;
    }

    function play(uint256 times) external {
        // burn the coins
        require(coin.transferFrom(msg.sender, address(0), 1 ether * times));
        // Have fun XD
    }
}
