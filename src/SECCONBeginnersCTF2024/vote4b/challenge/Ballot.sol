// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ballot is ERC721, Ownable {
    uint256 public ballotId;
    mapping(address => bool) private isResident;
    mapping(address => bool) private isIssued;
    mapping(address => uint256) public votes;

    constructor(address owner) ERC721("BeginnersBallot", "BB") Ownable(msg.sender) {}

    function registerAsResident(address person) public onlyOwner {
        isResident[person] = true;
    }

    function issueBallot() public returns (uint256) {
        require(isResident[msg.sender], "Not a resident");
        require(!isIssued[msg.sender], "Already issued");
        ballotId += 1;
        _safeMint(msg.sender, ballotId);
        isIssued[msg.sender] = true;
        return ballotId;
    }

    function voteForCandidate(uint256 id, address candidate) public {
        require(ownerOf(id) == msg.sender, "Not your ballot");
        votes[candidate] += 1;
        _burn(id);
    }
}
