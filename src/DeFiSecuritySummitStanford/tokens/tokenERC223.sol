// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

contract SimpleERC223Token is ERC20 {
    constructor(uint256 _supply) ERC20("Simple ERC223 Token", "SET") {
        _mint(msg.sender, _supply);
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        // Call parent hook
        super._update(from, to, amount);
        if (to.code.length > 0) {
            // this is wrong and broken on many ways, but it works for this example
            // instead of a try catch perhaps we should use a ERC165...
            // the tokenFallback function is run if the contract has this function
            (bool success,) =
                to.call(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", msg.sender, amount, ""));
            require(success, "TokenFallback not implemented");
        }
    }
}
