# Paradigm CTF 2023 - Cosmic Radiation - From Zero to 45,046,618 ETH

On this page, I will explain a solution to the "Cosmic Radiation" challenge from Paradigm CTF 2023.

Our team, KALOS++, achieved a score of 44,901,978 during the CTF for this challenge.
However, there were some ideas for algorithms that we could not fully implement within the time constraints.
**After the CTF ended, when I implemented those algorithms, our score eventually increased to 45,046,618.**
This score was more than about 100,000 ETH higher than the highest score of all teams during the CTF.

In this writeup, I will describe the algorithms I got the score.

**Table of Contents**
- [Challenge Overview](#challenge-overview)
- [Solution](#solution)
  - [\[-\> 31,659,312\] Attacking the Contract with the Highest Balance](#--31659312-attacking-the-contract-with-the-highest-balance)
  - [\[-\> 44,956,845\] Using the Contract List of Top Balances from Google BigQuery](#--44956845-using-the-contract-list-of-top-balances-from-google-bigquery)
  - [\[-\> 44,971,334\] Optimizing based on On-Chain Simulation](#--44971334-optimizing-based-on-on-chain-simulation)
  - [\[-\> 44,973,046\] Optimizing with Overwrite Target: `ORIGIN SELFDESTRUCT` or `CALLER SELFDESTRUCT`](#--44973046-optimizing-with-overwrite-target-origin-selfdestruct-or-caller-selfdestruct)
  - [\[-\> 44,975,043\] Optimizing with Calldata: `0x` or `0x11223344`](#--44975043-optimizing-with-calldata-0x-or-0x11223344)
  - [\[-\> 44,992,197\] Detecting Proxy Contracts and Modifying Implementation Contracts](#--44992197-detecting-proxy-contracts-and-modifying-implementation-contracts)
  - [\[-\> 45,046,618\] Performing Replay Attacks](#--45046618-performing-replay-attacks)

## Challenge Overview

"Cosmic Radiation" is a King-of-the-Hill style challenge, where players compete to maximize the amount of ETH they can get under given constraints.
The primary constraints are as follows:
- Players can modify any number of bits within the bytecode of any address with a positive balance.
- The more bits a player modifies, the lower the value the address's balance will be overwritten with.

However, despite being able to modify the bytecode of any number of addresses, due to infrastructure and time limitations during the CTF, we could only modify up to approximately 10,000 contracts.
**Thus, on this page, I will approach this challenge under the constraint of "being able to modify a maximum of 10,000 contracts."**

In more detail, the instruction to modify the bytecode is named `bitflip` and follows the below format.

```
address:bit1:bit2:bit3:...:bitN
```

This is parsed into `addr` and `bits` as follows by the challenge server:

```python
(addr, *bits) = bitflip.split(":")
addr = Web3.to_checksum_address(addr)
bits = [int(v) for v in bits]
```

Following that, the bytecode is modified according to bits as below:

```python
code = bytearray(web3.eth.get_code(addr))
for bit in bits:
    byte_offset = bit // 8
    bit_offset = 7 - bit % 8
    if byte_offset < len(code):
        code[byte_offset] ^= 1 << bit_offset
```

Based on the length of `bits`, the balance of the address is modified as follows:

```python
total_bits = len(code) * 8
corrupted_balance = int(balance * (total_bits - len(bits)) / total_bits)
```

## Solution

### [-> 31,659,312] Attacking the Contract with the Highest Balance

First, we will try to acquire the ETH held by the contract address with the highest balance.

As confirmed on Etherscan's "[Ethereum Top Accounts by ETH Balance](https://etherscan.io/accounts/1?ps=100)", the contract with the highest balance is the Beacon Deposit Contract at [0x00000000219ab540356cBB839Cbe05303d7705Fa](https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa).

The block number that the challenge server forks from is 18437825, and at that block, this contract holds 31,664,538 ETH.

```
$ cast balance 0x00000000219ab540356cBB839Cbe05303d7705Fa -e --block 18437825
31664538.264999839958004578
```

While there are various ways to think about how to modify the bytecode and obtain the balance, first, we will overwrite the beginning of the bytecode with the simple and versatile `ORIGIN SELFDESTRUCT`.

The start of this contract's bytecode is `6080`.
So, for instance, if we send a bitflip like the following, we can change it to `ORIGIN SELFDESTRUCT` (`32FF`).

```
0x00000000219ab540356cBB839Cbe05303d7705Fa:6:3:1:15:14:13:12:11:10:9
```

Then, by simply calling this contract address, we can obtain the balance.

Additionally, since the given player account starts with an initial 1000 ETH, sending this to the challenge contract, in the end, will slightly boost a score (as the balance of the challenge contract becomes our score).

As a result, the score becomes 31,659,312.

### [-> 44,956,845] Using the Contract List of Top Balances from Google BigQuery

Now, let's apply the above method to the top 10,000 contract addresses by balance.

A list of 10,000 contract addresses can be obtained using Google BigQuery.
For example, we can use the following query:

```sql
SELECT contracts.address, balances.eth_balance
FROM `bigquery-public-data.crypto_ethereum.contracts` AS contracts
JOIN `bigquery-public-data.crypto_ethereum.balances` AS balances
ON balances.address = contracts.address
ORDER BY balances.eth_balance DESC
LIMIT 10000
```

However, since Google BigQuery updates in real-time, this query will not provide data as of block 18437825 that the challenge server forks.
Thus, it is recommended to obtain not just 10,000 but rather 20,000 addresses and use Web3.py or similar to retrieve the balance and contract code for that block to create a precise list.

In addition to that, obtain a list of contract addresses that sent more than 10 Ether using the following query.
This ensures we capture contract addresses that might currently be outside the top 20,000 list.

```sql
SELECT DISTINCT traces.from_address
FROM `bigquery-public-data.crypto_ethereum.traces` AS traces
WHERE traces.value > cast('1E19' as NUMERIC) AND traces.block_number >= 18437825 AND traces.block_number <= 18451700
LIMIT 100000
```

From the above, we will end up with a list like [this](data/contract-list.csv).

For each of these contract addresses, calculate the score when applying `ORIGIN SELFDESTRUCT`.
Then, If we attack the top 10,000 addresses based on the calculated scores, we will obtain a score of 44,956,845.

With just these steps, we will surpass the maximum score of 44,947,584 during the CTF.
It means we could have clinched the first place by submitting this simple solution.

### [-> 44,971,334] Optimizing based on On-Chain Simulation

Currently, our strategy is overwriting the beginning of the bytecode.
However, it is not mandatory to overwrite the start, so we can also overwrite a position somewhere in the middle.

For instance, the bytecode for the Beacon Deposit Contract starts with `60806040`, which disassembled looks like this:

```
PUSH1 80
PUSH1 40
```

While we previously altered `PUSH1 80`, there is no problem in overwriting `PUSH1 40`.
Modifying the location that yields the highest score would enable us to achieve even better results.

To determine this optimal location, on-chain simulations are useful.
Various methods are available for on-chain simulations, but for this instance, I utilized a custom reversing tool I developed named [erever](https://github.com/minaminao/erever).
(Note: This tool is optimized for my usage, so it is not strongly recommended for others to use.)

For the Beacon Deposit Contract, we initially flipped 10 bits for the `PUSH1 80` with `6:3:1:15:14:13:12:11:10:9`.
However, using on-chain simulation, for the strategy of simply overwriting with `ORIGIN SELFDESTRUCT` and then calling, it is found most efficient to modify the following positions:

```
0x0042: (0x80) DUP1
0x0043: (0xfd) REVERT
```

The bitflip becomes `0x00000000219ab540356cBB839Cbe05303d7705Fa:534:531:530:528:542`, requiring edits to just 5 bits.

Noted that this on-chain simulation simplifies several processes.
For example, it stops when it encounters the opcode: `STOP`,`RETURN`,`REVERT`,`INVALID`,`SELFDESTRUCT`, and also for `DELEGATECALL`,`STATICCALL`,`CALLCODE`,`CALL`,`CREATE`,`CREATE2`.
Moreover, since editing a `JUMPDEST` would make it non-jumpable and broken, we avoid modifying `JUMPDEST`.
Furthermore, the trace is stopped after executing 500 instructions.

Applying the above methods to all contracts results in a score of 44,971,334.

### [-> 44,973,046] Optimizing with Overwrite Target: `ORIGIN SELFDESTRUCT` or `CALLER SELFDESTRUCT`

Now, instead of `ORIGIN SELFDESTRUCT`, executing `CALLER SELFDESTRUCT` is also available.
In that case, it would be better to adopt whichever of the two yields a higher score.

By optimally choosing between these two options, the score marginally increases to 44,973,046.

### [-> 44,975,043] Optimizing with Calldata: `0x` or `0x11223344`

Many contracts initially determine whether or not a jump will be executed based on the `JUMPI` instruction resulting from `CALLDATASIZE`.
This is because they check for the function selector.
For instance, the Beacon Deposit Contract looks like this:

```
0x0000: (0x60) PUSH1 0x80
0x0002: (0x60) PUSH1 0x40
0x0004: (0x52) MSTORE
0x0005: (0x60) PUSH1 0x04
0x0007: (0x36) CALLDATASIZE
0x0008: (0x10) LT
0x0009: (0x61) PUSH2 0x003f
0x000c: (0x57) JUMPI
```

Currently, we send no calldata.
However, if we consider cases where an arbitrary 4-byte calldata is sent, the range of our search to find the optimal solution expands.

Thus, we perform simulations for both patterns: one without calldata and one with a 4-byte calldata.
Then, we adopt the pattern that gives the highest score.

With this simple tweak, the score reaches 44,975,043.

### [-> 44,992,197] Detecting Proxy Contracts and Modifying Implementation Contracts

Among the top contracts, many are proxy contracts.
If the balance of an implementation contract is positive, modifying the bytecode of the implementation contract allows obtaining the theoretical score without modifying the balance of the proxy contract.

Thus, in on-chain simulation, when a `DELEGATECALL` or `CALLCODE` execution is detected, we opt to modify the implementation contract.
The address of the implementation contract can be identified by examining the stack before executing `DELEGATECALL` or `CALLCODE`.

For instance, [0xC61b9BB3A7a0767E3179713f3A5c7a9aeDCE193C](https://etherscan.io/address/0xc61b9bb3a7a0767e3179713f3a5c7a9aedce193c) has a `DELEGATECALL` instruction at position `0x5e`.

```
...
0x5c: DUP5
0x5d: GAS
0x5e: DELEGATECALL
0x5f: RETURNDATASIZE
0x60: PUSH1 0x00
...
```

From the on-chain simulation, we can observe that the content of the stack just before this `DELEGATECALL` instruction is as follows:

```
[0x017e19, 0x34cfac646f301356faa8b21e94227e3583fe3f5f, 0x00, 0x00, 0x00, 0x00, 0x34cfac646f301356faa8b21e94227e3583fe3f5f]
```

In this case, `0x34cfac646f301356faa8b21e94227e3583fe3f5f` is the address of the implementation contract.

Moreover, many proxy contracts share the same implementation contracts.
Thus, the number of bitflips required to capture the balance of the top 10,000 contracts, originally set at 10,000, significantly reduces.
Since we have set a constraint to only send 10,000 bitflips, by considering proxy contracts, we can target a broader range of contracts.

With this optimization, the score reaches 44,992,197.

### [-> 45,046,618] Performing Replay Attacks

Lastly, by replaying transactions on the mainnet after block `18437825` on the challenge server's forked network, we can acquire more Ether.

Among the transactions up to block `18451700`, which is about an hour and a half before the end of the CTF, we list the transactions that are sending more than 100 ETH to contracts.
We get this list by running the following query on Google BigQuery:

```sql
SELECT transactions.hash, transactions.from_address, transactions.to_address, transactions.value, transactions.nonce
FROM `bigquery-public-data.crypto_ethereum.transactions` AS transactions
JOIN `bigquery-public-data.crypto_ethereum.contracts` AS contracts
ON transactions.to_address = contracts.address
WHERE transactions.value > cast('1E20' as NUMERIC) AND transactions.block_number >= 18437825 AND transactions.block_number <= 18451700 AND transactions.receipt_status = 1
ORDER BY transactions.block_number, transactions.nonce
LIMIT 1000
```

One important thing when performing replay attacks is the need to consider the nonces.
If the nonce of the target transaction is larger than the nonce at the time of block `18437825`, we will also need to replay transactions with previous nonces.

To obtain a list of transactions sent by a specific address, we can use the Etherscan API.
Details of the endpoint can be found in "[Get a list of 'Normal' Transactions By Address](https://docs.etherscan.io/api-endpoints/accounts#get-a-list-of-normal-transactions-by-address)".

Under the constraint of being able to send a maximum of 5 intermediary transactions, we found over a dozen transactions where the replay attack was effective.
We can calculate the score after replaying these transactions and select the optimal 10,000 bitflips.

By employing this strategy, **the final score amounted to 45,046,618!**
The source code can be found in [solve.py](solve.py).
