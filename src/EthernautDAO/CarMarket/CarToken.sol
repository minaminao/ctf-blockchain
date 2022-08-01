// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title CarToken contract
 * @dev This is the implementation of the CarToken contract
 * @notice There is a capped supply of 210,000 tokens.
 *         10,000 tokens is reserved for the public
 *         A user can only mint once
 */
contract CarToken is ERC20, Ownable {
    // ---- States ----
    mapping(address => bool) hasMinted;
    uint256 private constant MAX_SUPPLY = 210000 * 1e18;
    uint256 public count;

    /**
     * @dev Car Company Contract Constructor.
     */
    constructor() ERC20("Car Company", "CCY") {}

    /**
     * @dev Checks to see if the user has minted previously.
     */
    modifier hasNotMinted() {
        require(!hasMinted[msg.sender], "Can only mint once");
        _;
    }

    /**
     * @dev Mint new tokens
     */
    function mint() external hasNotMinted {
        require(totalSupply() < MAX_SUPPLY, "Max Supply Reached");
        hasMinted[msg.sender] = true;
        _mint(msg.sender, 1 ether);
    }

    /**
     * @dev Allows only the owner to mint new tokens
     * @param _to Address to mint tokens to
     * @param _amount The amount of tokens to mint to address
     */
    function priviledgedMint(address _to, uint256 _amount)
        external
        onlyOwner
        hasNotMinted
    {
        require(_amount + totalSupply() <= MAX_SUPPLY, "Max Supply Reached");
        hasMinted[_to] = true;
        _mint(_to, _amount);
    }
}
