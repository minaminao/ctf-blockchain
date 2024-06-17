# Awesomwasm 2023 CTF

## Challenge 04: *Gram*

Simplified vault for minting shares proportional to the current balance of the contract, it allows to redeem back for funds afterwards.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    /// Mint shares
    Mint {},
    /// Burn shares
    Burn { shares: Uint128 },
}
```

Please check the challenge's [integration_tests](./src/integration_tests.rs) for expected usage examples. You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract is newly instantiated with zero funds.

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can withdraw more funds than deposited.
