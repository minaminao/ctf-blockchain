pragma solidity ^0.8.17;

contract OsuCoin {
    struct Account {
        uint128 balance;
        uint32 context;
        uint96 escaped;
    }

    address public constant _0 = address(0);

    mapping(address => Account) public _accounts;

    function balanceOf(address a) public view returns (uint128) {
        return _accounts[a].balance;
    }

    function deposit() public payable {
        _accounts[msg.sender].balance += uint128(msg.value);
    }

    function withdraw(uint256) public pure {
        require(false, "You really think you could get USD from withdrawing osu!coin?");
    }

    function transfer(address from, address to, uint256 amount) public returns (uint160) {
        uint128 n = uint128(amount);
        unchecked {
            Account memory a = _accounts[from];
            Account memory b = _accounts[to];
            a.balance -= n;
            b.balance += n;
            _accounts[to] = b;
            _accounts[from] = a;
            return 0;
        }
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}
