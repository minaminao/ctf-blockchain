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

## Scoring

This challenge has been assigned a total of **90** points:
- **20** points will be awarded for a proper description of the finding that allows you to achieve the **Goal** above.
- **25** points will be awarded for a proper recommendation that fixes the issue.
- If the report is deemed valid, the remaining **45** additional points will be awarded for a working Proof of Concept exploit of the vulnerability.

:exclamation: The usage of [`cw-multi-test`](https://github.com/CosmWasm/cw-multi-test) is **mandatory** for the PoC, please take the approach of the provided integration tests as a suggestion.

:exclamation: Remember that insider threats and centralization concerns are out of the scope of the CTF.
