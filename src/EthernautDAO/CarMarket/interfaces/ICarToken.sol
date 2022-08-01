// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ICarToken is IERC20 {
    function mint() external;

    function priviledgedMint(address _to, uint256 _amount) external;
}
