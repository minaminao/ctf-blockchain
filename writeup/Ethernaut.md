# Ethernaut Solver with Foundry

**Table of Contents**
- [Common Settings](#common-settings)
- [Test All Exploit](#test-all-exploit)
- [0. Hello Ethernaut](#0-hello-ethernaut)
- [1. Fallback](#1-fallback)
- [2. Fallout](#2-fallout)
- [3. Coin Flip](#3-coin-flip)
- [4. Telephone](#4-telephone)
- [5. Token](#5-token)
- [6. Delegation](#6-delegation)
- [7. Force](#7-force)
- [8. Vault](#8-vault)
- [9. King](#9-king)
- [10. Re-entrancy](#10-re-entrancy)
- [11. Elevator](#11-elevator)
- [12. Privacy](#12-privacy)
- [13. Gatekeeper One](#13-gatekeeper-one)
- [14. Gatekeeper Two](#14-gatekeeper-two)
- [15. Naught Coin](#15-naught-coin)
- [16. Preservation](#16-preservation)
- [17. Recovery](#17-recovery)
- [18. MagicNumber](#18-magicnumber)
- [19. Alien Codex](#19-alien-codex)
- [20. Denial](#20-denial)
- [21. Shop](#21-shop)
- [22. Dex](#22-dex)
- [23. Dex Two](#23-dex-two)
- [24. Puzzle Wallet](#24-puzzle-wallet)
- [25. Motorbike](#25-motorbike)
- [26. DoubleEntryPoint](#26-doubleentrypoint)

## Common Setup

Execute the following:
```sh
export PRIVATE_KEY=<PRIVATE KEY>
export RPC_URL=<RPC URL>
export FOUNDRY_ETH_RPC_URL=$RPC_URL
```

## Test All Exploit 
```sh
forge test
```

## 0. Hello Ethernaut
**Test**
```sh
forge test --match-contract HelloEthernautExploitTest -vvvv
```
**Exploit on chain**
```sh
forge script HelloEthernautExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 1. Fallback
**Test**
```sh
forge test --match-contract FallbackExploitTest -vvvv
```
**Exploit on chain**
```sh
forge script FallbackExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 2. Fallout
**Test**
```sh
forge test --match-contract FalloutExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script FalloutExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 3. Coin Flip
**Test**
```sh
forge test --match-contract CoinFlipExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script CoinFlipExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --slow --sig "run(address)" <INSTANCE ADDRESS>
```

Command to work around the bug in https://github.com/foundry-rs/foundry/issues/2489 :
```sh
forge script CoinFlipExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --slow --sig "run(address)" <INSTANCE ADDRESS> --fork-block-number $(python -c "print($(cast block-number)-10)")
```

## 4. Telephone
**Test**
```sh
forge test --match-contract TelephoneExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script TelephoneExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 5. Token
**Test**
```sh
forge test --match-contract TokenExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script TokenExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 6. Delegation
**Test**
```sh
forge test --match-contract DelegationExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DelegationExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 7. Force
**Test**
```sh
forge test --match-contract ForceExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ForceExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 8. Vault
**Test**
```sh
forge test --match-contract VaultExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script VaultExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

`cast` command-only one-liner:
```sh
cast send --private-key $PRIVATE_KEY <INSTANCE ADDRESS> "unlock(bytes32)" $(cast storage  <INSTANCE ADDRESS> 1)
```

## 9. King
**Test**
```sh
forge test --match-contract KingExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script KingExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 10. Re-entrancy
**Test**
```sh
forge test --match-contract ReentranceExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ReentranceExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 11. Elevator
**Test**
```sh
forge test --match-contract ElevatorExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ElevatorExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 12. Privacy
**Test**
```sh
forge test --match-contract PrivacyExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PrivacyExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 13. Gatekeeper One
**Test**
```sh
forge test --match-contract GatekeeperOneExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script GatekeeperOneExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 14. Gatekeeper Two
**Test**
```sh
forge test --match-contract GatekeeperTwoExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script GatekeeperTwoExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 15. Naught Coin
**Test**
```sh
forge test --match-contract NaughtCoinExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script NaughtCoinExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 16. Preservation
**Test**
```sh
forge test --match-contract PreservationExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PreservationtExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 17. Recovery
**Exploit on chain**
```sh
cast send --private-key $PRIVATE_KEY --gas-limit 100000 <INSTANCE ADDRESS> "destroy(address)" <TOKEN ADDRESS>
```
The token address can be easily found in a blockchain explorer.

## 18. MagicNumber
**Test**
```sh
forge test --match-contract MagicNumberExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script MagicNumberExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 19. Alien Codex
**Test**
```sh
forge test --match-contract AlienCodexExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script AlienCodexExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 20. Denial
**Test**
```sh
forge test --match-contract DenialExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DenialExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 21. Shop
**Test**
```sh
forge test --match-contract ShopExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ShopExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 22. Dex
**Test**
```sh
forge test --match-contract DexExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DexExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 23. Dex Two
**Test**
```sh
forge test --match-contract DexTwoExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DexTwoExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 24. Puzzle Wallet
**Test**
```sh
forge test --match-contract PuzzleWalletExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PuzzleWalletExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 25. Motorbike
**Test**
- Foundry test function cannot detect that the code size has changed to 0.
- Anvil should be able to test it (WIP).

**Exploit**
```sh
forge script MotorbikeExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```

## 26. DoubleEntryPoint
**Test**
```sh
forge test --match-contract DoubleEntryPointExploit -vvvv
```

**Exploit on chain**
```sh
forge script DoubleEntryPointExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_URL --broadcast --sig "run(address)" <INSTANCE ADDRESS>
```
