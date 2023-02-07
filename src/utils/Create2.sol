// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Create2 {
    address constant create2DeployerAddress = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function getAddress(address creator, bytes32 salt, bytes memory creationCode) internal pure returns (address) {
        return
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), creator, salt, keccak256(creationCode))))));
    }

    function getAddress(address creator, bytes32 salt, bytes memory creationCode, bytes memory encodedArgs)
        internal
        pure
        returns (address)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), creator, salt, keccak256(abi.encodePacked(creationCode, encodedArgs))
                        )
                    )
                )
            )
        );
    }
}
