# Awesomwasm 2023 CTF

## Challenge 05: *Draupnir*

Simplified vault where users can deposit and withdraw their tokens which will be internally accounted.
The vault's `owner` can perform arbitrary actions through the `OwnerAction` entry point.
In addition, a two step address transfer is implemented for the `owner` role.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { amount: Uint128 },
    OwnerAction { msg: CosmosMsg },
    ProposeNewOwner { new_owner: String },
    AcceptOwnership {},
    DropOwnershipProposal {},
}
```

Please check the challenge's [integration_tests](./src/integration_tests.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract has been instantiated with zero funds.
- `USER1` and `USER2` deposit `10_000` tokens each.
- The owner role is assigned to the `ADMIN` address.

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can drain all the funds inside the contract.
