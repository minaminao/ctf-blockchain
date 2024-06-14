# Awesomwasm 2023 CTF

## Challenge 02: *Gungnir*

Staking contract for users to lock their deposits for a fixed amount of time to generate voting power.

### Execute entry points:
```rust
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { amount: Uint128 },
    Stake { lock_amount: u128 },
    Unstake { unlock_amount: u128 },
}
```

Please check the challenge's [integration_tests](./src/integration_test.rs) for expected usage examples.
You can use these tests as a base to create your exploit Proof of Concept.

**:house: Base scenario:**
- The contract is newly instantiated with zero funds.

**:star: Goal for the challenge:**
- Demonstrate how an unprivileged user can achieve an unfair amount of voting power.

## Scoring

This challenge has been assigned a total of **150** points:
- **40** points will be awarded for a proper description of the finding that allows you to achieve the **Goal** above.
- **35** points will be awarded for a proper recommendation that fixes the issue.
- If the report is deemed valid, the remaining **75** additional points will be awarded for a working Proof of Concept exploit of the vulnerability.

:exclamation: The usage of [`cw-multi-test`](https://github.com/CosmWasm/cw-multi-test) is **mandatory** for the PoC, please take the approach of the provided integration tests as a suggestion.

:exclamation: Remember that insider threats and centralization concerns are out of the scope of the CTF.
