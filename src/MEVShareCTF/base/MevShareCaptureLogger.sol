//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./Ownable.sol";

//          ________           __    __          __
//         / ____/ /___ ______/ /_  / /_  ____  / /______
//        / /_  / / __ `/ ___/ __ \/ __ \/ __ \/ __/ ___/
//       / __/ / / /_/ (__  ) / / / /_/ / /_/ / /_(__  )
//      /_/   /_/\__,_/____/_/ /_/_.___/\____/\__/____/

// Join the MEV-Share CTF at https://ctf.flashbots.net
// The goal of this challenge is to emit `Capture()` events with your own address (from tx.origin)
// These challenges require backrunning private transactions using MEV-Share

// Learn about MEV-Share at https://docs.flashbots.net/flashbots-mev-share/overview
// Join the Flashbots Discord and learn about Flashbots at https://flashbots.net/

contract MevShareCaptureLogger is Ownable {
    mapping(address => bool) public ctfContracts;
    mapping(address => mapping(uint256 => bool)) public winnerCaptures;
    mapping(address => uint256) public totalPoints;

    event Capture(uint256 points, address winner, uint256 captureId);
    event CaptureContract(address captureContract, bool isCaptureContract);

    modifier onlyCtfContracts() {
        require(ctfContracts[msg.sender]);
        _;
    }

    function setCaptureContract(address captureContract, bool isCaptureContract) public payable onlyOwner {
        ctfContracts[captureContract] = isCaptureContract;
        emit CaptureContract(captureContract, isCaptureContract);
    }

    function setCaptureContracts(address[] calldata captureContracts, bool isCaptureContract)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < captureContracts.length; i++) {
            setCaptureContract(captureContracts[i], isCaptureContract);
        }
    }

    function call(address destination, uint256 value, bytes memory data) external onlyOwner returns (bool) {
        (bool success,) = destination.call{value: value}(data);
        return success;
    }

    function registerCapture(uint256 captureId, address winner) external payable onlyCtfContracts {
        require(winnerCaptures[winner][captureId] == false);
        winnerCaptures[winner][captureId] = true;
        uint256 points = captureId / 100;
        totalPoints[winner] += points;
        emit Capture(points, winner, captureId);
    }
}
