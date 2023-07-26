pragma solidity ^0.8.13;

contract Deployer {
    constructor(bytes memory code) {
        assembly {
            return(add(code, 0x20), mload(code))
        }
    }
}

contract SmartCounter {
    address public owner;
    address public target;
    bool flag = false;

    constructor(address owner_) {
        owner = owner_;
    }

    function create(bytes memory code) public {
        require(code.length <= 24);
        target = address(new Deployer(code));
    }

    function A_delegateccall(bytes memory data) public {
        (bool success,) = target.delegatecall(data);
        success;
        require(owner == msg.sender);
        flag = true;
    }

    function isSolved() public view returns (bool) {
        return flag;
    }
}
