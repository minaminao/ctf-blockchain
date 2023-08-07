//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV1 is MevShareCTFMagicNumber {
    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFMagicNumber(_mevShareCaptureLogger) {}

    function claimReward(uint256 _magicNumber) external {
        require(claimRewardInternal(_magicNumber, 201));
    }
}
