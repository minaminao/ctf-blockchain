// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

contract Challenge1Test is Test {
    function test() public {
        // 6 bytes
        Challenge challenge = Challenge(HuffDeployer.deploy("HuffChallenge/challenge1/Challenge1"));
        emit log_uint(address(challenge).code.length);

        uint32 blockNumber = challenge.blockNumber();

        assertEq(blockNumber, block.number);
    }
}

interface Challenge {
    function blockNumber() external returns (uint32);
}
