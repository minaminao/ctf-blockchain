# CTF Blockchain Challenges

This repository collects blockchain challenges in CTFs and wargames.

These challenges are categorized by topic, not by difficulty or recommendation.
Also, there are my writeups and exploits for some challenges (e.g., [Paradigm CTF 2022](src/ParadigmCTF2022/)).
Please be aware that these contain spoilers.

If there are any incorrect descriptions, I would appreciate it if you could let me know via issue or PR!

---

**Table of Contents**
- [Ethereum](#ethereum)
  - [Smart contract basics](#smart-contract-basics)
  - [EVM puzzles](#evm-puzzles)
  - [Misuse of `tx.origin`](#misuse-of-txorigin)
  - [Weak sources of randomness from chain attributes](#weak-sources-of-randomness-from-chain-attributes)
  - [ERC-20 basics](#erc-20-basics)
  - [Storage overwrite by `delegatecall`](#storage-overwrite-by-delegatecall)
  - [Context mismatch in `delegatecall`](#context-mismatch-in-delegatecall)
  - [Integer overflow](#integer-overflow)
  - [Ether transfer failures for non-payable contracts](#ether-transfer-failures-for-non-payable-contracts)
  - [Forced Ether transfers to non-payable contracts via `selfdestruct`](#forced-ether-transfers-to-non-payable-contracts-via-selfdestruct)
  - [Large gas consumption by contract callees](#large-gas-consumption-by-contract-callees)
  - [Forgetting to set `view`/`pure` to interface and abstract contract functions](#forgetting-to-set-viewpure-to-interface-and-abstract-contract-functions)
  - [`view` functions that do not always return same values](#view-functions-that-do-not-always-return-same-values)
  - [Mistakes in setting `storage` and `memory`](#mistakes-in-setting-storage-and-memory)
  - [Tracing transactions](#tracing-transactions)
  - [Reversing states](#reversing-states)
  - [Reversing transactions](#reversing-transactions)
  - [Reversing EVM bytecodes](#reversing-evm-bytecodes)
  - [EVM assembly logic bugs](#evm-assembly-logic-bugs)
  - [EVM bytecode golf](#evm-bytecode-golf)
  - [Jump-oriented programming](#jump-oriented-programming)
  - [Gas optimization](#gas-optimization)
  - [Collisions when using `abi.encodePacked` with variable length arguments](#collisions-when-using-abiencodepacked-with-variable-length-arguments)
  - [Bypassing verifications with zero iteration loops](#bypassing-verifications-with-zero-iteration-loops)
  - [Reentrancy attacks](#reentrancy-attacks)
  - [Flash loan basics](#flash-loan-basics)
  - [Governance attacks by executing flash loans during snapshots](#governance-attacks-by-executing-flash-loans-during-snapshots)
  - [Bypassing repayments of push architecture flash loans](#bypassing-repayments-of-push-architecture-flash-loans)
  - [Bugs in AMM price calculation algorithm](#bugs-in-amm-price-calculation-algorithm)
  - [Attacks using custom tokens](#attacks-using-custom-tokens)
  - [Oracle manipulation attacks without flash loans](#oracle-manipulation-attacks-without-flash-loans)
  - [Oracle manipulation attacks with flash loans](#oracle-manipulation-attacks-with-flash-loans)
  - [Sandwich attacks](#sandwich-attacks)
  - [Recoveries of private keys by same-nonce attacks](#recoveries-of-private-keys-by-same-nonce-attacks)
  - [ECDSA signature malleability attacks](#ecdsa-signature-malleability-attacks)
  - [Brute-forcing addresses](#brute-forcing-addresses)
  - [Recoveries of public keys](#recoveries-of-public-keys)
  - [Encryption and decryption in secp256k1](#encryption-and-decryption-in-secp256k1)
  - [Bypassing bots and taking ERC-20 tokens owned by wallets with known private keys](#bypassing-bots-and-taking-erc-20-tokens-owned-by-wallets-with-known-private-keys)
  - [Claimable intermediate nodes of Merkle trees](#claimable-intermediate-nodes-of-merkle-trees)
  - [Precompiled contracts](#precompiled-contracts)
  - [Faking errors](#faking-errors)
  - [Foundry cheatcodes](#foundry-cheatcodes)
  - [Front-running](#front-running)
  - [Back-running](#back-running)
  - [Head overflow bugs in calldata tuple ABI-reencoding (\< Solidity 0.8.16)](#head-overflow-bugs-in-calldata-tuple-abi-reencoding--solidity-0816)
  - [Overwriting storage slots via local storage variables (\< Solidity 0.8.1)](#overwriting-storage-slots-via-local-storage-variables--solidity-081)
  - [Overwriting arbitrary storage slots by setting array lengths to `2^256-1` (\< Solidity 0.6.0)](#overwriting-arbitrary-storage-slots-by-setting-array-lengths-to-2256-1--solidity-060)
  - [Constructors that is just functions by typos (\< Solidity 0.5.0)](#constructors-that-is-just-functions-by-typos--solidity-050)
  - [Overwriting storage slots via uninitialized storage pointer (\< Solidity 0.5.0)](#overwriting-storage-slots-via-uninitialized-storage-pointer--solidity-050)
  - [Other ad-hoc vulnerabilities and methods](#other-ad-hoc-vulnerabilities-and-methods)
- [Bitcoin](#bitcoin)
  - [Bitcoin basics](#bitcoin-basics)
  - [Recoveries of private keys by same-nonce attacks](#recoveries-of-private-keys-by-same-nonce-attacks-1)
  - [Bypassing PoW of other applications using Bitcoin's PoW database](#bypassing-pow-of-other-applications-using-bitcoins-pow-database)
- [Solana](#solana)
- [Cosmos](#cosmos)
  - [CosmWasm](#cosmwasm)
  - [Application-specific blockchain](#application-specific-blockchain)
- [Move](#move)
- [Cairo](#cairo)
- [Other Blockchain-Related](#other-blockchain-related)

---

## Ethereum

Note:
- If an attack is only valid for a particular version of Solidity and not for the latest version, the version is noted at the end of the heading.
- To avoid notation fluctuations, EVM terms are avoided as much as possible and Solidity terms are used.

### Smart contract basics
- These challenges can be solved if you know the basic mechanics of Ethereum, [the basic language specification of Solidity](https://docs.soliditylang.org/en/latest/), and the basic operation of contracts.

| Challenge                                                          | Note, Keywords         |
| ------------------------------------------------------------------ | ---------------------- |
| [Capture The Ether: Deploy a contract](src/CaptureTheEther/)       | faucet, wallet         |
| [Capture The Ether: Call me](src/CaptureTheEther/)                 | contract call          |
| [Capture The Ether: Choose a nickname](src/CaptureTheEther/)       | contract call          |
| [Capture The Ether: Guess the number](src/CaptureTheEther/)        | contract call          |
| [Capture The Ether: Guess the secret number](src/CaptureTheEther/) | `keccak256`            |
| [Ethernaut: 0. Hello Ethernaut](src/Ethernaut/)                    | contract call, ABI     |
| [Ethernaut: 1. Fallback](src/Ethernaut/)                           | receive Ether function |
| [Paradigm CTF 2021: Hello](src/ParadigmCTF2021/)                   | contract call          |
| [0x41414141 CTF: sanity-check](src/0x41414141CTF/)                 | contract call          |
| [Paradigm CTF 2022: RANDOM](src/ParadigmCTF2022/)                  | contract call          |
| [DownUnderCTF 2022: Solve Me](src/DownUnderCTF2022/)               |                        |
| [LA CTF 2024: remi's-world](src/LACTF2024/)                        |                        |

### EVM puzzles
- Puzzle challenges that can be solved by understanding the EVM specifications.
- No vulnerabilities are used to solve these challenges.

| Challenge                                                          | Note, Keywords                                                         |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| [Capture The Ether: Guess the new number](src/CaptureTheEther/)    | `block.number`, `block.timestamp`                                      |
| [Capture The Ether: Predict the block hash](src/CaptureTheEther/)  | `blockhash`                                                            |
| [Ethernaut: 13. Gatekeeper One](src/Ethernaut/)                    | `msg.sender != tx.origin`, `gasleft().mod(8191) == 0`, type conversion |
| [Ethernaut: 14. Gatekeeper Two](src/Ethernaut/)                    | `msg.sender != tx.origin`, `extcodesize` is 0                          |
| Cipher Shastra: Minion                                             | `msg.sender != tx.origin`, `extcodesize` is 0, `block.timestamp`       |
| SECCON Beginners CTF 2020: C4B                                     | `block.number`                                                         |
| [Paradigm CTF 2021: Babysandbox](src/ParadigmCTF2021/Babysandbox/) | `staticcall`, `call`, `delegatecall`, `extcodesize` is 0               |
| Paradigm CTF 2021: Lockbox                                         | `ecrecover`, `abi.encodePacked`, `msg.data.length`                     |
| [EthernautDAO: 6. (No Name)](src/EthernautDAO/NoName/)             | `block.number`, gas price war                                          |
| [fvictorio's EVM Puzzles](src/FvictorioEVMPuzzles/)                |                                                                        |
| [Huff Challenge: Challenge #3](src/HuffChallenge/)                 |                                                                        |
| [Paradigm CTF 2022: LOCKBOX2](src/ParadigmCTF2022/)                |                                                                        |
| [Paradigm CTF 2022: SOURCECODE](src/ParadigmCTF2022/)              | quine                                                                  |
| [Numen Cyber CTF 2023: LittleMoney](src/NumenCTF/)                 | function pointer                                                       |
| [Numen Cyber CTF 2023: ASSLOT](src/NumenCTF/)                      | `staticcall` that return different values                              |
| [Paradigm CTF 2023: Black Sheep](src/ParadigmCTF2023/)             | Huff                                                                   |

### Misuse of `tx.origin`
- `tx.origin` refers to the address of the transaction publisher and should not be used as the address of the contract caller `msg.sender`.

| Challenge                                 | Note, Keywords |
| ----------------------------------------- | -------------- |
| [Ethernaut: 4. Telephone](src/Ethernaut/) |                |

### Weak sources of randomness from chain attributes
- Since contract bytecodes are publicly available, it is easy to predict pseudorandom numbers whose generation is completed on-chain (using only states, not off-chain data).
- It is equivalent to having all the parameters of a pseudorandom number generator exposed.
- If you want to use random numbers that are unpredictable to anyone, use a decentralized oracle with a random number function.
  - For example, [Chainlink VRF](https://docs.chain.link/docs/chainlink-vrf/), which implements Verifiable Random Function (VRF).

| Challenge                                                     | Note, Keywords |
| ------------------------------------------------------------- | -------------- |
| [Capture The Ether: Predict the future](src/CaptureTheEther/) |                |
| [Ethernaut: 3. Coin Flip](src/Ethernaut/)                     |                |
| [DownUnderCTF 2022: Crypto Casino](src/DownUnderCTF2022/)     |                |
| [Paradigm CTF 2023: SkillBasedGame](src/ParadigmCTF2023/)     |                |

### ERC-20 basics
- These challenges can be solved with an understanding of the [ERC-20 token standard](https://eips.ethereum.org/EIPS/eip-20).

| Challenge                                                                | Note, Keywords                        |
| ------------------------------------------------------------------------ | ------------------------------------- |
| [Ethernaut: 15. Naught Coin](src/Ethernaut/)                             | `transfer`, `approve`, `transferFrom` |
| [Paradigm CTF 2021: Secure](src/ParadigmCTF2021)                         | WETH                                  |
| [DeFi-Security-Summit-Stanford: VToken](src/DeFiSecuritySummitStanford/) |                                       |

### Storage overwrite by `delegatecall`
- `delegatecall` is a potential source of vulnerability because the storage of the `delegatecall` caller contract can be overwritten by the called contract.

| Challenge                                                                              | Note, Keywords                                                                                    |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| [Ethernaut: 6. Delegation](src/Ethernaut/)                                             |                                                                                                   |
| [Ethernaut: 16. Preservation](src/Ethernaut/)                                          |                                                                                                   |
| [Ethernaut: 24. Puzzle Wallet](src/Ethernaut/)                                         | proxy contract                                                                                    |
| [Ethernaut: 25. Motorbike](src/Ethernaut/)                                             | proxy contract, [EIP-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967) |
| [DeFi-Security-Summit-Stanford: InSecureumLenderPool](src/DeFiSecuritySummitStanford/) | flash loan                                                                                        |
| [QuillCTF2023: D3l3g4t3](src/QuillCTF2022/D3l3g4t3)                                    |                                                                                                   |
| [Numen Cyber CTF 2023: Counter](src/NumenCTF/)                                         | writing EVM code                                                                                  |

### Context mismatch in `delegatecall`
- Contracts called by `delegatecall` are executed in the context of the `delegatecall` caller contract. 
- If the function does not carefully consider the context, a bug will be created.

| Challenge                                                 | Note, Keywords             |
| --------------------------------------------------------- | -------------------------- |
| [EthernautDAO: 3. CarMarket](src/EthernautDAO/CarMarket/) | Non-use of `address(this)` |

### Integer overflow
- For example, subtracting `1` from the value of a variable of `uint` type when the value is `0` causes an arithmetic overflow.
- Arithmetic overflow has been detected and reverted state since Solidity v0.8.0.
- Contracts written in earlier versions can be checked by using [the SafeMath library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol).

| Challenge                                              | Note, Keywords |
| ------------------------------------------------------ | -------------- |
| [Capture The Ether: Token sale](src/CaptureTheEther/)  | multiplication |
| [Capture The Ether: Token whale](src/CaptureTheEther/) | subtraction    |
| [Ethernaut: 5. Token](src/Ethernaut/)                  | subtraction    |

### Ether transfer failures for non-payable contracts
- Do not create a contract on the assumption that normal Ether transfer (`.send()` or `.transfer()`) can always be executed.
- If a destination is a contract and there is no receive Ether function or payable fallback function, Ether cannot be transferred.
- However, instead of the normal transfer functions, the `selfdestruct` described in the next section can be used to force such a contract to transfer Ether.

| Challenge                                                                  | Note, Keywords |
| -------------------------------------------------------------------------- | -------------- |
| [Ethernaut: 9. King](src/Ethernaut/)                                       |                |
| [Project SEKAI CTF 2022: Random Song](src/ProjectSekaiCTF2022/RandomSong/) | Chainlink VRF  |

### Forced Ether transfers to non-payable contracts via `selfdestruct`
- If a contract does not have a receive Ether function and a payable fallback function, it is not guaranteed that Ether will not be received.
- When a contract executes `selfdestruct`, it can transfer its Ether to another contract or EOA, and this `selfdestruct` transfer can be forced even if the destination contract does not have the receive Ether function and the payable fallback function. 
- If the application is built on the assumption that the Ether is `0`, it could be a bug.

| Challenge                                                  | Note, Keywords   |
| ---------------------------------------------------------- | ---------------- |
| [Capture The Ether: Retirement fund](src/CaptureTheEther/) | integer overflow |
| [Ethernaut: 7. Force](src/Ethernaut/)                      |                  |

### Large gas consumption by contract callees
- A large amount of gas can be consumed by loops and recursion in `call`, and there may not be enough gas for the rest of the process.
- Until Solidity v0.8.0, zero division and `assert(false)` could consume a lot of gas.

| Challenge                               | Note, Keywords |
| --------------------------------------- | -------------- |
| [Ethernaut: 20. Denial](src/Ethernaut/) |                |

### Forgetting to set `view`/`pure` to interface and abstract contract functions
- If you forget to set `view` or `pure` for a function and design your application under the assumption that the state will not change, it will be a bug.

| Challenge                                 | Note, Keywords |
| ----------------------------------------- | -------------- |
| [Ethernaut: 11. Elevator](src/Ethernaut/) | interface      |

### `view` functions that do not always return same values
- Since `view` functions can read state, they can be conditionally branched based on state and do not necessarily return the same value.

| Challenge                             | Note, Keywords |
| ------------------------------------- | -------------- |
| [Ethernaut: 21. Shop](src/Ethernaut/) |                |

### Mistakes in setting `storage` and `memory`
- If `storage` and `memory` are not set properly, old values may be referenced, or overwriting may not occur, resulting in vulnerability.

| Challenge            | Note, Keywords                                                                                                  |
| -------------------- | --------------------------------------------------------------------------------------------------------------- |
| N1CTF 2021: BabyDefi | [Cover Protocol infinite minting](https://coverprotocol.medium.com/12-28-post-mortem-34c5f9f718d4) + flash loan |

### Tracing transactions
- Various information can be obtained just by following the flow of transaction processing.
- Blockchain explorers such as Etherscan are useful.

| Challenge                                 | Note, Keywords                    |
| ----------------------------------------- | --------------------------------- |
| [Ethernaut: 17. Recovery](src/Ethernaut/) | loss of deployed contract address |

### Reversing states 
- Since the state and the bytecodes of contracts are public, all variables, including private variables, are readable.
- Private variables are only guaranteed not to be directly readable by other contracts, but we, as an entity outside the blockchain, can read them.

| Challenge                                                          | Note, Keywords |
| ------------------------------------------------------------------ | -------------- |
| [Capture The Ether: Guess the random number](src/CaptureTheEther/) |                |
| [Ethernaut: 8. Vault](src/Ethernaut/)                              |                |
| [Ethernaut: 12. Privacy](src/Ethernaut/)                           |                |
| Cipher Shastra: Sherlock                                           |                |
| [0x41414141 CTF: secure enclave](src/0x41414141CTF/)               | log, storage   |
| [EthernautDAO: 1. PrivateData](src/EthernautDAO/PrivateData/)      |                |

### Reversing transactions
- Reversing the contents of a transaction or how the state has been changed by the transaction.

| Challenge                                                        | Note, Keywords |
| ---------------------------------------------------------------- | -------------- |
| [darkCTF: Secret Of The Contract](src/DarkCTF/)                  |                |
| [DownUnderCTF 2022: Secret and Ephemeral](src/DownUnderCTF2022/) |                |

### Reversing EVM bytecodes
- Reversing a contract for which code is not given in whole or in part.
- [evm.codes](https://www.evm.codes/) is very useful.
- Use a decompiler (e.g., [Dedaub Decompiler](https://app.dedaub.com/decompile), [heimdall](https://github.com/Jon-Becker/heimdall-rs)).
- Use a disassembler (e.g., [ByteGraph](https://bytegraph.xyz/), [ethersplay](https://github.com/crytic/ethersplay)).
- Use a debugger (e.g., [Foundry Debugger](https://book.getfoundry.sh/forge/debugger)).

| Challenge                                                       | Note, Keywords                          |
| --------------------------------------------------------------- | --------------------------------------- |
| Incognito 2.0: Ez                                               | keep in plain text                      |
| [0x41414141 CTF: crackme.sol](src/0x41414141CTF/)               | decompile                               |
| [0x41414141 CTF: Crypto Casino](src/0x41414141CTF/)             | bypass condition check                  |
| Paradigm CTF 2021: Babyrev                                      |                                         |
| 34C3 CTF: Chaingang                                             |                                         |
| Blaze CTF 2018: Smart? Contract                                 |                                         |
| DEF CON CTF Qualifier 2018: SAG?                                |                                         |
| pbctf 2020: pbcoin                                              |                                         |
| Paradigm CTF 2022: STEALING-SATS                                |                                         |
| Paradigm CTF 2022: ELECTRIC-SHEEP                               |                                         |
| Paradigm CTF 2022: FUN-REVERSING-CHALLENGE                      |                                         |
| [DownUnderCTF 2022: EVM Vault Mechanism](src/DownUnderCTF2022/) |                                         |
| [EKOPARTY CTF 2022: Byte](src/EkoPartyCTF2022/)                 | stack tracing                           |
| [EKOPARTY CTF 2022: SmartRev](src/EkoPartyCTF2022/)             | memory tracing                          |
| [Numen Cyber CTF 2023: HEXP](src/NumenCTF/)                     | previous block hash == gas price % 2^24 |
| [BlazCTF 2023: Maze](src/BlazCTF2023/)                          |                                         |
| [BlazCTF 2023: Jambo](src/BlazCTF2023/)                         |                                         |
| [BlazCTF 2023: Ghost](src/BlazCTF2023/)                         |                                         |
| [Curta: Lana](src/Curta/20_Lana/)                               | LLVM                                    |

### EVM assembly logic bugs
- Logic bugs in assemblies such as Yul

| Challenge                                               | Note, Keywords |
| ------------------------------------------------------- | -------------- |
| [Project SEKAI CTF 2024: Zoo](src/ProjectSekaiCTF2024/) | `Pausable`     |

### EVM bytecode golf
- These challenges have a limit on the length of the bytecode to be created.

| Challenge                                              | Note, Keywords                                                                                                 |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| [Ethernaut: 18. MagicNumber](src/Ethernaut/)           |                                                                                                                |
| [Paradigm CTF 2021: Rever](src/ParadigmCTF2021/Rever/) | Palindrome detection. In addition, the code that inverts the bytecode must also be able to detect palindromes. |
| [Huff Challenge: Challenge #1](src/HuffChallenge/)     |                                                                                                                |

### Jump-oriented programming
- Jump-Oriented Programming (JOP)

| Challenge                                                                          | Note, Keywords |
| ---------------------------------------------------------------------------------- | -------------- |
| [SECCON CTF 2023 Quals: Tokyo Payload](https://github.com/minaminao/tokyo-payload) |                |
| Paradigm CTF 2021: JOP                                                             |                |
| Real World CTF 3rd: Re:Montagy                                                     |                |

### Gas optimization
- These challenges have a limit on the gas to be consumed.

| Challenge                                          | Note, Keywords |
| -------------------------------------------------- | -------------- |
| [Huff Challenge: Challenge #2](src/HuffChallenge/) |                |

### Collisions when using `abi.encodePacked` with variable length arguments

| Challenge                                                        | Note, Keywords |
| ---------------------------------------------------------------- | -------------- |
| [SEETF 2023: Operation Feathered Fortune Fiasco](src/SEETF2023/) |                |

### Bypassing verifications with zero iteration loops

| Challenge                                   | Note, Keywords             |
| ------------------------------------------- | -------------------------- |
| [SEETF 2023: Murky SEEPass](src/SEETF2023/) | array length, Merkle proof |

### Reentrancy attacks
- In case a function of contract `A` contains interaction with another contract `B` or Ether transfer to `B`, the control is temporarily transferred to `B`.
- Since `B` can call `A` in this control, it will be a bug if the design is based on the assumption that `A` is not called in the middle of the execution of that function.
- For example, when `B` executes the `withdraw` function to withdraw Ether deposited in `A`, the Ether transfer triggers a control shift to `B`, and during the `withdraw` function, `B` executes `A`'s `withdraw` function again. Even if the `withdraw` function is designed to prevent withdrawal of more than the limit if it is simply called twice, if the `withdraw` function is executed in the middle of the `withdraw` function, it may be designed to bypass the limit check.
- To prevent reentrancy attacks, use the Checks-Effects-Interactions pattern.

| Challenge                                                                       | Note, Keywords             |
| ------------------------------------------------------------------------------- | -------------------------- |
| [Capture The Ether: Token bank](src/CaptureTheEther/)                           | ERC-223, `tokenFallback()` |
| [Ethernaut: 10. Re-entrancy](src/Ethernaut/)                                    | `call`                     |
| Paradigm CTF 2021: Yield Aggregator                                             |                            |
| HTB University CTF 2020 Quals: moneyHeist                                       |                            |
| [EthernautDAO: 4. VendingMachine](src/EthernautDAO/VendingMachine/)             | `call`                     |
| [DeFi-Security-Summit-Stanford: InsecureDexLP](src/DeFiSecuritySummitStanford/) | ERC-223, `tokenFallback()` |
| [MapleCTF 2022: maplebacoin](src/MapleCTF/)                                     |                            |
| [QuillCTF 2022: SafeNFT](src/QuillCTF2022/SafeNFT)                              | ERC721, `_safeMint()`      |
| [Numen Cyber CTF 2023: SimpleCall](src/NumenCTF/)                               | `call`                     |
| [SEETF 2023: PigeonBank](src/SEETF2023/)                                        |                            |
| [Project SEKAI CTF 2023: Re-Remix](src/ProjectSekaiCTF2023/)                    | Read-Only Reentrancy       |
| [SECCON Beginners CTF 2024: vote4b](src/SECCONBeginnersCTF2024/vote4b/)         | ERC721, `_safeMint()`      |

### Flash loan basics
- Flash loans are uncollateralized loans that allow the borrowing of an asset, as long as the borrowed assets are returned before the end of the transaction. The borrower can deal with the borrowed assets any way they want within the transaction.
- By making large asset moves, attacks can be made to snatch funds from DeFi applications or to gain large amounts of votes for participation in governance.
- A solution to attacks that use flash loans to corrupt oracle values is to use a decentralized oracle.

| Challenge                              | Note, Keywords                                                                                                                                                |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Damn Vulnerable DeFi: 1. Unstoppable   | Simple flash loan with a single token. Failure to send the token directly.                                                                                    |
| Damn Vulnerable DeFi: 2. Naivereceiver | The `flashLoan` function can specify a `borrower`, but the receiver side does not authenticate the TX sender, so the receiver's funds can be drained as a fee |
| Damn Vulnerable DeFi: 3. Truster       | The target of a call is made into the token and the token can be taken by approving it to oneself                                                             |
| Damn Vulnerable DeFi: 4. Sideentrance  | Flash loan that allows each user to make a deposit and a withdrawal. The deposit can be executed at no cost at the time of the flash loan.                    |

### Governance attacks by executing flash loans during snapshots
- If the algorithm distributes some kind of rights using the token balance at the time of a snapshot, and if a malicious user transaction can trigger a snapshot, a flash loan can be used to obtain massive rights.
- A period of time to lock the token will avoid this attack.

| Challenge                            | Note, Keywords                                                       |
| ------------------------------------ | -------------------------------------------------------------------- |
| Damn Vulnerable DeFi: 5. Therewarder | Get reward tokens based on the deposited token balance.              |
| Damn Vulnerable DeFi: 6. Selfie      | Get voting power in governance based on the deposited token balance. |

### Bypassing repayments of push architecture flash loans
- There are two architectures of flash loans: push and pull, with push architectures represented by Uniswap and Aave v1 and pull architectures by Aave v2 and dYdX.
- The proposed flash loan in [EIP-3156: Flash Loans](https://eips.ethereum.org/EIPS/eip-3156) is a pull architecture.

| Challenge                  | Note, Keywords                                                  |
| -------------------------- | --------------------------------------------------------------- |
| Paradigm CTF 2021: Upgrade | Bypass using the lending functionality implemented in the token |

### Bugs in AMM price calculation algorithm
- A bug in the Automated Market Maker (AMM) price calculation algorithm allows a simple combination of trades to drain funds.

| Challenge                            | Note, Keywords |
| ------------------------------------ | -------------- |
| [Ethernaut: 22. Dex](src/Ethernaut/) |                |

### Attacks using custom tokens
- The ability of a protocol to use arbitrary tokens is not in itself a bad thing, but it can be an attack vector.
- In addition, bugs in the whitelist design, which assumes that arbitrary tokens are not available, could cause funds to drain.

| Challenge                                | Note, Keywords |
| ---------------------------------------- | -------------- |
| [Ethernaut: 23. Dex Two](src/Ethernaut/) |                |

### Oracle manipulation attacks without flash loans
- It corrupts the value of the oracle and drains the funds of applications that refer to that oracle.

| Challenge                            | Note, Keywords                                                                                  |
| ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| Paradigm CTF 2021: Broker            | Distort Uniswap prices and liquidate positions on lending platforms that reference those prices |
| Damn Vulnerable DeFi: 7. Compromised | Off-chain private key leak & oracle manipulation                                                |

### Oracle manipulation attacks with flash loans
- The use of flash loans distorts the value of the oracle and drains the funds of the protocols that reference that oracle.
- The ability to move large amounts of funds through a flash loan makes it easy to distort the oracle and cause more damage.

| Challenge                                                                                    | Note, Keywords                                                                                     |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Damn Vulnerable DeFi: 8. Puppet                                                              | Distort the price of Uniswap V1 and leak tokens from a lending platform that references that price |
| [DeFi-Security-Summit-Stanford: BorrowSystemInsecureOracle](src/DeFiSecuritySummitStanford/) | lending protocol                                                                                   |

### Sandwich attacks
- For example, if there is a transaction by another party to sell token `A` and buy `B`, the attacker can put in a transaction to sell `A` and buy `B` before the transaction, and later put in a transaction to sell the same amount of `B` and buy `A`, thereby ultimately increasing the amount of `A` at a profit.
- In general, such "revenue earned by selecting, inserting, and reordering transactions contained in a block generated by a miner" is referred to as Miner Extractable Value (MEV). Recently, it is also called Maximal Extractable Value.

| Challenge                                         | Note, Keywords                              |
| ------------------------------------------------- | ------------------------------------------- |
| [Paradigm CTF 2021: Farmer](src/ParadigmCTF2021/) | Sandwich the trade from COMP to WETH to DAI |

### Recoveries of private keys by same-nonce attacks
- In general, a same-nonce attack is possible when the same nonce is used for different messages in the elliptic curve DSA (ECDSA), and the secret key can be calculated.
- In Ethereum, if nonces used to sign transactions are the same, this attack is feasible.

| Challenge                                                   | Note, Keywords |
| ----------------------------------------------------------- | -------------- |
| [Capture The Ether: Account Takeover](src/CaptureTheEther/) |                |
| [Paradigm CTF 2021: Babycrypto](src/ParadigmCTF2021)        |                |
| [MetaTrust CTF: ECDSA](src/MetaTrustCTF/ECDSA/)             |                |

### ECDSA signature malleability attacks
- ECDSA signatures have a property called malleability, where for a given message and signature `(v, r, s)`, there exists another valid signature `(v', r, -s mod n)` for the same message.
- This can be exploited in systems that track used signatures, as the alternative signature may not be recognized as already used.
- In Ethereum's secp256k1 curve, this property can be used to bypass signature verification mechanisms.

| Challenge                                                  | Note, Keywords                           |
| ---------------------------------------------------------- | ---------------------------------------- |
| [SmileyCTF: MultisigWallet](src/SmileyCTF/MultisigWallet/) | ECDSA, signature malleability, secp256k1 |

### Brute-forcing addresses
- Brute force can make a part of an address a specific value.

| Challenge                                                 | Note, Keywords   |
| --------------------------------------------------------- | ---------------- |
| [Capture The Ether: Fuzzy identity](src/CaptureTheEther/) | 28 bits, CREATE2 |
| [Numen Cyber CTF 2023: Exist](src/NumenCTF/)              | 16 bits          |

### Recoveries of public keys
- The address is the public key applied to a `keccak256` hash, and the public key cannot be recovered from the address.
- If even one transaction has been sent, the public key can be back-calculated from it.
- Specifically, it can be recovered from the Recursive Length Prefix (RLP)-encoded data `[nonce, gas_price, gas, to, value, data, chain_id, 0, 0]` and the signature `(v,r,s)`.

| Challenge                                             | Note, Keywords |
| ----------------------------------------------------- | -------------- |
| [Capture The Ether: Public Key](src/CaptureTheEther/) | RLP, ECDSA     |

### Encryption and decryption in secp256k1

| Challenge                                       | Note, Keywords  |
| ----------------------------------------------- | --------------- |
| [0x41414141 CTF: Rich Club](src/0x41414141CTF/) | DEX, flash loan |

### Bypassing bots and taking ERC-20 tokens owned by wallets with known private keys
- If a wallet with a known private key has an ERC-20 token but no Ether, it is usually necessary to first send Ether to the wallet and then `transfer` the ERC-20 token to get the ERC-20 token.
- However, if a bot that immediately takes the Ether sent at this time is running, the Ether will be stolen when the Ether is simply sent.
- In this situation, we can use [Flashbots](https://docs.flashbots.net/) bundled transactions or just `permit` and `transferFrom` if the token is [EIP-2612 permit](https://eips.ethereum.org/EIPS/eip-2612) friendly.

| Challenge                                                                 | Note, Keywords |
| ------------------------------------------------------------------------- | -------------- |
| [EthernautDAO: 5. EthernautDaoToken](src/EthernautDAO/EthernautDaoToken/) |                |

### Claimable intermediate nodes of Merkle trees

| Challenge                                             | Note, Keywords |
| ----------------------------------------------------- | -------------- |
| [Paradigm CTF 2022: MERKLEDROP](src/ParadigmCTF2022/) |                |

### Precompiled contracts

| Challenge                                         | Note, Keywords |
| ------------------------------------------------- | -------------- |
| [Paradigm CTF 2022: VANITY](src/ParadigmCTF2022/) |                |

### Faking errors

| Challenge                                       | Note, Keywords |
| ----------------------------------------------- | -------------- |
| [Ethernaut: 27. Good Samaritan](src/Ethernaut/) |                |

### Foundry cheatcodes

| Challenge                                            | Note, Keywords |
| ---------------------------------------------------- | -------------- |
| [Paradigm CTF 2022: TRAPDOOOR](src/ParadigmCTF2022/) |                |
| Paradigm CTF 2022: TRAPDOOOOR                        |                |

### Front-running

| Challenge                                               | Note, Keywords |
| ------------------------------------------------------- | -------------- |
| [DownUnderCTF 2022: Private Log](src/DownUnderCTF2022/) |                |
| [DiceCTF 2024: Floordrop](src/DiceCTF2024/)             | Geth           |

### Back-running
- MEV-Share can be used to create bundled transactions to back-run.

| Challenge                                                           | Note, Keywords |
| ------------------------------------------------------------------- | -------------- |
| [MEV-Share CTF: MevShareCTFSimple 1](src/MEVShareCTF/)              |                |
| [MEV-Share CTF: MevShareCTFSimple 2](src/MEVShareCTF/)              |                |
| [MEV-Share CTF: MevShareCTFSimple 3](src/MEVShareCTF/)              |                |
| [MEV-Share CTF: MevShareCTFSimple 4](src/MEVShareCTF/)              |                |
| [MEV-Share CTF: MevShareCTFMagicNumberV1](src/MEVShareCTF/)         |                |
| [MEV-Share CTF: MevShareCTFMagicNumberV2](src/MEVShareCTF/)         |                |
| [MEV-Share CTF: MevShareCTFMagicNumberV3](src/MEVShareCTF/)         |                |
| [MEV-Share CTF: MevShareCTFNewContract (Address)](src/MEVShareCTF/) |                |
| [MEV-Share CTF: MevShareCTFNewContract (Salt)](src/MEVShareCTF/)    | CREATE2        |

### Head overflow bugs in calldata tuple ABI-reencoding (< Solidity 0.8.16)
- See: https://blog.soliditylang.org/2022/08/08/calldata-tuple-reencoding-head-overflow-bug/

| Challenge                                                 | Note, Keywords             |
| --------------------------------------------------------- | -------------------------- |
| [0CTF 2022: TCTF NFT Market](src/0CTF2022/TctfNftMarket/) |                            |
| [Numen Cyber CTF 2023: Wallet](src/NumenCTF/)             | illegal `v` in `ecrecover` |

### Overwriting storage slots via local storage variables (< Solidity 0.8.1)
- In `Foo storage foo;`, the local variable `foo` points to slot 0.

| Challenge                                           | Note, Keywords |
| --------------------------------------------------- | -------------- |
| [Capture The Ether: Donation](src/CaptureTheEther/) |                |

### Overwriting arbitrary storage slots by setting array lengths to `2^256-1` (< Solidity 0.6.0)
- For example, any storage variable can be overwritten by negatively arithmetic overflowing the length of an array to `2^256-1`.
- It need not be due to overflow.
- The `length` property has been read-only since v0.6.0.

| Challenge                                          | Note, Keywords |
| -------------------------------------------------- | -------------- |
| [Capture The Ether: Mapping](src/CaptureTheEther/) |                |
| [Ethernaut: 19. Alien Codex](src/Ethernaut/)       |                |
| Paradigm CTF 2021: Bank                            |                |

### Constructors that is just functions by typos (< Solidity 0.5.0)
- In versions before v0.4.22, the constructor is defined as a function with the same name as the contract, so a typo of the constructor name could cause it to become just a function, resulting in a bug.
- Since v0.5.0, this specification is removed and the `constructor` keyword must be used.

| Challenge                                                   | Note, Keywords |
| ----------------------------------------------------------- | -------------- |
| [Capture The Ether: Assume ownership](src/CaptureTheEther/) |                |
| [Ethernaut: 2. Fallout](src/Ethernaut/)                     |                |

### Overwriting storage slots via uninitialized storage pointer (< Solidity 0.5.0)
- Since v0.5.0, uninitialized storage variables are forbidden, so this bug cannot occur.

| Challenge                                              | Note, Keywords                                                                      |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| [Capture The Ether: Fifty years](src/CaptureTheEther/) |                                                                                     |
| ~~Ethernaut: Locked~~                                  | [deleted](https://forum.openzeppelin.com/t/ethernaut-locked-with-solidity-0-5/1115) |

### Other ad-hoc vulnerabilities and methods

| Challenge                                                         | Note, Keywords                                                                                                                    |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [Paradigm CTF 2021: Bouncer](src/ParadigmCTF2021/Bouncer/)        | The funds required for batch processing are the same as for single processing.                                                    |
| Paradigm CTF 2021: Market                                         | Make the value of one field be recognized as the value of another field by using key misalignment in the Eternal Storage pattern. |
| [EthernautDAO: 2. WalletLibrary](src/EthernautDAO/WalletLibrary/) | m and n of m-of-n multisig wallet can be changed.                                                                                 |
| [Paradigm CTF 2022: RESCUE](src/ParadigmCTF2022/)                 |                                                                                                                                   |
| Paradigm CTF 2022: JUST-IN-TIME                                   |                                                                                                                                   |
| Paradigm CTF 2022: 0XMONACO                                       |                                                                                                                                   |
| [BalsnCTF 2022: NFT Marketplace](src/BalsnCTF2022/)               | initialize, `_safeTransferFrom`, `CREATE2`                                                                                        |
| [Numen Cyber CTF 2023: LenderPool](src/NumenCTF/)                 | flash loan                                                                                                                        |
| [Numen Cyber CTF 2023: GOATFinance](src/NumenCTF/)                | check sum address                                                                                                                 |
| [SEETF 2023: Pigeon Vault](src/SEETF2023/)                        | EIP-2535: Diamonds, Multi-Facet Proxy                                                                                             |
| [corCTF 2023: baby-wallet](src/CorCTF2023/)                       | missing `from != to` check                                                                                                        |

## Bitcoin
Note
- This section includes challenges of Bitcoin variants whose transaction model is Unspent Transaction Output (UTXO).

### Bitcoin basics

| Challenge                              | Note, Keywords              |
| -------------------------------------- | --------------------------- |
| TsukuCTF 2021: genesis                 | genesis block               |
| WORMCON 0x01: What's My Wallet Address | Bitcoin address, RIPEMD-160 |

### Recoveries of private keys by same-nonce attacks
- There was a bug and it has been fixed using [RFC6979](https://datatracker.ietf.org/doc/html/rfc6979).
- https://github.com/daedalus/bitcoin-recover-privkey

| Challenge                                 | Note, Keywords |
| ----------------------------------------- | -------------- |
| [darkCTF: Duplicacy Within](src/DarkCTF/) |                |

### Bypassing PoW of other applications using Bitcoin's PoW database
- Bitcoin uses a series of leading zeros in the SHA-256 hash value as a Proof of Work (PoW), but if other applications are designed in the same way, its PoW time can be significantly reduced by choosing one that matches the conditions from Bitcoin's past PoW results 

| Challenge                   | Note, Keywords |
| --------------------------- | -------------- |
| Dragon CTF 2020: Bit Flip 2 | 64-bit PoW     |

## Solana

| Challenge                                             | Note, Keywords       |
| ----------------------------------------------------- | -------------------- |
| ALLES! CTF 2021: Secret Store                         | `solana`,`spl-token` |
| ALLES! CTF 2021: Legit Bank                           |                      |
| ALLES! CTF 2021: Bugchain                             |                      |
| ALLES! CTF 2021: eBPF                                 | reversing eBPF       |
| [Paradigm CTF 2022: OTTERWORLD](src/ParadigmCTF2022/) |                      |
| [Paradigm CTF 2022: OTTERSWAP](src/ParadigmCTF2022/)  |                      |
| Paradigm CTF 2022: POOL                               |                      |
| Paradigm CTF 2022: SOLHANA-1                          |                      |
| Paradigm CTF 2022: SOLHANA-2                          |                      |
| Paradigm CTF 2022: SOLHANA-3                          |                      |
| corCTF 2023: tribunal                                 |                      |
| Project SEKAI CTF 2023: The Bidding                   |                      |
| Project SEKAI CTF 2023: Play for Free                 |                      |

## Cosmos

### CosmWasm

| Challenge                                                                             | Note, Keywords                |
| ------------------------------------------------------------------------------------- | ----------------------------- |
| [Oak Security CosmWasm CTF: 1. Mjolnir](src/OakSecurityCosmWasmCTF/01-Mjolnir/)       | logic bug                     |
| [Oak Security CosmWasm CTF: 2. Gungnir](src/OakSecurityCosmWasmCTF/02-Gungnir/)       | integer overflow              |
| [Oak Security CosmWasm CTF: 3. Laevateinn](src/OakSecurityCosmWasmCTF/03-Laevateinn/) | address validation, uppercase |
| [Oak Security CosmWasm CTF: 4. Gram](src/OakSecurityCosmWasmCTF/04-Gram/)             | invariant, rounding error     |
| [Oak Security CosmWasm CTF: 5. Draupnir](src/OakSecurityCosmWasmCTF/05-Draupnir/)     | missing return                |
| [Oak Security CosmWasm CTF: 6. Hofund](src/OakSecurityCosmWasmCTF/06-Hofund/)         | flash loan, governance        |
| [Oak Security CosmWasm CTF: 7. Tyrfing](src/OakSecurityCosmWasmCTF/07-Tyrfing/)       | storage collision             |
| Oak Security CosmWasm CTF: 8. Gjallarhorn                                             |                               |
| Oak Security CosmWasm CTF: 9. Brisingamen                                             |                               |
| Oak Security CosmWasm CTF: 10. Mistilteinn                                            |                               |

### Application-specific blockchain

| Challenge                           | Note, Keywords |
| ----------------------------------- | -------------- |
| RealWorld CTF 3rd Finals: Billboard |                |

## Move

| Challenge                                                                         | Note, Keywords                           |
| --------------------------------------------------------------------------------- | ---------------------------------------- |
| [Numen Cyber CTF 2023: Move to Checkin](src/NumenCTF/)                            | contract call in Sui                     |
| [Numen Cyber CTF 2023: ChatGPT tell me where is the vulnerability](src/NumenCTF/) | OSINT                                    |
| [Numen Cyber CTF 2023: Move to Crackme](src/NumenCTF/)                            | reversing Move code and Linux executable |
| justCTF 2024 teaser: The Otter Scrolls                                            |                                          |
| justCTF 2024 teaser: Dark BrOTTERhood                                             |                                          |
| justCTF 2024 teaser: World of Ottercraft                                          |                                          |

## Cairo

| Challenge                                                       | Note, Keywords   |
| --------------------------------------------------------------- | ---------------- |
| [Paradigm CTF 2022: RIDDLE-OF-THE-SPHINX](src/ParadigmCTF2022/) | contract call    |
| [Paradigm CTF 2022: CAIRO-PROXY](src/ParadigmCTF2022/)          | integer overflow |
| [Paradigm CTF 2022: CAIRO-AUCTION](src/ParadigmCTF2022/)        | `Uint256`        |
| [BalsnCTF 2022: Cairo Reverse](src/BalsnCTF2022/)               | reversing        |

## Other Blockchain-Related
- Things that are not directly related to blockchains but are part of the ecosystems.

| Challenge                              | Note, Keywords                    |
| -------------------------------------- | --------------------------------- |
| TsukuCTF 2021: InterPlanetary Protocol | IPFS address, Base32 in lowercase |
