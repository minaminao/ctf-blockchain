// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SafeNFT is ERC721Enumerable {
    uint256 price;
    mapping(address => bool) public canClaim;

    constructor(string memory tokenName, string memory tokenSymbol, uint256 _price) ERC721(tokenName, tokenSymbol) {
        price = _price; //price = 0.01 ETH
    }

    function buyNFT() external payable {
        require(price == msg.value, "INVALID_VALUE");
        canClaim[msg.sender] = true;
    }

    function claim() external {
        require(canClaim[msg.sender], "CANT_MINT");
        _safeMint(msg.sender, totalSupply());
        canClaim[msg.sender] = false;
    }
}
