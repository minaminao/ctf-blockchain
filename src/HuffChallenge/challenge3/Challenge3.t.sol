// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface Challenge3 {
    function deposit() external payable;

    function withdraw() external;

    function set_withdrawer() external;
}

contract Challenge3Test is Test {
    Challenge3 test;

    function setUp() public {
        test = Challenge3(
            HuffDeployer.deploy("HuffChallenge/challenge3/Challenge3")
        );
        test.deposit{value: 0.1 ether}();
    }

    function testExploit() public {
        test.set_withdrawer();
    }
}
