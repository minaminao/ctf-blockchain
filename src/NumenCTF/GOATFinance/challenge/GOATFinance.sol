// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PrivilegeFinance {
    string public name = "Privilege Finance";
    string public symbol = "PF";
    uint256 public decimals = 18;
    uint256 public totalSupply = 200000000000;
    mapping(address => uint256) public balances;
    mapping(address => address) public referrers;
    string msgsender = "0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E0";
    uint256 public rewmax = 65000000000000000000000;
    uint256 public time = 1677729607;
    uint256 public Timeinterval = 600;
    uint256 public Timewithdraw = 6000;
    uint256 public Timeintervallimit = block.timestamp;
    uint256 public Timewithdrawlimit = block.timestamp;
    bytes32 r = 0xf296e6b417ce70a933383191bea6018cb24fa79d22f7fb3364ee4f54010a472c;
    bytes32 s = 0x62bdb7aed9e2f82b2822ab41eb03e86a9536fcccff5ef6c1fbf1f6415bd872f9;
    uint8 v = 28;
    address public admin = 0x2922F8CE662ffbD46e8AE872C1F285cd4a23765b;
    uint256 public burnFees = 2;
    uint256 public ReferrerFees = 8;
    uint256 public transferRate = 10;
    address public BurnAddr = 0x000000000000000000000000000000000000dEaD;
    bool public flag;

    constructor() public {
        balances[address(this)] = totalSupply;
    }

    function Airdrop() public {
        require(balances[msg.sender] == 0 && block.timestamp >= Timeintervallimit, "Collection time not reached");
        balances[msg.sender] += 1000;
        balances[address(this)] -= 1000;
        Timeintervallimit += Timeinterval;
    }

    function deposit(address token, uint256 amount, address _ReferrerAddress) public {
        require(amount > 0, "amount zero!");
        if (
            msg.sender != address(0) && _ReferrerAddress != address(0) && msg.sender != _ReferrerAddress
                && referrers[msg.sender] == address(0)
        ) {
            referrers[msg.sender] = _ReferrerAddress;
        }
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
    }

    function withdraw(address token, uint256 amount) public {
        require(balances[msg.sender] == 0 && block.timestamp >= Timewithdrawlimit, "Collection time not reached");
        require(amount > 0 && amount <= 2000, "Financial restrictions");
        Timewithdrawlimit += Timewithdraw;
        require(amount > 0, "amount zero!");
        balances[msg.sender] += amount;
        balances[address(this)] -= amount;
    }

    function DynamicRew(address _msgsender, uint256 _blocktimestamp, uint256 _ReferrerFees, uint256 _transferRate)
        public
        returns (address)
    {
        require(_blocktimestamp < 1677729610, "Time mismatch");
        require(_transferRate <= 50 && _transferRate <= 50);
        bytes32 _hash = keccak256(abi.encodePacked(_msgsender, rewmax, _blocktimestamp));
        address a = ecrecover(_hash, v, r, s);
        require(a == admin && time < _blocktimestamp, "time or banker");
        ReferrerFees = _ReferrerFees;
        transferRate = _transferRate;
        return a;
    }

    function transfer(address recipient, uint256 amount) public {
        if (msg.sender == admin) {
            uint256 _fee = amount * transferRate / 100;
            _transfer(msg.sender, referrers[msg.sender], _fee * ReferrerFees / transferRate);
            _transfer(msg.sender, BurnAddr, _fee * burnFees / transferRate);
            _transfer(address(this), recipient, amount * amount * transferRate);
            amount = amount - _fee;
        } else if (recipient == admin) {
            uint256 _fee = amount * transferRate / 100;
            _transfer(address(this), referrers[msg.sender], _fee * ReferrerFees / transferRate);
            _transfer(msg.sender, BurnAddr, _fee * burnFees / transferRate);
            amount = amount - _fee;
        }
        _transfer(msg.sender, recipient, amount);
    }

    function _transfer(address from, address _to, uint256 _value) internal returns (bool) {
        balances[from] -= _value;
        balances[_to] += _value;
        return true;
    }

    function setflag() public {
        if (balances[msg.sender] > 10000000) {
            flag = true;
        }
    }

    function isSolved() public view returns (bool) {
        return flag;
    }
}
