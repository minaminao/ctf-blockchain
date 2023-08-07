// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ClearChecker {
    function requireClear(uint256 captureId) public view {
        IMevShareCaptureLogger logger = IMevShareCaptureLogger(0x6C9c151642C0bA512DE540bd007AFa70BE2f1312);
        require(logger.winnerCaptures(tx.origin, captureId));
    }
}

interface IMevShareCaptureLogger {
    function winnerCaptures(address, uint256) external view returns (bool);
}
