// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "forge-std/console.sol";

contract Deployer {
    constructor(bytes memory code) {
        assembly {
            return(add(code, 0x20), mload(code))
        }
    }
}

contract Challenge {
    bool public solved = false;

    function safe(bytes memory code) private view returns (bool) {
        uint256 i = 0;
        while (i < code.length) {
            uint8 op = uint8(code[i]);

            if (op >= 0x30 && op <= 0x48) {
                console.log(i);
                console.log(op);
                return false;
            }

            if (
                op == 0x54
                    || // SLOAD
                    op == 0x55
                    || // SSTORE
                    op == 0xF0
                    || // CREATE
                    op == 0xF1
                    || // CALL
                    op == 0xF2
                    || // CALLCODE
                    op == 0xF4
                    || // DELEGATECALL
                    op == 0xF5
                    || // CREATE2
                    op == 0xFA
                    || // STATICCALL
                    op == 0xFF
            ) {
                // SELFDESTRUCT
                return false;
            }

            if (op >= 0x60 && op < 0x80) {
                i += (op - 0x60) + 1;
            }

            i++;
        }

        return true;
    }

    event log_bytes(bytes);

    function solve(bytes memory code) external {
        require(code.length > 0);
        require(safe(code), "deploy/code-unsafe");
        address target = address(new Deployer(code));
        (bool ok, bytes memory result) = target.staticcall("");
        require(ok && keccak256(code) == target.codehash && keccak256(result) == target.codehash);
        solved = true;
    }
}
