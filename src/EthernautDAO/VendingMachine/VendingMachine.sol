// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title A simple contract that models after a vending machine that provides only peanuts
 * @dev Implement one time hackable smart contract (vending machine model)
 */
contract VendingMachine {
    address public owner;
    uint256 private reserve;
    bool private txCheckLock;
    mapping(address => uint256) public peanuts;
    mapping(address => uint256) public consumersDeposit;

    /**
     * @dev Sets the values for {owner}, require contract {reserve} balance of 0.1 ether,
     * initialize {peanuts} with a default value of 2,000 and {txCheckLock} with default
     * value of false.
     */
    constructor() payable {
        require(
            msg.value >= 1 ether,
            "You need a minimum of reserve of 1 ether before deploying the contract"
        );

        owner = msg.sender;
        reserve = msg.value;
        peanuts[address(this)] = 2000;
        txCheckLock = false;
    }

    /**
     * @dev Returns true if `account` is a contract and not an EOA.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     * ====
     */
    function isExtContract(address _addr) private view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint32 _codeSize;

        assembly {
            _codeSize := extcodesize(_addr)
        }
        return (_codeSize > 0 || _addr != tx.origin);
    }

    /**
     * @dev Ascertains the validity of the contract
     * Throws if the contract has been hacked.
     */
    modifier isStillValid() {
        require(!txCheckLock, "Sorry, this product project has been hacked");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the amount of peanuts remaining in the contract[Vending Machine].
     */
    function getPeanutsBalance() public view returns (uint256) {
        return peanuts[address(this)];
    }

    /**
     * @dev Returns the balance of any address that has deposited to
     * the contract.
     */
    function getMyBalance() public view returns (uint256) {
        return consumersDeposit[msg.sender];
    }

    /**
     * @dev Returns the balance of the contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the amount the owner deposited to the contract as reserve.
     */
    function getReserveAmount() public view onlyOwner returns (uint256) {
        return reserve;
    }

    /**
     * @dev Deposits are made to the contract before any interaction with it.
     * Only valid when the contract hasn't been hacked.
     */
    function deposit() public payable isStillValid {
        require(
            msg.value >= 0.1 ether,
            "You must have at least 0.1 ether to initiate transaction"
        );
        consumersDeposit[msg.sender] += msg.value;
    }

    /**
     * @dev Gets[buys] peanuts from the contract[Vending Machine].
     * Only valid when the contract hasn't been hacked.
     *
     * Requirements:
     *
     * - The caller must have deposited to contract and has a balance of at least `units` of peanuts to buy.
     * - The contract must have enough peanuts in stock a caller wants to buy/get.
     */
    function getPeanuts(uint256 units) public isStillValid {
        require(
            consumersDeposit[msg.sender] >= units * 0.1 ether,
            "You must pay at least 0.1 ether per peanutToken"
        );
        require(
            peanuts[address(this)] >= units,
            "Not enough peanuts to fulfill the purchase request"
        );

        consumersDeposit[msg.sender] -= units * 0.1 ether; // Debits caller's deposit
        peanuts[address(this)] -= units; // Reduce the amount purchased from the peanuts stock
        peanuts[msg.sender] += units; //  Credits the caller with amount of peanuts purchased
    }

    /**
     * @dev Withdraws deposit or balance from the contract.
     * Only valid when the contract hasn't been hacked.
     *
     * Requirements:
     *
     * - The caller must have deposited to contract and has a balance in the contract even after transaction.
     */
    function withdrawal() public isStillValid {
        uint256 contractBalanceBeforeTX = getContractBalance();
        uint256 balance = consumersDeposit[msg.sender];
        uint256 finalContractBalance = contractBalanceBeforeTX - balance;

        require(balance > 0, "Insufficient balance");

        (bool sent,) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send ether");

        consumersDeposit[msg.sender] = 0;

        uint256 contractBalanceAfterTX = getContractBalance();

        if (
            (contractBalanceAfterTX < finalContractBalance)
                && isExtContract(msg.sender)
        ) {
            txCheckLock = true;
        }
    }

    /**
     * @dev Restocks the amount of peanuts in the contract[Vending Machine], increasing
     * the total supply.
     * Can only be called by the current owner.
     */
    function restockPeanuts(uint256 _restockAmount) public onlyOwner {
        peanuts[address(this)] += _restockAmount;
    }

    /**
     * @dev Returns the opposite truthy value of txCheckLock
     * Can only be called by the current owner.
     */
    function hasNotBeenHacked() public view onlyOwner returns (bool) {
        return !txCheckLock;
    }
}
