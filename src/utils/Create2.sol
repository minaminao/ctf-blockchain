// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Create2 {
    function getAddress(address creator, bytes32 salt, bytes memory bytecode, bytes memory encodedArgs)
        internal
        pure
        returns (address)
    {
        return address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), creator, salt, keccak256(abi.encodePacked(bytecode, encodedArgs)))))
            )
        );
    }
}
