# WalletLibrary & Wallet

Transactions
- https://goerli.etherscan.io/tx/0xc1a89575fe13b57951e2e1c1a32fceafc9aa6a6bec07ab090f908068189a8643
  - nonce: 0
  - WalletLibrary.sol
- https://goerli.etherscan.io/tx/0x1e9960a6417a66c0168c35ffbde18a26b5281811526c5c79faf49245fa61d5c0
  - nonce: 1
  - Wallet.sol

```sh
$ cast run 0x1e9960a6417a66c0168c35ffbde18a26b5281811526c5c79faf49245fa61d5c0
Executing previous transactions from the block.
Traces:
  [425501] → new Wallet@"0x19c8…4cb7"
    ├─ [180303] WalletLibrary::initWallet([0x89d8632bc8020a7ddd540e6d9b118aa9ec19af27, 0x8a5722860c6691f2a25d141d73e678bf1078aac3, 0x6813eb9362372eef6200f3b1dbc3f819671cba69], 2) [delegatecall]
    │   └─ ← ()
    └─ ← 1089 bytes of code
```
2-of-3.