//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "../base/MevShareCTFBase.sol";

contract MevShareCTFTriple is MevShareCTFBase {
    uint256 public activeBlock;

    mapping(address => mapping(uint256 => uint256)) addressBlockCount;

    event Activate();

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFBase(_mevShareCaptureLogger) {}

    function activateRewardTriple() external payable onlyOwner {
        activeBlock = block.number;
        emit Activate();
    }

    function claimReward() external {
        require(activeBlock == block.number);
        require(tx.origin == msg.sender);
        uint256 claimCount = addressBlockCount[tx.origin][block.number] + 1;
        if (claimCount == 3) {
            mevShareCaptureLogger.registerCapture(401, tx.origin);
            return;
        }
        addressBlockCount[tx.origin][block.number] = claimCount;
    }
}
