//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV2 is MevShareCTFMagicNumber {
    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFMagicNumber(_mevShareCaptureLogger) {}

    function claimReward(uint256 _magicNumber) external {
        require(tx.origin == msg.sender);
        require(claimRewardInternal(_magicNumber, 202));
    }
}
