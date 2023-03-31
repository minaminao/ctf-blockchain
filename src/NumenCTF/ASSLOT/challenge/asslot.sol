// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Asslot {
    event EmitFlag(address);

    constructor() {}

    function func() private view {
        assembly {
            for { let i := 0 } lt(i, 0x4) { i := add(i, 1) } {
                mstore(0, blockhash(sub(number(), 1)))
                let success := staticcall(gas(), caller(), 0, shl(0x5, 1), 0, 0)
                if eq(success, 0) { invalid() }
                returndatacopy(0, 0, shl(0x5, 1))
                switch eq(i, mload(0))
                case 0 { invalid() }
            }
        }
    }

    function f00000000_bvvvdlt() external {
        assembly {
            let size := extcodesize(caller())
            if gt(size, shl(0x6, 1)) { invalid() }
        }
        func();
        emit EmitFlag(tx.origin);
    }
}
