//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "../base/MevShareCaptureLogger.sol";
import "../base/MevShareCTFBase.sol";

contract MevShareCTFNewContracts is MevShareCTFBase {
    uint256 public magicNumber;

    // maps addresses to child contracts, acts both as check for valid caller and which CTF is being targeted
    //  value of 1 = emitted by address
    //  value of 2 = emitted by salt
    mapping(address => uint256) childContracts;

    event Activate(address newlyDeployedContract);
    event ActivateBySalt(bytes32 salt);

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) payable MevShareCTFBase(_mevShareCaptureLogger) {}

    function proxyRegisterCapture() external {
        uint256 childContractType = childContracts[msg.sender];
        if (childContractType == 0) {
            revert("Not called by a child contract");
        }
        mevShareCaptureLogger.registerCapture(300 + childContractType, tx.origin);
    }

    function activateRewardNewContract(bytes32 salt) external payable onlyOwner {
        MevShareCTFNewContract newlyDroppedContract = new MevShareCTFNewContract{salt: salt}();
        childContracts[address(newlyDroppedContract)] = 1;
        emit Activate(address(newlyDroppedContract));
    }

    function activateRewardBySalt(bytes32 salt) external payable onlyOwner {
        MevShareCTFNewContract newlyDroppedContract = new MevShareCTFNewContract{salt: salt}();
        childContracts[address(newlyDroppedContract)] = 2;
        emit ActivateBySalt(salt);
    }
}

contract MevShareCTFNewContract {
    MevShareCTFNewContracts immutable mevShareCTFNewContracts;
    uint256 public activeBlock;

    constructor() payable {
        mevShareCTFNewContracts = MevShareCTFNewContracts(msg.sender);
        activeBlock = block.number;
    }

    function claimReward() external {
        require(activeBlock == block.number);
        activeBlock = 0;
        mevShareCTFNewContracts.proxyRegisterCapture();
    }
}
