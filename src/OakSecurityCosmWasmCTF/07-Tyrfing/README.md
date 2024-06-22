# Awesomwasm 2023 CTF

## Challenge 07: *Tyrfing*

Simplified vault that accounts for the top depositor!
The `owner` can set the threshold to become top depositor.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { amount: Uint128 },
    OwnerAction { msg: CosmosMsg },
    UpdateConfig { new_threshold: Uint128 },
}
```

Please check the challenge's [integration_tests](./src/integration_tests.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract is newly instantiated.
- `USER1` and `USER2` deposit 10_000 tokens each
- The owner role is assigned to the `ADMIN` address

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can drain all the contract's funds.
