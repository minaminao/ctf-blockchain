pragma solidity ^0.8.13;

interface ERC20Like {
    function transfer(address dst, uint256 qty) external returns (bool);
    function transferFrom(address src, address dst, uint256 qty) external returns (bool);
    function approve(address dst, uint256 qty) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

contract TokenModule {
    function deposit(ERC20Like token, address from, uint256 amount) public {
        token.transferFrom(from, address(this), amount);
    }

    function withdraw(ERC20Like token, address to, uint256 amount) public {
        token.transfer(to, amount);
    }
}

contract Wallet {
    address public owner = msg.sender;

    mapping(address => bool) _allowed;
    mapping(address => bool) _operators;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrOperators() {
        require(msg.sender == owner || _operators[msg.sender]);
        _;
    }

    function allowModule(address module) public onlyOwner {
        _allowed[module] = true;
    }

    function disallowModule(address module) public onlyOwner {
        _allowed[module] = false;
    }

    function addOperator(address) public onlyOwner {
        _operators[owner] = true;
    }

    function removeOperator(address) public onlyOwner {
        _operators[owner] = false;
    }

    function execModule(address module, bytes memory data) public onlyOwnerOrOperators {
        require(_allowed[module], "execModule/not-allowed");
        (bool ok, bytes memory res) = module.delegatecall(data);
        require(ok, string(res));
    }
}
