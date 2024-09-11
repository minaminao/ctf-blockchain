//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// import "openzeppelin-contracts@4.3.2/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-contracts@4.3.2/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract DUCoin is ERC20, Ownable {
    constructor() ERC20("DUCoin", "DUC") Ownable(msg.sender) {}

    function freeMoney(address addr) external onlyOwner {
        _mint(addr, 1337);
    }
}
