# Awesomwasm 2023 CTF

## Challenge 01: *Mjolnir*

Smart contract that allows user deposit for a locked period before unlocking them.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { ids: Vec<u64> },
}
```

Please check the challenge's [integration_tests](./src/integration_test.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract contains initial funds.
- `USER` deposits funds into the contract.

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can drain all funds inside the contract.
