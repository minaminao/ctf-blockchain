# Oak Security CosmWasm CTF

## Challenge 03: *Laevateinn*

Flash loan protocol which allows users to execute a [flash loan](https://chain.link/education-hub/flash-loans) using the proxy contract.

### Flash loan contract entry points:
```rust
pub enum ExecuteMsg {
    SetProxyAddr { proxy_addr: String },
    FlashLoan {},
    SettleLoan {},
    WithdrawFunds { recipient: Addr },
    TransferOwner { new_owner: Addr },
}
```

### Proxy contract entry points:
```rust
pub enum ExecuteMsg {
    RequestFlashLoan { recipient: Addr, msg: Binary },
}
```

Please check the challenge's [integration_tests](./contracts/proxy/src/integration_tests.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The flash loan contract will have initial funds deposited.
- Proxy contract is configured to flash loan contract.

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can drain all funds from the flash loan contract.
