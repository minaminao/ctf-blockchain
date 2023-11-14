// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Create2 {
    function computeAddr(address creator, bytes32 salt, bytes memory creationCode) external pure returns (address) {
        return
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), creator, salt, keccak256(creationCode))))));
    }

    function computeAddr(address creator, bytes32 salt, bytes memory creationCode, bytes memory encodedArgs)
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

contract Create2Deployer {
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address addr) {
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)
        }
    }
}
