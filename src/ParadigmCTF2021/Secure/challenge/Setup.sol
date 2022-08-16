pragma solidity ^0.8.13;

import "./Wallet.sol";

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract Setup {
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint public constant WANT = 50 ether;

    Wallet public wallet;

    constructor() payable {
        require(msg.value == WANT);

        address tokenModule = address(new TokenModule());

        wallet = new Wallet();
        wallet.allowModule(tokenModule);

        WETH.deposit{value: msg.value}();
        WETH.approve(address(wallet), type(uint).max);

        wallet.execModule(tokenModule, abi.encodeWithSelector(TokenModule.deposit.selector, WETH, address(this), msg.value));
    }

    function isSolved() public view returns (bool) {
        return WETH.balanceOf(address(this)) == WANT;
    }
}