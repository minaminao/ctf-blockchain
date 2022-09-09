# Ethernaut with Foundry

Ethernaut: https://ethernaut.openzeppelin.com/

Note: All commands below need to be executed in the root of this repository.

**Table of Contents**
- [Common Setup](#common-setup)
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
- [27. Good Samaritan](#27-good-samaritan)

## Common Setup

Execute the following commands:
```sh
export PRIVATE_KEY=<PRIVATE KEY>
export RPC_RINKEBY=<RPC RINKEBY>
export FOUNDRY_ETH_RPC_URL=$RPC_RINKEBY
```

## Test All Exploit 
```sh
forge test --match-path "src/Ethernaut/*"
```

## 0. Hello Ethernaut
[Challenge & Exploit codes](HelloEthernaut)

**Test**
```sh
forge test --match-contract HelloEthernautExploitTest -vvvv
```
**Exploit on chain**
```sh
forge script HelloEthernautExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 1. Fallback
[Challenge & Exploit codes](Fallback)

**Test**
```sh
forge test --match-contract FallbackExploitTest -vvvv
```
**Exploit on chain**
```sh
forge script FallbackExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 2. Fallout
[Challenge & Exploit codes](Fallout)

**Test**
```sh
forge test --match-contract FalloutExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script FalloutExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 3. Coin Flip
[Challenge & Exploit codes](CoinFlip)

**Test**
```sh
forge test --match-contract CoinFlipExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script CoinFlipExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --slow --sig "run(address)" $INSTANCE_ADDRESS
```

Command to work around the bug in https://github.com/foundry-rs/foundry/issues/2489 :
```sh
forge script CoinFlipExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --slow --sig "run(address)" $INSTANCE_ADDRESS --fork-block-number $(python -c "print($(cast block-number)-10)")
```

## 4. Telephone
[Challenge & Exploit codes](Telephone)

**Test**
```sh
forge test --match-contract TelephoneExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script TelephoneExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 5. Token
[Challenge & Exploit codes](Token)

**Test**
```sh
forge test --match-contract TokenExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script TokenExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 6. Delegation
[Challenge & Exploit codes](Delegation)

**Test**
```sh
forge test --match-contract DelegationExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DelegationExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 7. Force
[Challenge & Exploit codes](Force)

**Test**
```sh
forge test --match-contract ForceExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ForceExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 8. Vault
[Challenge & Exploit codes](Vault)

**Test**
```sh
forge test --match-contract VaultExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script VaultExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

`cast` command-only one-liner:
```sh
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "unlock(bytes32)" $(cast storage  $INSTANCE_ADDRESS 1)
```

## 9. King
[Challenge & Exploit codes](King)

**Test**
```sh
forge test --match-contract KingExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script KingExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 10. Re-entrancy
[Challenge & Exploit codes](Reentrance)

**Test**
```sh
forge test --match-contract ReentranceExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ReentranceExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 11. Elevator
[Challenge & Exploit codes](Elevator)

**Test**
```sh
forge test --match-contract ElevatorExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ElevatorExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 12. Privacy
[Challenge & Exploit codes](Privacy)

**Test**
```sh
forge test --match-contract PrivacyExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PrivacyExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 13. Gatekeeper One
[Challenge & Exploit codes](GatekeeperOne)

**Test**
```sh
forge test --match-contract GatekeeperOneExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script GatekeeperOneExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 14. Gatekeeper Two
[Challenge & Exploit codes](GatekeeperTwo)

**Test**
```sh
forge test --match-contract GatekeeperTwoExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script GatekeeperTwoExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 15. Naught Coin
[Challenge & Exploit codes](NaughtCoin)

**Test**
```sh
forge test --match-contract NaughtCoinExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script NaughtCoinExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 16. Preservation
[Challenge & Exploit codes](Preservation)

**Test**
```sh
forge test --match-contract PreservationExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PreservationtExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 17. Recovery
[Challenge & Exploit codes](Recovery)

**Exploit on chain**
```sh
cast send --private-key $PRIVATE_KEY --gas-limit 100000 $INSTANCE_ADDRESS "destroy(address)" <TOKEN ADDRESS>
```
The token address can be easily found in a blockchain explorer.

## 18. MagicNumber
[Challenge & Exploit codes](MagicNumber)

Exploit written in Huff: https://github.com/minaminao/huff-ethernaut-magic-number

**Test**
```sh
forge test --match-contract MagicNumberExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script MagicNumberExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 19. Alien Codex
[Challenge & Exploit codes](AlienCodex)

**Test**
```sh
forge test --match-contract AlienCodexExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script AlienCodexExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 20. Denial
[Challenge & Exploit codes](Denial)

**Test**
```sh
forge test --match-contract DenialExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DenialExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 21. Shop
[Challenge & Exploit codes](Shop)

**Test**
```sh
forge test --match-contract ShopExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script ShopExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 22. Dex
[Challenge & Exploit codes](Dex)

**Test**
```sh
forge test --match-contract DexExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DexExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 23. Dex Two
[Challenge & Exploit codes](DexTwo)

**Test**
```sh
forge test --match-contract DexTwoExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script DexTwoExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 24. Puzzle Wallet
[Challenge & Exploit codes](PuzzleWallet)

**Test**
```sh
forge test --match-contract PuzzleWalletExploitTest -vvvv
```

**Exploit on chain**
```sh
forge script PuzzleWalletExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 25. Motorbike
[Challenge & Exploit codes](Motorbike)

**Test**
- Foundry test function cannot detect that the code size has changed to 0.
- Anvil should be able to test it (WIP).

**Exploit**
```sh
forge script MotorbikeExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 26. DoubleEntryPoint
[Challenge & Exploit codes](DoubleEntryPoint)

**Test**
```sh
forge test --match-contract DoubleEntryPointExploit -vvvv
```

**Exploit on chain**
```sh
forge script DoubleEntryPointExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```

## 27. Good Samaritan 
[Challenge & Exploit codes](GoodSamaritan)

**Test**
```sh
forge test --match-contract GoodSamaritanExploit -vvvv
```

**Exploit on chain**
```sh
forge script GoodSamaritanExploitScript -vvvv --private-key $PRIVATE_KEY --fork-url $RPC_RINKEBY --broadcast --sig "run(address)" $INSTANCE_ADDRESS
```