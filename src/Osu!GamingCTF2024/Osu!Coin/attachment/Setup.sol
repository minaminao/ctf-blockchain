pragma solidity ^0.8.17;

import "./OsuCoin.sol";

contract Setup {
    OsuCoin public immutable coin;

    constructor() payable {
        require(msg.value == 100 wei, "requires 100 wei");
        coin = new OsuCoin();
        coin.deposit{value: msg.value}();
    }

    function isSolved() public view returns (bool) {
        return coin.balanceOf(address(this)) == 0;
    }
}
