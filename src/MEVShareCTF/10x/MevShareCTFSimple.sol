//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "../base/MevShareCTFBase.sol";

contract MevShareCTFSimple is MevShareCTFBase {
    uint256 public activeBlock;

    uint256 immutable captureId;

    event Activate();

    constructor(MevShareCaptureLogger _mevShareCaptureLogger, uint256 _captureId)
        payable
        MevShareCTFBase(_mevShareCaptureLogger)
    {
        captureId = _captureId;
    }

    function activateRewardSimple() external payable onlyOwner {
        activeBlock = block.number;
        emit Activate();
    }

    function claimReward() external {
        require(activeBlock == block.number);
        activeBlock = 0;
        mevShareCaptureLogger.registerCapture(captureId, tx.origin);
    }
}
