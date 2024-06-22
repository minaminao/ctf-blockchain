# Awesomwasm 2023 CTF

## Challenge 06: *Hofund*

The contract allow anyone to propose themselves for the `owner` role of the contract, the rest of the users can vote in favor by sending a governance token.
If a proposal was voted for with more than a third of the current supply, the user gets the `owner` role.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    Propose {},
    ResolveProposal {},
    OwnerAction {
        action: CosmosMsg,
    },
    Receive(Cw20ReceiveMsg),
}
```

Please check the challenge's [integration_tests](./src/integration_tests.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract is newly instantiated

**:star: Goal for the challenge:**
- Demonstrate how a proposer can obtain the owner role without controlling 1/3 of the total supply.
