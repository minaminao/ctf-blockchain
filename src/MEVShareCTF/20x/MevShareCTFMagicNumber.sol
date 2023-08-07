//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "../base/MevShareCTFBase.sol";

contract MevShareCTFMagicNumber is MevShareCTFBase {
    uint256 public activeBlock;
    uint256 private magicNumber;

    event Activate(uint256 lowerBound, uint256 upperBound);

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFBase(_mevShareCaptureLogger) {}

    function activateRewardMagicNumber(uint256 _lowerBound, uint256 _upperBound, uint256 _magicNumber)
        external
        payable
        onlyOwner
    {
        require(_lowerBound <= _magicNumber && _upperBound >= _magicNumber);
        activeBlock = block.number;
        magicNumber = _magicNumber;
        emit Activate(_lowerBound, _upperBound);
    }

    function claimRewardInternal(uint256 _magicNumber, uint256 _captureId) internal returns (bool) {
        if (activeBlock != block.number || _magicNumber != magicNumber) {
            return false;
        }
        activeBlock = 0;
        magicNumber = 0;
        mevShareCaptureLogger.registerCapture(_captureId, tx.origin);
        return true;
    }
}
