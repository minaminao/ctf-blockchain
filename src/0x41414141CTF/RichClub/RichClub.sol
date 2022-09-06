pragma solidity ^0.6;
//SPDX-License-Identifier: MIT

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract RICH_CLUB {
    ERC20 UNI;

    event new_member(string pub_key);
    event send_flag(string pub_key, string flag);

    constructor() public {
        UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    }

    function grant_membership(string memory _pub_key) public {
        require(bytes(_pub_key).length > 120, "invalid public key");
        require(UNI.balanceOf(msg.sender) >= 6e20, "you don't look rich to me");
        emit new_member(_pub_key);
    }

    function grant_flag(string memory _pub_key, string memory encoded_flag) public {
        require(msg.sender == address(0x30cE246A1282169895bf247abaE77BA69d5B2416), "you don't have access to this");
        emit send_flag(_pub_key, encoded_flag);
    }
}
