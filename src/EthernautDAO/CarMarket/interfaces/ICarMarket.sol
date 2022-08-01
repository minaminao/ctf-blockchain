// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ICarToken.sol";

interface ICarMarket {
    function setCarFactory(address _factory) external;

    function purchaseCar(
        string memory _color,
        string memory _model,
        string memory _plateNumber
    )
        external;

    function isExistingCustomer(address _customer)
        external
        view
        returns (bool);

    function getCarFactory() external view returns (address);

    function getCarToken() external view returns (ICarToken);

    function getCarCount(address _carOwner) external view returns (uint256);
}
