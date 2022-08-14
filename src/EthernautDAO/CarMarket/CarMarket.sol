// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ICarMarket.sol";
import "./interfaces/ICarToken.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title CarMarket
 * @author Jelo
 * @notice CarMarket is a marketplace where people interested in cars can buy directly from the company.
 * To grow her userbase, the company allows first time users to purchase cars for free.
 * Getting a free car involves, using the company's tokens which is given to first timers for free.
 * There is a problem however, malicious users have discovered how to get a second car for free.
 * Your job is to figure out how to purchase a second car in a clever and ingenious way.
 */
contract CarMarket is Ownable {
    // -- States --
    address private carFactory;
    ICarToken private carToken;
    ICarMarket public carMarket;
    uint256 private constant CARCOST = 1 ether;

    struct Car {
        string color;
        string model;
        string plateNumber;
    }

    mapping(address => uint256) private carCount;
    mapping(address => mapping(uint256 => Car)) public purchasedCars;

    /**
     * @notice Sets the car token during deployment.
     * @param _carToken The token used to purchase cars
     */
    constructor(address _carToken) {
        carToken = ICarToken(_carToken);
    }

    /**
     * @notice Sets the car factory after deployment.
     * @param _factory The address of the car factory.
     */
    function setCarFactory(address _factory) external onlyOwner {
        carFactory = _factory;
    }

    /**
     * @notice Gets the current cost of a car for a particular buyer.
     * @param _buyer The buyer to check for.
     */
    function _carCost(address _buyer) private view returns (uint256) {
        //if it's a first time buyer
        if (carCount[_buyer] == 0) {
            return CARCOST;
        } else {
            return 100000 ether;
        }
    }

    /**
     * @dev Enables a user to purchase a car
     * @param _color The color of the car to be purchased
     * @param _model The model of the car to be purchased
     * @param _plateNumber The plateNumber of the car to be purchased
     */
    function purchaseCar(string memory _color, string memory _model, string memory _plateNumber) external {
        //Ensure that the user has enough money to purchase a car
        require(carToken.balanceOf(msg.sender) >= _carCost(msg.sender), "Not enough money");

        //user must have given approval. Transfers the money used in
        //purchasing the car to the owner of the contract
        carToken.transferFrom(msg.sender, owner(), CARCOST);

        //Update the amount of cars the user has purchased.
        uint256 _carCount = ++carCount[msg.sender];

        //Allocate a car to the user based on the user's specifications.
        purchasedCars[msg.sender][_carCount] = Car({color: _color, model: _model, plateNumber: _plateNumber});
    }

    /**
     * @dev Checks if a customer has previously purchased a car
     * @param _customer Address of the customer
     */
    function isExistingCustomer(address _customer) public view returns (bool) {
        return carCount[_customer] > 0;
    }

    /**
     * @dev Gets the address of the Car factory
     */
    function getCarFactory() external view returns (address) {
        return carFactory;
    }

    /**
     * @dev Returns the car token
     */
    function getCarToken() external view returns (ICarToken) {
        return carToken;
    }

    /**
     * @dev Returns the amount of cars a car owner has.
     */
    function getCarCount(address _carOwner) external view returns (uint256) {
        return carCount[_carOwner];
    }

    /**
     * @dev A fallback function that delegates call to the CarFactory
     */
    fallback() external {
        carMarket = ICarMarket(address(this));
        carToken.approve(carFactory, carToken.balanceOf(address(this)));
        (bool success,) = carFactory.delegatecall(msg.data);
        require(success, "Delegate call failed");
    }
}
