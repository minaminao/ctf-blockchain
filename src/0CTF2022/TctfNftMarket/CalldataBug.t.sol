// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

struct A {
    B b;
    C c;
}

struct B {
    uint256 b1;
    bytes b2;
}

struct C {
    bytes32[2] c2;
}

contract F {
    function f(A calldata a) external {
        new G().g(a);
    }
}

contract G {
    function g(A calldata a) public pure {
        require(a.b.b1 == 0);
    }
}

contract CalldataBugTest is Test {
    function test() public {
        B memory b = B(3, "");
        bytes32[2] memory c2;
        C memory c = C(c2);
        A memory a = A(b, c);
        new F().f(a);
    }
}
