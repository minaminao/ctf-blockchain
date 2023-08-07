//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./MevShareCaptureLogger.sol";

contract MevShareCTFBase is Ownable {
    MevShareCaptureLogger immutable mevShareCaptureLogger;

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable {
        mevShareCaptureLogger = _mevShareCaptureLogger;
    }

    function call(address destination, uint256 value, bytes memory data) external onlyOwner returns (bool) {
        (bool success,) = destination.call{value: value}(data);
        return success;
    }
}
