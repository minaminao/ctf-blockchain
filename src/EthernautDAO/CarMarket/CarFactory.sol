// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ICarMarket.sol";
import "./interfaces/ICarToken.sol";

/**
 * @title CarFactory
 * @author Jelo
 * @notice This is a contract that handles crucial changes in the car company.
 * It also gives out flashloans to existing customers of the car company.
 */
contract CarFactory {
    // -- States --
    address private _owner;
    address private carFactory;
    ICarToken private carToken;
    ICarMarket public carMarket;

    /**
     * @notice Sets the car Market and car token during deployment.
     * @param _carMarket The exchange where car trades take place.
     * @param _carToken The token used to purchase cars.
     */
    constructor(address _carMarket, address _carToken) {
        carToken = ICarToken(_carToken);
        carMarket = ICarMarket(_carMarket);
    }

    /**
     * @notice Gives out flashLoan to an existing customer.
     * @param _amount The amount to be borrowed.
     */
    function flashLoan(uint256 _amount) external {
        //checks if the address has purchased a car previously.
        require(carMarket.isExistingCustomer(msg.sender), "Not existing customer");

        //fetches the balance of the carFactory before loaning out.
        uint256 balanceBefore = carToken.balanceOf(carFactory);

        //check if there is enough amount in the contract to borrow.
        require(balanceBefore >= _amount, "Amount not available");

        //transfers the amount to be borrowed to the borrower
        carToken.transfer(msg.sender, _amount);

        (bool success,) = msg.sender.call(abi.encodeWithSignature("receivedCarToken(address)", address(this)));
        require(success, "Call to target failed");

        //fetches the balance of the carFactory after loaning out.
        uint256 balanceAfter = carToken.balanceOf(carFactory);

        //ensures that the Loan has been paid
        require(balanceAfter >= balanceBefore, "Loan not paid in full");
    }

    /**
     * @dev Returns the car market
     */
    function getCarMarket() external view returns (ICarMarket) {
        return carMarket;
    }

    /**
     * @dev Returns the car token
     */
    function getCarToken() external view returns (ICarToken) {
        return carToken;
    }
}
