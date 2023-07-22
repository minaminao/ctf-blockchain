// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract DonationChallenge {
    struct Donation {
        uint256 timestamp;
        uint256 etherAmount;
    }

    Donation[] public donations;

    address public owner;

    constructor() payable {
        require(msg.value == 1 ether);
        owner = msg.sender;
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function donate(uint256 etherAmount) public payable {
        // amount is in ether, but msg.value is in wei
        uint256 scale = 10 ** 18 * 1 ether;
        require(msg.value == etherAmount / scale);

        Donation storage donation;
        donation.timestamp = block.timestamp; // <0.8.0
        donation.etherAmount = etherAmount;

        donations.push(donation);
    }

    function withdraw() public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}
