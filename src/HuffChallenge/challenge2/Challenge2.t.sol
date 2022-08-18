// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

contract Challenge2Test is Test {
    function testSolver28Gas() public {
        address solverAddress = HuffDeployer.deploy("HuffChallenge/challenge2/Solver28Gas");
        emit log_uint(solverAddress.code.length); // 11 bytes
        validSolver(solverAddress);
    }

    function testSolver26Gas() public {
        address solverAddress = HuffDeployer.deploy("HuffChallenge/challenge2/Solver26Gas");
        emit log_uint(solverAddress.code.length); // 11 bytes
        validSolver(solverAddress);
    }

    function testSolver25Gas() public {
        vm.chainId(1); // mainnet
        address solverAddress = HuffDeployer.deploy("HuffChallenge/challenge2/Solver25Gas");
        emit log_uint(solverAddress.code.length); // 10 bytes
        validSolver(solverAddress);
    }

    function validSolver(address solverAddress) public {
        for (uint256 i = 0; i < 10; i++) {
            (bool success, bytes memory data) = solverAddress.call(abi.encode(i));
            assertTrue(success);
            uint256 isEven = abi.decode(data, (uint256));
            assertEq(isEven, uint256((i + 1) % 2));
        }
    }
}
