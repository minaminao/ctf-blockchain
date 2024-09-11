pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Animal is ERC721, Ownable {
    struct status {
        uint256 feed;
        string name;
    }

    mapping(uint256 => status) public animalStatus;
    uint256 public counter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function feed(uint256 tokenId, uint256 amount) public onlyOwner {
        animalStatus[tokenId].feed += amount;
    }

    function setName(uint256 tokenId, string memory name) public onlyOwner {
        animalStatus[tokenId].name = name;
    }

    function addAnimal(address to) public onlyOwner {
        _safeMint(to, counter);
        counter++;
    }
}
