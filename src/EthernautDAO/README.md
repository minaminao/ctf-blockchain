# EthernautDAO with Foundry

EthernautDAO: https://twitter.com/EthernautDAO

Note: All commands below need to be executed in the root of this repository.

**Table of Contents**
- [Common Setup](#common-setup)
- [Test All Exploit](#test-all-exploit)
- [1. PrivateData](#1-privatedata)
- [2. WalletLibrary](#2-walletlibrary)
- [3. CarMarket](#3-carmarket)
- [4. VendingMachine](#4-vendingmachine)
- [5. EthernautDaoToken](#5-ethernautdaotoken)

## Common Setup

Execute the following:
```sh
export RPC_GOERLI=<RPC URL>
export FOUNDRY_ETH_RPC_URL=$RPC_GOERLI
```

## Test All Exploit 
```sh
forge test --match-path "src/EthernautDAO/*"
```

## 1. PrivateData
[Challenge & Exploit codes](PrivateData)

**Test**
```sh
forge test --match-contract PrivateDataExploitTest -vvvv
```

## 2. WalletLibrary
[Challenge & Exploit codes](WalletLibrary)

**Test**
```sh
forge test --match-contract WalletLibraryExploitTest -vvvv
```

## 3. CarMarket
[Challenge & Exploit codes](CarMarket)

**Test**
```sh
forge test --match-contract CarMarketExploitTest -vvvv
```

## 4. VendingMachine 
[Challenge & Exploit codes](VendingMachine)

**Test**
```sh
forge test --match-contract VendingMachineExploitTest -vvvv
```

## 5. EthernautDaoToken
[Challenge & Exploit codes](EthernautDaoToken)

**Test**
```sh
forge test --match-contract EthernautDaoTokenExploitTest -vvvv
```

## 6. (No Name)
[Challenge & Exploit codes](NoName)

**
bash src/EthernautDAO/NoName/exploit.sh
**