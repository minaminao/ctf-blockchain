pragma solidity ^0.8.0;

contract Hexp {
    address public immutable target;
    bool flag;

    constructor() {
        bytes memory code = hex"3d602d80600a3d3981f362ffffff80600a43034016903a1681146016576033fe5b5060006000f3";
        address child;
        assembly {
            child := create(0, add(code, 0x20), mload(code))
        }
        target = child;
    }

    function f00000000_bvvvdlt() external {
        (bool succ, bytes memory ret) = target.call(hex"");
        assert(succ);
        flag = true;
    }

    function isSolved() public view returns (bool) {
        return flag;
    }
}
