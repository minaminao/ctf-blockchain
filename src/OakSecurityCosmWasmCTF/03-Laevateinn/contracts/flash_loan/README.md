# Oak Security CosmWasm CTF

## Challenge 03: *Laevateinn*

The flash loan contract is the core logic for the flash loan implementation.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    SetProxyAddr { proxy_addr: String },
    FlashLoan {},
    SettleLoan {},
    WithdrawFunds { recipient: Addr },
    TransferOwner { new_owner: Addr },
}
```