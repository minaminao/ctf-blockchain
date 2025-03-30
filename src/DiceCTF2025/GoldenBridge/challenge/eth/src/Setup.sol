// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "./Feather.sol";
import "./Bubble.sol";
import "./Bridge.sol";

contract Setup {
    Feather public immutable feather;
    Bubble public immutable bubble;
    Bridge public immutable bridge;
    bool private airdropped;

    constructor() {
        airdropped = false;
        uint256 liquidity = 1_000_000_000;
        feather = new Feather();
        feather.mint(address(this), liquidity);
        bubble = new Bubble(feather);
        feather.approve(address(bubble), liquidity);
        bubble.wrap(liquidity);
        bridge = new Bridge(bubble);
        bubble.transfer(address(bridge), liquidity);
        bridge.changeOwner(msg.sender);
    }

    function airdrop() external {
        if (airdropped) revert("no more airdrops :(");
        feather.mint(msg.sender, 10);
        airdropped = true;
    }

    function isSolved() external view returns (bool) {
        return bubble.balanceOf(address(bridge)) == 0;
    }
}
