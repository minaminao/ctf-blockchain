// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

contract Challenge2Test is Test {
    function test() public {
        address solverAddress1 = HuffDeployer.deploy("HuffChallenge/challenge2/Solver26Gas");
        emit log_uint(solverAddress1.code.length); // 11 bytes
        validSolver(solverAddress1);
        address solverAddress2 = HuffDeployer.deploy("HuffChallenge/challenge2/Solver28Gas");
        emit log_uint(solverAddress2.code.length); // 11 bytes
        validSolver(solverAddress2);
    }

    function validSolver(address solverAddress) public {
        for (uint256 i = 0; i < 4; i++) {
            (bool success, bytes memory data) = solverAddress.call(abi.encode(i));
            require(success);
            uint256 isEven = abi.decode(data, (uint256));
            assertEq(isEven, uint256((i + 1) % 2));
        }
    }
}
