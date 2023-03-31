pragma solidity ^0.6.12;

contract Existing {
    string public name = "Existing";
    string public symbol = "EG";
    uint256 public decimals = 18;
    uint256 public totalSupply = 10000000;
    bool public flag = false;

    mapping(address => bool) public status;

    event SendFlag(address addr);

    mapping(address => uint256) public balanceOf;

    bytes20 internal appearance = bytes20(bytes32("ZT")) >> 144;
    bytes20 internal maskcode = bytes20(uint160(0xffff));

    constructor() public {
        balanceOf[address(this)] += totalSupply;
    }

    function transfer(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "amount exceed");
        require(to != address(0), "you cant burn my token");
        require(balanceOf[to] + amount >= balanceOf[to]);
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    modifier only_family() {
        require(is_my_family(msg.sender), "no no no,my family only");
        _;
    }

    modifier only_EOA(address msgs) {
        uint256 x;
        assembly {
            x := extcodesize(msgs)
        }
        require(x == 0, "Only EOA can do that");
        _;
    }

    function is_my_family(address account) internal returns (bool) {
        bytes20 you = bytes20(account);

        bytes20 code = maskcode;
        bytes20 feature = appearance;

        for (uint256 i = 0; i < 34; i++) {
            if (you & code == feature) {
                return true;
            }

            code <<= 4;
            feature <<= 4;
        }
        return false;
    }

    function share_my_vault() external only_EOA(msg.sender) only_family {
        uint256 add = balanceOf[address(this)];
        _transfer(address(this), msg.sender, add);
    }

    function setflag() external {
        if (balanceOf[msg.sender] >= totalSupply) {
            flag = true;
        }
    }

    function isSolved() external view returns (bool) {
        return flag;
    }
}
