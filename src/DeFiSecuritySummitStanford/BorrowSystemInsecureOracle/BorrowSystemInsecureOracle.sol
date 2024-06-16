// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface IInsecureDexLP {
    function calcAmountsOut(address tokenIn, uint256 amountIn) external view returns (uint256 output);
}

/**
 * @dev Codebase heavily inspired by
 * https://github.com/maxsam4/bad-lending-demo/blob/main/contracts/LeBo.sol
 */
contract BorrowSystemInsecureOracle {
    using SafeERC20 for IERC20;

    /// @dev oracle to be used
    IInsecureDexLP immutable oracleToken;
    /// @dev ERC20 tokens participating in the borrow system
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    /// @dev Borrow and lend balances
    mapping(address => uint256) token0Deposited;
    mapping(address => uint256) token0Borrowed;
    mapping(address => uint256) token1Deposited;
    mapping(address => uint256) token1Borrowed;

    constructor(address _oracleToken, address _tokenInsecureum, address _tokenBoring) {
        oracleToken = IInsecureDexLP(_oracleToken);
        token0 = IERC20(_tokenInsecureum);
        token1 = IERC20(_tokenBoring);
    }

    function depositToken0(uint256 amount) external {
        token0.safeTransferFrom(msg.sender, address(this), amount);
        token0Deposited[msg.sender] += amount;
    }

    function depositToken1(uint256 amount) external {
        token1.safeTransferFrom(msg.sender, address(this), amount);
        token1Deposited[msg.sender] += amount;
    }

    function borrowToken0(uint256 amount) external {
        token0Borrowed[msg.sender] += amount;
        require(isSolvent(msg.sender), "User is not solvent");
        token0.safeTransfer(msg.sender, amount);
    }

    function borrowToken1(uint256 amount) external {
        token1Borrowed[msg.sender] += amount;
        require(isSolvent(msg.sender), "User is not solvent");
        token1.safeTransfer(msg.sender, amount);
    }

    /// @dev Liquidate an undercollaterized position
    function liquidate(address user) external {
        require(!isSolvent(user), "User is not solvent!");

        // @dev Retrieve user balances
        uint256 _token0Borrowed = token0Borrowed[user];
        uint256 _token1Borrowed = token1Borrowed[user];
        uint256 _token0Deposited = token0Deposited[user];
        uint256 _token1Deposited = token1Deposited[user];

        // @dev Check iteration effects
        token0Borrowed[user] = 0;
        token1Borrowed[user] = 0;
        token0Deposited[user] = 0;
        token1Deposited[user] = 0;

        token0.safeTransferFrom(msg.sender, address(this), _token0Borrowed);
        token1.safeTransferFrom(msg.sender, address(this), _token1Borrowed);
        token0.safeTransfer(msg.sender, _token0Deposited);
        token1.safeTransfer(msg.sender, _token1Deposited);
    }

    /// @dev Check if user is solvent
    function isSolvent(address user) public view returns (bool) {
        uint256 _base = 1 ether;
        uint256 _tokenPrice = tokenPrice(_base);

        uint256 collateralValue = token0Deposited[user] + (token1Deposited[user] * _tokenPrice) / _base;

        uint256 maxBorrow = collateralValue * 100 / 90; // 90% LTV
        uint256 borrowed = token0Borrowed[user] + (token1Borrowed[user] * _tokenPrice) / _base;

        return maxBorrow >= borrowed;
    }

    /// @dev Retrieve token price from oracle
    function tokenPrice(uint256 _amount) public view returns (uint256) {
        return oracleToken.calcAmountsOut(address(token1), _amount);
    }
}
