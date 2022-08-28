// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// Some ideas for this challenge were taken from damn vulnerable defi
contract InSecureumLenderPool {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @dev Token contract address to be used for lending.
    //IERC20 immutable public token;
    IERC20 public token;
    /// @dev Internal balances of the pool for each user.
    mapping(address => uint256) public balances;

    // flag to notice contract is on a flashloan
    bool private _flashLoan;

    /// @param _token Address of the token to be used for the lending pool.
    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @dev Deposit the given amount of tokens to the lending
    ///      pool. This will add _amount to balances[msg.sender] and
    ///      transfer _amount tokens to the lending pool.
    /// @param _amount Amount of token to deposit in the lending pool
    function deposit(uint256 _amount) external {
        require(!_flashLoan, "Cannot deposit while flash loan is active");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    /// @dev Withdraw the given amount of tokens from the lending pool.
    function withdraw(uint256 _amount) external {
        require(!_flashLoan, "Cannot withdraw while flash loan is active");
        balances[msg.sender] -= _amount;
        token.safeTransfer(msg.sender, _amount);
    }

    /// @dev Give borrower all the tokens to make a flashloan.
    ///      For this with get the amount of tokens in the lending pool before, then we give
    ///      control to the borrower to make the flashloan. After the borrower makes the flashloan
    ///      we check if the lending pool has the same amount of tokens as before.
    /// @param borrower The contract that will have access to the tokens
    /// @param data Function call data to be used by the borrower contract.
    function flashLoan(address borrower, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));

        _flashLoan = true;

        borrower.functionDelegateCall(data);

        _flashLoan = false;

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}
