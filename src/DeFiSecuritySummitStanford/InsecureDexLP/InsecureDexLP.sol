// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

/**
 * @dev Some ideas for this challenge were taken from
 * https://github.com/martriay/scAMM/blob/main/contracts/Exchange.sol
 */
contract InsecureDexLP {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // @dev Balance of token0
    uint256 public reserve0;
    // @dev Balance of token1
    uint256 public reserve1;

    // @dev Total liquidity LP
    uint256 public totalSupply;
    // @dev Liquidity shares per user
    mapping(address => uint256) private _balances;

    /* @dev token0Address, token1Address Addresses of the tokens
     * participating in the liquidity pool 
     */
    constructor(address token0Address, address token1Address) {
        token0 = IERC20(token0Address);
        token1 = IERC20(token1Address);
    }

    // @dev Updates the balances of the tokens
    function _updateReserves() internal {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }

    // @dev Allows users to add liquidity for token0 and token1
    function addLiquidity(uint256 amount0, uint256 amount1) external {
        uint256 liquidity;

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        uint256 _totalSupply = totalSupply;

        /* @dev if there is no liquidity, initial liquidity is defined as
         * sqrt(amount0 * amount1), following the product-constant rule
         * for AMMs.
         */
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
            // @dev If liquidity exists, update shares with supplied amounts
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 * _totalSupply) / reserve1);
        }

        // @dev Update balances with the new values
        _updateReserves();
        // @dev Increase total supply and user balance accordingly
        unchecked {
            totalSupply += liquidity;
            _balances[msg.sender] += liquidity;
        }
    }

    // @dev Burn LP shares and get token0 and token1 amounts back
    function removeLiquidity(uint256 amount) external returns (uint256 amount0, uint256 amount1) {
        require(_balances[msg.sender] >= amount);
        unchecked {
            amount0 = (amount * reserve0) / totalSupply;
            amount1 = (amount * reserve1) / totalSupply;
        }
        require(amount0 > 0 && amount1 > 0, "InsecureDexLP: INSUFFICIENT_LIQUIDITY_BURNED");

        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);

        unchecked {
            _balances[msg.sender] -= amount;
            totalSupply -= amount;
        }

        _updateReserves();
    }

    // @dev Swap amountIn of tokenFrom to tokenTo
    function swap(address tokenFrom, address tokenTo, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenFrom == address(token0) || tokenFrom == address(token1), "tokenFrom is not supported");
        require(tokenTo == address(token0) || tokenTo == address(token1), "tokenTo is not supported");

        if (tokenFrom == address(token0)) {
            amountOut = _calcAmountsOut(amountIn, reserve0, reserve1);
            token0.safeTransferFrom(msg.sender, address(this), amountIn);
            token1.safeTransfer(msg.sender, amountOut);
        } else {
            amountOut = _calcAmountsOut(amountIn, reserve1, reserve0);
            token1.safeTransferFrom(msg.sender, address(this), amountIn);
            token0.safeTransfer(msg.sender, amountOut);
        }
        _updateReserves();
    }

    /* @dev Given an amountIn of tokenIn, compute the corresponding output of
     * tokenOut
     */
    function calcAmountsOut(address tokenIn, uint256 amountIn) external view returns (uint256 output) {
        if (tokenIn == address(token0)) {
            output = _calcAmountsOut(amountIn, reserve0, reserve1);
        } else if (tokenIn == address(token1)) {
            output = _calcAmountsOut(amountIn, reserve1, reserve0);
        } else {
            revert("Token is not supported");
        }
    }

    // @dev See balance of user
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /* @dev taken from uniswap library;
     * https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43
     */
    function _calcAmountsOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        amountIn = amountIn * 1000;
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountIn;
        amountOut = (numerator / denominator);
    }

    function tokenFallback(address, uint256, bytes memory) external {}
}
