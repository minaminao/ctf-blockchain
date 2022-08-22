// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface Challenge3 {
    function deposit() external;

    function withdraw() external;

    function set_withdrawer() external;
}

contract Challenge3Test is Test {
    function setUp() public {
        Challenge3 test = Challenge3(
            HuffDeployer.deploy("HuffChallenge/challenge3/Challenge3")
        );
    }
}
