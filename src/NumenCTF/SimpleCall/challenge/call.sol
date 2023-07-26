pragma solidity ^0.7.0;

contract ExistingStock {
    address public owner;
    address private reserve;

    string public name = "Existing Stock";
    string public symbol = "ES";
    uint256 public decimals = 18;
    uint256 public totalSupply = 200000000000;
    uint8 public frequency = 1;

    bool public Lock = false;
    bool public result;
    bool public flag;

    event Approval(address indexed from, address indexed to, uint256 number);
    event Transfer(address indexed from, address indexed to, uint256 number);
    event Deposit(address indexed to, uint256 number);
    event Withdraw(address indexed from, uint256 number);
    event Target(address indexed from, bool result);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function approve(address to, uint256 number) public returns (bool) {
        allowance[msg.sender][to] = number;
        emit Approval(msg.sender, to, number);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] - _value >= 0);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }

    function transferFrom(address from, address to, uint256 number) public returns (bool) {
        require(balanceOf[from] >= number);

        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            require(allowance[from][msg.sender] >= number);
            allowance[from][msg.sender] -= number;
        }

        balanceOf[from] -= number;
        balanceOf[to] += number;

        emit Transfer(from, to, number);
        return true;
    }

    function privilegedborrowing(uint256 value, address, /* secure */ address target, bytes memory data) public {
        require(Lock == false && value >= 0 && value <= 1000);
        balanceOf[address(this)] -= value;
        balanceOf[target] += value;

        address(target).call(data);

        Lock = true;

        require(balanceOf[target] >= value);
        balanceOf[address(this)] += value;
        balanceOf[target] -= value;

        Lock = false;
    }

    function withdraw(uint256 number) public {
        require(balanceOf[msg.sender] >= number);
        balanceOf[msg.sender] -= number;
        (msg.sender).transfer(number);
        emit Withdraw(msg.sender, number);
    }

    function setflag() public {
        if (balanceOf[msg.sender] > 200000 && allowance[address(this)][msg.sender] > 200000) {
            flag = true;
        }
    }

    function isSolved() public view returns (bool) {
        return flag;
    }
}
