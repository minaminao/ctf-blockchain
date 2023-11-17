// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IPuzzle} from "../../general/IPuzzle.sol";

/// @title TinySig
/// @author Riley Holterhus
contract TinySig is IPuzzle {
    // This is the address you get by using the private key 0x1.
    // For this challenge, make sure you do not use *your own* private key
    // (other than to initiate the `solve` transaction of course). You only
    // need to use the private key 0x1 for signing things.
    address constant SIGNER = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;

    /// @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "TinySig";
    }

    /// @inheritdoc IPuzzle
    function generate(address _seed) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed)));
    }

    /// @inheritdoc IPuzzle
    function verify(uint256 _start, uint256 _solution) external returns (bool) {
        address target = address(new Deployer(abi.encodePacked(_solution)));
        (, bytes memory ret) = target.staticcall("");
        (bytes32 h, uint8 v, bytes32 r) = abi.decode(ret, (bytes32, uint8, bytes32));
        return (r < bytes32(uint256(1 << 184)) && ecrecover(h, v, r, bytes32(_start)) == SIGNER);
    }
}

contract Deployer {
    constructor(bytes memory code) {
        assembly {
            return(add(code, 0x20), mload(code))
        }
    }
}
