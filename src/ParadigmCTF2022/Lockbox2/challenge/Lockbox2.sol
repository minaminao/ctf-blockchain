// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

contract Lockbox2 {
    bool public locked = true;

    function solve() external {
        bool[] memory successes = new bool[](5);
        (successes[0],) = address(this).delegatecall(abi.encodePacked(this.stage1.selector, msg.data[4:]));
        (successes[1],) = address(this).delegatecall(abi.encodePacked(this.stage2.selector, msg.data[4:]));
        (successes[2],) = address(this).delegatecall(abi.encodePacked(this.stage3.selector, msg.data[4:]));
        (successes[3],) = address(this).delegatecall(abi.encodePacked(this.stage4.selector, msg.data[4:]));
        (successes[4],) = address(this).delegatecall(abi.encodePacked(this.stage5.selector, msg.data[4:]));
        for (uint256 i = 0; i < 5; ++i) {
            require(successes[i]);
        }
        locked = false;
    }

    function stage1() external pure {
        require(msg.data.length < 500);
    }

    function stage2(uint256[4] calldata arr) external pure {
        for (uint256 i = 0; i < arr.length; ++i) {
            require(arr[i] >= 1);
            for (uint256 j = 2; j < arr[i]; ++j) {
                require(arr[i] % j != 0);
            }
        }
    }

    function stage3(uint256 a, uint256 b, uint256 c) external view {
        assembly {
            mstore(a, b)
        }
        (bool success, bytes memory data) = address(uint160(a + b)).staticcall("");
        require(success && data.length == c);
    }

    event log_bytes(bytes);
    event log_bytes32(bytes32);

    function stage4(bytes memory a, bytes memory b) external {
        emit log_bytes(a);
        emit log_bytes(b);
        address addr;
        address callerOpResult;
        address addressOpResult;
        uint256 remainingGas;
        assembly {
            remainingGas := gas()
            callerOpResult := caller()
            addressOpResult := address()
            addr := create(0, add(a, 0x20), mload(a))
        }
        (bool success,) = addr.staticcall(b);
        require(tx.origin == address(uint160(uint256(addr.codehash))) && success);
    }

    function stage5() external {
        if (msg.sender != address(this)) {
            (bool success,) = address(this).call(abi.encodePacked(this.solve.selector, msg.data[4:]));
            require(!success);
        }
    }
}
