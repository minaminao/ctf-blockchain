// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Anyone can deposit ether, but only the owner can withdraw
 * During contract creation a secret key is set, which allows
 * to transfer ownership of the contract
 */
contract PrivateData {
    uint256 public constant NUM = 1337;
    address public owner;
    bytes32[5] private randomData;
    mapping(address => uint256) public addressToKeys;
    uint128 private a;
    uint128 private b;
    uint256 private secretKey;

    event OwnershipTaken(
        address indexed previousOwner,
        address indexed newOwner
    );

    event Deposit(address _from, uint256 value);

    constructor(string memory rndString) {
        owner = msg.sender;

        // create a random number and store it in a private variable
        secretKey = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    rndString
                )
            )
        );
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function takeOwnership(uint256 key) public {
        // only a person knowing the secretKey is allowed to take ownership
        require(key == secretKey, "Not allowed!");

        address oldOwner = owner;
        owner = msg.sender;

        emit OwnershipTaken(oldOwner, msg.sender);
    }
}