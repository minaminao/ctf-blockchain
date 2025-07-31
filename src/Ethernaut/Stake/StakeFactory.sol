// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Ethernaut/Level.sol";
import "./Stake.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract DWETH is ERC20 {
    constructor() ERC20("DummyWETH", "DWETH") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract StakeFactory is Level {
    address _dweth = address(new DWETH());

    function createInstance(address /* _player */) public payable override returns (address) {
        return address(new Stake(address(_dweth)));
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        Stake instance = Stake(_instance);
        return _instance.balance != 0 && instance.totalStaked() > _instance.balance && instance.UserStake(_player) == 0
            && instance.Stakers(_player);
    }
}
