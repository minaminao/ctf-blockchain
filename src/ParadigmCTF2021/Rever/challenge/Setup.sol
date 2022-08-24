pragma solidity ^0.8.0;

contract Deployer {
    constructor(bytes memory code) {
        assembly {
            return(add(code, 0x20), mload(code))
        }
    }
}

contract Challenge {
    address public fwd;
    address public rev;

    function safe(bytes memory code) private pure returns (bool) {
        uint256 i = 0;
        while (i < code.length) {
            uint8 op = uint8(code[i]);
            if (
                op == 0x3B // EXTCODECOPY
                    || op == 0x3C // EXTCODESIZE
                    || op == 0x3F // EXTCODEHASH
                    || op == 0x54 // SLOAD
                    || op == 0x55 // SSTORE
                    || op == 0xF0 // CREATE
                    || op == 0xF1 // CALL
                    || op == 0xF2 // CALLCODE
                    || op == 0xF4 // DELEGATECALL
                    || op == 0xF5 // CREATE2
                    || op == 0xFA // STATICCALL
                    || op == 0xFF // SELFDESTRUCT
            ) {
                return false;
            }

            if (op >= 0x60 && op < 0x80) {
                i += (op - 0x60) + 1;
            }

            i++;
        }

        return true;
    }

    function flip(bytes memory a) private pure returns (bytes memory) {
        bytes memory b = new bytes(a.length);
        for (uint256 i = 0; i < a.length; i++) {
            b[b.length - i - 1] = a[i];
        }
        return b;
    }

    function deployOne(bytes memory code) private returns (address) {
        require(code.length < 101, "deployOne/code-too-long");
        require(safe(code), "deployOne/code-unsafe");

        return address(new Deployer(code));
    }

    function deploy(bytes memory code) public {
        fwd = deployOne(code);
        rev = deployOne(flip(code));
    }
}

contract Setup {
    Challenge public challenge;

    constructor() {
        challenge = new Challenge();
    }

    function test(string memory what) public view returns (bool) {
        return test(challenge.fwd(), what) && test(challenge.rev(), what);
    }

    function test(address who, string memory what) public view returns (bool) {
        bool ok;
        assembly {
            ok := staticcall(gas(), who, add(what, 0x20), mload(what), 0x00, 0x00)
            if ok {
                if iszero(iszero(returndatasize())) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0x00, returndatasize())
                    ok := mload(ptr)
                }
            }
        }
        return ok;
    }
}
