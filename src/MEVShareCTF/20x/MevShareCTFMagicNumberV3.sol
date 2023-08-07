//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV3 is MevShareCTFMagicNumber {
    // V3 only gets one shot per tx.origin. If any tx lands that is incorrect, that tx.origin does not get another shot
    mapping(address => bool) public registeredV3Attempts;

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFMagicNumber(_mevShareCaptureLogger) {}

    function claimReward(uint256 _magicNumber) external {
        require(tx.origin == msg.sender);
        require(registeredV3Attempts[tx.origin] == false);
        registeredV3Attempts[tx.origin] = true;
        claimRewardInternal(_magicNumber, 203);
    }
}
