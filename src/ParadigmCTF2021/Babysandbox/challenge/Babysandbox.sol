pragma solidity ^0.8.0;

contract BabySandbox {
    function run(address code) external payable {
        assembly {
            // if we're calling ourselves, perform the privileged delegatecall
            if eq(caller(), address()) {
                switch delegatecall(gas(), code, 0x00, 0x00, 0x00, 0x00)
                case 0 {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                case 1 {
                    returndatacopy(0x00, 0x00, returndatasize())
                    return(0x00, returndatasize())
                }
            }

            // ensure enough gas
            if lt(gas(), 0xf000) { revert(0x00, 0x00) }

            // load calldata
            calldatacopy(0x00, 0x00, calldatasize())

            // run using staticcall
            // if this fails, then the code is malicious because it tried to change state
            if iszero(staticcall(0x4000, address(), 0, calldatasize(), 0, 0)) { revert(0x00, 0x00) }

            // if we got here, the code wasn't malicious
            // run without staticcall since it's safe
            switch call(0x4000, address(), 0, 0, calldatasize(), 0, 0)
            case 0 { returndatacopy(0x00, 0x00, returndatasize()) }
            case 1 {
                returndatacopy(0x00, 0x00, returndatasize())
                return(0x00, returndatasize())
            }
        }
    }
}
