pragma solidity 0.8.25;

import {Coin} from "./Coin.sol";
import {ArcadeMachine} from "./ArcadeMachine.sol";

contract Setup {
    Coin public coin;
    ArcadeMachine public arcadeMachine;

    address player;

    constructor() payable {
        coin = new Coin();
        arcadeMachine = new ArcadeMachine(coin);

        // Assume that many people have played before you ;)
        require(msg.value == 20 ether);
        coin.deposit{value: 20 ether}();
        coin.approve(address(arcadeMachine), 19 ether);
        arcadeMachine.play(19);
    }

    function register() external {
        require(player == address(0));
        player = msg.sender;
        coin.transfer(msg.sender, 1337); // free coins for new players :)
    }

    function isSolved() external view returns (bool) {
        return player != address(0) && player.balance >= 13.37 ether;
    }
}
