// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

/// @author Pranesh <github.com/PraneshASP>
contract Challenge5Test is Test {
    address solver;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("RPC_MAINNET"));
        solver = HuffDeployer.config().deploy("HuffChallenge/challenge5/Challenge5");
    }

    function testSignaturePass() public {
        bytes32 messageHash = hex"3ea2f1d0abf3fc66cf29eebb70cbd4e7fe762ef8a09bcc06c8edf641230afec0";

        bytes memory signature =
            hex"1556a70d76cc452ae54e83bb167a9041f0d062d000fa0dcb42593f77c544f6471643d14dbd6a6edc658f4b16699a585181a08dba4f6d16a9273e0e2cbed622da1b";

        bytes memory input = abi.encodePacked(messageHash, signature);

        vm.prank(0x80C67eEC6f8518B5Bb707ECc718B53782AC71543); // valid address
        (bool success, bytes memory retData) = solver.staticcall(input);
        assertTrue(success);
        assertEq(retData, abi.encode(1));
    }

    function testSignaturePass2() public {
        bytes32 messageHash = hex"97c943890b15f4dea02c3ae1653252489599957b280a95bf2e533fdbc8facb58";

        bytes memory signature =
            hex"d361e8ea11167286b3e9874de12a2e82a46a12d5adada287fc356f7a1583ce352aa8da5efafc3996294bddbafbec34f46932c081c9853e1233df46b2a2d216021c";

        bytes memory input = abi.encodePacked(messageHash, signature);

        vm.prank(0x98b4d7B30aa38BadB24D95517796e19127975dD5); // valid address
        (bool success, bytes memory retData) = solver.staticcall(input);
        assertTrue(success);
        assertEq(retData, abi.encode(1));
    }

    function testSignatureRevert() public {
        bytes32 messageHash = hex"3ea2f1d0abf3fc66cf29eebb70cbd4e7fe762ef8a09bcc06c8edf641230afec0";

        bytes memory signature =
            hex"1556a70d76cc452ae54e83bb167a9041f0d062d000fa0dcb42593f77c544f6471643d14dbd6a6edc658f4b16699a585181a08dba4f6d16a9273e0e2cbed622da1b";

        bytes memory input = abi.encodePacked(messageHash, signature);

        vm.prank(0x7156526fbD7a3c72969B54F64e42c10fBB768C8B); // invalid address
        (bool success,) = solver.staticcall(input);
        assertFalse(success);
    }
}
