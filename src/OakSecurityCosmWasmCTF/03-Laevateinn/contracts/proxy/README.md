# Oak Security CosmWasm CTF

## Challenge 03: *Laevateinn*

The proxy contract is the entry point for user to execute flash loan into the flash loan contract.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    RequestFlashLoan { recipient: Addr, msg: Binary },
}
```