pragma solidity ^0.8.0;

import "./Bouncer.sol";

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract Setup {
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Bouncer public bouncer;
    Party public party;

    constructor() payable {
        require(msg.value == 100 ether);
        // give some cash to the bouncer for his drinks
        bouncer = new Bouncer{value: 50 ether}();

        // 2 * eth
        bouncer.enter{value: 1 ether}(address(weth), 10 ether);
        bouncer.enter{value: 1 ether}(ETH, 10 ether);

        party = new Party(bouncer);
    }

    function isSolved() public view returns (bool) {
        return address(bouncer).balance == 0;
    }
}
