# MEV-Share CTF Writeup

**Table of Contents**
- [What is MEV-Share CTF?](#what-is-mev-share-ctf)
- [Common Info for All Challenges](#common-info-for-all-challenges)
- [Challenge 1: MevShareCTFSimple 1](#challenge-1-mevsharectfsimple-1)
- [Challenge 2: MevShareCTFSimple 2](#challenge-2-mevsharectfsimple-2)
- [Challenge 3: MevShareCTFSimple 3](#challenge-3-mevsharectfsimple-3)
- [Challenge 4: MevShareCTFSimple 4](#challenge-4-mevsharectfsimple-4)
- [Challenge 5: MevShareCTFMagicNumberV1](#challenge-5-mevsharectfmagicnumberv1)
- [Challenge 6: MevShareCTFMagicNumberV2](#challenge-6-mevsharectfmagicnumberv2)
- [Challenge 7: MevShareCTFMagicNumberV3](#challenge-7-mevsharectfmagicnumberv3)
- [Challenge 8: MevShareCTFNewContract (address)](#challenge-8-mevsharectfnewcontract-address)
- [Challenge 9: MevShareCTFNewContract (salt)](#challenge-9-mevsharectfnewcontract-salt)
- [Challenge 10: MevShareCTFTriple](#challenge-10-mevsharectftriple)

## What is MEV-Share CTF?

The [MEV-Share CTF](https://collective.flashbots.net/t/capture-the-flag/2100) was a CTF organized by [Flashbots](https://www.flashbots.net/) that ran for 48 hours from August 5 to August 7, 2023.
As the name MEV-Share CTF implies, to solve the challenges, getting the transactions distributed from the [MEV-Share](https://docs.flashbots.net/flashbots-mev-share/overview) event stream and backrunning using the MEV-Share infrastructure were required.
I had never seen this type of CTF before, and it was very interesting. 
The challenges were easy for me, and I finished solving all of them in about 3 hours, but they were all new and educational.

There were 10 challenges in this CTF.
All challenges were deployed on the Goerli testnet.
Basically, blockchain CTF challenges would be less interesting if they did not use a private chain for each participant, as the solution transactions could be copied, but this is not the case when using MEV infrastructure, as in the MEV-Share CTF.

## Common Info for All Challenges

All challenge contracts are managed by the following `MevShareCaptureLogger` contract.

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

//          ________           __    __          __
//         / ____/ /___ ______/ /_  / /_  ____  / /______
//        / /_  / / __ `/ ___/ __ \/ __ \/ __ \/ __/ ___/
//       / __/ / / /_/ (__  ) / / / /_/ / /_/ / /_(__  )
//      /_/   /_/\__,_/____/_/ /_/_.___/\____/\__/____/

// Join the MEV-Share CTF at https://ctf.flashbots.net
// The goal of this challenge is to emit `Capture()` events with your own address (from tx.origin)
// These challenges require backrunning private transactions using MEV-Share

// Learn about MEV-Share at https://docs.flashbots.net/flashbots-mev-share/overview
// Join the Flashbots Discord and learn about Flashbots at https://flashbots.net/

contract MevShareCaptureLogger is Ownable {
    mapping(address => bool) public ctfContracts;
    mapping(address => mapping(uint256 => bool)) public winnerCaptures;
    mapping(address => uint256) public totalPoints;

    event Capture(uint256 points, address winner, uint256 captureId);
    event CaptureContract(address captureContract, bool isCaptureContract);

    modifier onlyCtfContracts() {
        require(ctfContracts[msg.sender]);
        _;
    }

    function setCaptureContract(address captureContract, bool isCaptureContract) public payable onlyOwner {
        ctfContracts[captureContract] = isCaptureContract;
        emit CaptureContract(captureContract, isCaptureContract);
    }

    function setCaptureContracts(address[] calldata captureContracts, bool isCaptureContract) external payable onlyOwner {
        for (uint256 i = 0; i < captureContracts.length; i++) {
            setCaptureContract(captureContracts[i], isCaptureContract);
        }
    }

    function call(address destination, uint256 value, bytes memory data) external onlyOwner returns (bool) {
        (bool success,) = destination.call{value: value}(data);
        return success;
    }

    function registerCapture(uint256 captureId, address winner) external payable onlyCtfContracts {
        require(winnerCaptures[winner][captureId] == false);
        winnerCaptures[winner][captureId] = true;
        uint256 points = captureId / 100;
        totalPoints[winner] += points;
        emit Capture(points, winner, captureId);
    }
}
```

When a player successfully backruns, the `registerCapture` function is called from the challenge contract and they can earned points.

Transactions that should backrun are distributed in the following SSE endpoint: https://mev-share-goerli.flashbots.net/

All challenge contracts are deployed in the following single transaction, and the address of each challenge contract is in the transaction log: https://goerli.etherscan.io/tx/0x20ad7a3656f0bf39d977400cf9dec21e8da1b238d48f2c1c850559a5948b5780#eventlog

## Challenge 1: MevShareCTFSimple 1

Challenge contract address: https://goerli.etherscan.io/address/0x98997b55Bb271e254BEC8B85763480719DaB0E53

The source code is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTF.sol";

contract MevShareCTFSimple is MevShareCTFBase {
    uint256 public activeBlock;

    uint256 immutable captureId;

    event Activate();

    constructor(MevShareCaptureLogger _mevShareCaptureLogger, uint256 _captureId) MevShareCTFBase(_mevShareCaptureLogger) payable {
        captureId = _captureId;
    }

    function activateRewardSimple() external payable onlyOwner {
        activeBlock = block.number;
        emit Activate();
    }

    function claimReward() external {
        require (activeBlock == block.number);
        activeBlock = 0;
        mevShareCaptureLogger.registerCapture(captureId, tx.origin);
    }
}
```

The goal of this challenge is to call the `claimReward` function that has the condition `activeBlock == block.number`.

To satisfy the condition, we have to call the `claimReward` function in the same block after the transaction that is called the `activateRewardSimple` function executed by the challenge owner.
In short, we have to create a bundle transaction and backrun.

We want to find a transaction by the owner for this contract address `0x98997b55bb271e254bec8b85763480719dab0e53`.
The transaction can be found in the MEV-Share event stream:

```typescript
data: {"hash":"0xfb776d6ac28856a91938f4de392caf3da77c36fe526bdbc4868e56664f3d14ca","logs":[{"address":"0x98997b55bb271e254bec8b85763480719dab0e53","topics":["0x59d3ce47d6ad6c6003cef97d136155b29d88653eb355c8bed6e03fbf694570ca"],"data":"0x"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x7530"}
```

This data include the transaction hash as well as `logs` and `topics`.

To backrun this transaction, first, we filter transactions with the following code:

```typescript
function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return (pendingTx.logs || []).some(log => log.address === TARGET_ADDRESS)
}
```

Next, construct the bundle as follows:

```ts
const mevShareBundle = {
    inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + MAX_BLOCK },
    body: [
        { hash: pendingTxHash },
        { tx: backrunSignedTx, canRevert: false }
    ]
}
```

Finally, the following code will get the flag:

```ts
import MevShareClient, { IPendingTransaction } from '@flashbots/mev-share-client'
import { Contract, JsonRpcProvider, Wallet } from 'ethers'
import { MEV_SHARE_CTF_SIMPLE_ABI } from './abi'
import dotenv from "dotenv"
dotenv.config()

const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545'
const EXECUTOR_KEY = process.env.EXECUTOR_KEY || Wallet.createRandom().privateKey
const FB_REPUTATION_PRIVATE_KEY = process.env.FB_REPUTATION_KEY || Wallet.createRandom().privateKey

const provider = new JsonRpcProvider(RPC_URL)
const executorWallet = new Wallet(EXECUTOR_KEY, provider)
const authSigner = new Wallet(FB_REPUTATION_PRIVATE_KEY, provider)
const mevShare = MevShareClient.useEthereumGoerli(authSigner)

const TARGET_ADDRESS = "0x118bcb654d9a7006437895b51b5cd4946bf6cdc2"
const targetContract = new Contract(TARGET_ADDRESS, MEV_SHARE_CTF_SIMPLE_ABI, executorWallet)

const MAX_BLOCK = 24

const TX_GAS_LIMIT = 400000
const MAX_GAS_PRICE = 40n
const MAX_PRIORITY_FEE = 30n
const GWEI = 10n ** 9n

async function main() {
    console.log("mev-share auth address: " + authSigner.address)
    console.log("executor address: " + executorWallet.address)
    const nonce = await executorWallet.getNonce("latest")

    mevShare.on('transaction', async (pendingTx: IPendingTransaction) => {
        if (!transactionIsRelatedToTarget(pendingTx)) {
            console.log('skipping tx: ' + pendingTx.hash)
            return
        }
        console.log(pendingTx)
        const currentBlockNumber = await provider.getBlockNumber()
        backrunAttempt(currentBlockNumber, nonce, pendingTx.hash)
    })
}
main()

async function getSignedBackrunTx(nonce: number) {
    const backrunTx = await targetContract.claimReward.populateTransaction()
    const backrunTxFull = {
        ...backrunTx,
        chainId: 5,
        maxFeePerGas: MAX_GAS_PRICE * GWEI,
        maxPriorityFeePerGas: MAX_PRIORITY_FEE * GWEI,
        gasLimit: TX_GAS_LIMIT,
        nonce: nonce
    }
    return executorWallet.signTransaction(backrunTxFull)
}

function bigintJsonEncoder(key: any, value: any) {
    return typeof value === 'bigint'
        ? value.toString()
        : value
}

async function backrunAttempt(currentBlockNumber: number, nonce: number, pendingTxHash: string) {
    const backrunSignedTx = await getSignedBackrunTx(nonce)
    try {
        const mevShareBundle = {
            inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + MAX_BLOCK },
            body: [
                { hash: pendingTxHash },
                { tx: backrunSignedTx, canRevert: false }
            ]
        }
        const sendBundleResult = await mevShare.sendBundle(mevShareBundle)
        console.log('Bundle Hash: ' + sendBundleResult.bundleHash)
        if (process.env.BUNDLE_SIMULATION !== undefined) {
            mevShare.simulateBundle(mevShareBundle).then(simResult => {
                console.log(`Simulation result for bundle hash: ${sendBundleResult.bundleHash}`)
                console.log(JSON.stringify(simResult, bigintJsonEncoder))
            }).catch(error => {
                console.log(`Simulation error for bundle hash: ${sendBundleResult.bundleHash}`)
                console.warn(error)
            })
        }
    } catch (e) {
        console.log('err', e)
    }
}

function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return (pendingTx.logs || []).some(log => log.address === TARGET_ADDRESS)
}

```

## Challenge 2: MevShareCTFSimple 2

Challenge contract address: https://goerli.etherscan.io/address/0x1cdDB0BA9265bb3098982238637C2872b7D12474

The source code of this contract is the same as in the previous challenge.

Similar to the previous challenge, by searching for the challenge contract address `0x1cdDB0BA9265bb3098982238637C2872b7D12474` in the event stream, we find the following transaction:

```typescript
data: {"hash":"0xbb07f1b54e52597eedb12bb4d640b6e248524d11a5d2ec94b55ca6ee08d8073a","logs":null,"txs":[{"to":"0x1cddb0ba9265bb3098982238637c2872b7d12474","functionSelector":"0xa3c356e4","callData":"0xa3c356e4"}],"mevGasPrice":"0x2faf080","gasUsed":"0x7530"}
```

In this challenge, we see that the data have the `to` address instead of an address of `logs`.

Therefore, we replace the filtering function of the solver in the previous challenge with the following one:

```ts
function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return pendingTx.to === TARGET_ADDRESS
}
```

## Challenge 3: MevShareCTFSimple 3

Challenge contract address: https://goerli.etherscan.io/address/0x65459dD36b03Af9635c06BAD1930DB660b968278

The source code of the contract is also the same as in the first challenge.

Searching the event stream by this contract address gets the following transaction data:

```typescript
data: {"hash":"0x21f58a50def7108ed648c6baf23e56b2e34597161293b7e8b9956d68bb39bd76","logs":null,"txs":[{"to":"0x65459dd36b03af9635c06bad1930db660b968278","functionSelector":"0xa3c356e4"}],"mevGasPrice":"0x2faf080","gasUsed":"0xb798"}
```

Unlike the previous challenge, there is no `callData`, but since the `to` address is given similarly to it, it can be solved by the same solver as the previous one.

## Challenge 4: MevShareCTFSimple 4

Challenge contract address: https://goerli.etherscan.io/address/0x20a1A5857fDff817aa1BD8097027a841D4969AA5

The source code of this contract is the same as in the previous challenges.

However, we try to find the contract address in the event stream, but none are found.
The same is true when we look for it in the function selector `0xa3c356e4`.

It seems that data except transaction hashes are not given by the challenge owner.

We replace the filter with the following function and solve it by sending bundle transactions for all transactions.

```ts
function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return true
}
```

## Challenge 5: MevShareCTFMagicNumberV1

Challenge contract address: https://goerli.etherscan.io/address/0x118Bcb654d9A7006437895B51b5cD4946bF6CdC2

The source code of the contract is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV1 is MevShareCTFMagicNumber {
    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFMagicNumber(_mevShareCaptureLogger) payable {
    }

    function claimReward(uint256 _magicNumber) external {
        require(claimRewardInternal(_magicNumber, 201));
    }
}
```

The code for the `MevShareCTFMagicNumber` is as follows.

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTF.sol";

contract MevShareCTFMagicNumber is MevShareCTFBase {
    uint256 public activeBlock;
    uint256 private magicNumber;

    event Activate(uint256 lowerBound, uint256 upperBound);

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFBase(_mevShareCaptureLogger) payable {
    }

    function activateRewardMagicNumber(uint256 _lowerBound, uint256 _upperBound, uint256 _magicNumber) external payable onlyOwner {
        require (_lowerBound <= _magicNumber && _upperBound >= _magicNumber);
        activeBlock = block.number;
        magicNumber = _magicNumber;
        emit Activate(_lowerBound, _upperBound);
    }

    function claimRewardInternal(uint256 _magicNumber, uint256 _captureId) internal returns (bool) {
        if (activeBlock != block.number || _magicNumber != magicNumber) {
            return false;
        }
        activeBlock = 0;
        magicNumber = 0;
        mevShareCaptureLogger.registerCapture(_captureId, tx.origin);
        return true;
    }
}
```

Searching by the contract address gets the following transaction data in the event stream:

```typescript
data: {"hash":"0xf32b23b764f806bbbec39825512e5fbe2020b21cb698c7e1089f876c16880561","logs":[{"address":"0x118bcb654d9a7006437895b51b5cd4946bf6cdc2","topics":["0x86a27c2047f889fafe51029e28e24f466422abe8a82c0c27de4683dda79a0b5d"],"data":"0x000000000000000000000000000000000000000000000000001582b5507e065a000000000000000000000000000000000000000000000000001582b5507e0682"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x8ca0"}
```

It shows that we can backrun the `activateRewardMagicNumber` function with the `claimReward` function.
However, the magic number must be guessed.

The event `emit Activate(_lowerBound, _upperBound);` is given, so `_lowerBound` and `_upperBound` for the magic number are known.
`_upperBound - _lowerBound` is:

```
>>> 0x1582b5507e0682 - 0x1582b5507e065a
40
```

Thus, we can bruteforce the magic number. We can create a contract that calls the function with all 40 values, but we can simply send 40 bundled transactions.

The solver is as follows:

```ts
import MevShareClient, { IPendingTransaction } from '@flashbots/mev-share-client'
import { Contract, JsonRpcProvider, Wallet } from 'ethers'
import { MEV_SHARE_CTF_MAGIC_NUMBER } from './abi'
import dotenv from "dotenv"
dotenv.config()

const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545'
const EXECUTOR_KEY = process.env.EXECUTOR_KEY || Wallet.createRandom().privateKey
const FB_REPUTATION_PRIVATE_KEY = process.env.FB_REPUTATION_KEY || Wallet.createRandom().privateKey

const provider = new JsonRpcProvider(RPC_URL)
const executorWallet = new Wallet(EXECUTOR_KEY, provider)
const authSigner = new Wallet(FB_REPUTATION_PRIVATE_KEY, provider)
const mevShare = MevShareClient.useEthereumGoerli(authSigner)

const TARGET_ADDRESS = "0x118bcb654d9a7006437895b51b5cd4946bf6cdc2";
const targetContract = new Contract(TARGET_ADDRESS, MEV_SHARE_CTF_MAGIC_NUMBER, executorWallet)

const MAX_BLOCK = 24

const TX_GAS_LIMIT = 400000
const MAX_GAS_PRICE = 40n
const MAX_PRIORITY_FEE = 30n
const GWEI = 10n ** 9n

async function main() {
    console.log("mev-share auth address: " + authSigner.address)
    console.log("executor address: " + executorWallet.address)
    const nonce = await executorWallet.getNonce("latest")

    mevShare.on('transaction', async (pendingTx: IPendingTransaction) => {
        if (!transactionIsRelatedToTarget(pendingTx)) {
            console.log('skipping tx: ' + pendingTx.hash);
            return
        }
        console.log(pendingTx)
        const currentBlockNumber = await provider.getBlockNumber()

        backrunAttempt(currentBlockNumber, nonce, pendingTx)
    })
}
main()

async function getSignedBackrunTx(nonce: number, magicNumber: number) {
    const backrunTx = await targetContract.claimReward.populateTransaction(magicNumber)
    const backrunTxFull = {
        ...backrunTx,
        chainId: 5,
        maxFeePerGas: MAX_GAS_PRICE * GWEI,
        maxPriorityFeePerGas: MAX_PRIORITY_FEE * GWEI,
        gasLimit: TX_GAS_LIMIT,
        nonce: nonce
    }
    return executorWallet.signTransaction(backrunTxFull)
}

function bigintJsonEncoder(key: any, value: any) {
    return typeof value === 'bigint'
        ? value.toString()
        : value
}

async function backrunAttempt(currentBlockNumber: number, nonce: number, pendingTx: IPendingTransaction) {

    const pendingTxHash = pendingTx.hash

    const logs = pendingTx.logs
    if (logs === undefined) {
        throw new Error("logs is undefined")
    }
    const args = logs[0].data.slice(2);
    if (args === undefined) {
        throw new Error("args is undefined")
    }
    const lowerBound = parseInt(args.slice(0, 64), 16)
    const upperBound = parseInt(args.slice(64, 128), 16)

    for (let magicNumber = lowerBound; magicNumber <= upperBound; magicNumber++) {
        const backrunSignedTx = await getSignedBackrunTx(nonce, magicNumber)
        try {
            const mevShareBundle = {
                inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + MAX_BLOCK },
                body: [
                    { hash: pendingTxHash },
                    { tx: backrunSignedTx, canRevert: false }
                ]
            }
            const sendBundleResult = await mevShare.sendBundle(mevShareBundle)
            console.log('Bundle Hash: ' + sendBundleResult.bundleHash)
            if (process.env.BUNDLE_SIMULATION !== undefined) {
                mevShare.simulateBundle(mevShareBundle).then(simResult => {
                    console.log(`Simulation result for bundle hash: ${sendBundleResult.bundleHash}`)
                    console.log(JSON.stringify(simResult, bigintJsonEncoder))
                }).catch(error => {
                    console.log(`Simulation error for bundle hash: ${sendBundleResult.bundleHash}`)
                    console.warn(error)
                })
            }
        } catch (e) {
            console.log('err', e)
        }
    }
}

function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return (pendingTx.logs || []).some(log => log.address === TARGET_ADDRESS)
}

```

## Challenge 6: MevShareCTFMagicNumberV2

Challenge contract address: https://goerli.etherscan.io/address/0x9BE957D1c1c1F86Ba9A2e1215e9d9EEFdE615a56

The source code of this contract is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV2 is MevShareCTFMagicNumber {
    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFMagicNumber(_mevShareCaptureLogger) payable {
    }

    function claimReward(uint256 _magicNumber) external {
        require(tx.origin == msg.sender);
        require(claimRewardInternal(_magicNumber, 202));
    }
}
```

The transaction data given in the event stream is as follows:

```typescript
data: {"hash":"0x8ffc7e266bdd75b5644a8c716a2fdedec9abad068c20c9bd1d5ab08d97d698d2","logs":[{"address":"0x9be957d1c1c1f86ba9a2e1215e9d9eefde615a56","topics":["0x86a27c2047f889fafe51029e28e24f466422abe8a82c0c27de4683dda79a0b5d"],"data":"0x000000000000000000000000000000000000000000000000000378f03dcf4928000000000000000000000000000000000000000000000000000378f03dcf4950"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x8ca0"}
```

Unlike the previous challenge, `require(tx.origin == msg.sender);` is added, but it can be solved in the same way.

## Challenge 7: MevShareCTFMagicNumberV3

Challenge contract address: https://goerli.etherscan.io/address/0xE8B7475e2790409715AF793F799f3Cc80De6f071

The source code of this contract is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTFMagicNumber.sol";

contract MevShareCTFMagicNumberV3 is MevShareCTFMagicNumber {
    // V3 only gets one shot per tx.origin. If any tx lands that is incorrect, that tx.origin does not get another shot
    mapping(address => bool) public registeredV3Attempts;

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFMagicNumber(_mevShareCaptureLogger) payable {
    }

    function claimReward(uint256 _magicNumber) external {
        require(tx.origin == msg.sender);
        require(registeredV3Attempts[tx.origin] == false);
        registeredV3Attempts[tx.origin] = true;
        claimRewardInternal(_magicNumber, 203);
    }
}
```

The transaction data given in the event stream is as follows:

```typescript
data: {"hash":"0xae91fccc59f7687f30008d30b67993e8d4d876344eafacdaa27f328b76205af2","logs":[{"address":"0xe8b7475e2790409715af793f799f3cc80de6f071","topics":["0x86a27c2047f889fafe51029e28e24f466422abe8a82c0c27de4683dda79a0b5d"],"data":"0x000000000000000000000000000000000000000000000000001471b82d1714c2000000000000000000000000000000000000000000000000001471b82d1714ea"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x8ca0"}
```

Unlike the previous two challenges, once we call the `claimReward` function, we can never do it again.
In other words, we cannot simply send 40 bundle transactions because failure is not allowed in this challenge.

What we can solve is to check if the challenge was solved at the end of the bundle transaction.

For example, we can create the following checker:

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ClearChecker {
    function requireClear(uint256 captureId) public view {
        IMevShareCaptureLogger logger = IMevShareCaptureLogger(0x6C9c151642C0bA512DE540bd007AFa70BE2f1312);
        require(logger.winnerCaptures(tx.origin, captureId));
    }
}

interface IMevShareCaptureLogger {
    function winnerCaptures(address, uint256) external view returns (bool);
}

```

Then, calling this `requireClear` function is included at the end of the bundle transaction, and it can be solved.

```ts
const mevShareBundle = {
    inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + BLOCKS_TO_TRY },
    body: [
        { hash: pendingTxHash },
        { tx: backrunSignedTx, canRevert: false },
        { tx: backrunSignedTx2, canRevert: false },
    ]
}
```

## Challenge 8: MevShareCTFNewContract (address)

Challenge contract address: https://goerli.etherscan.io/address/0x5eA0feA0164E5AA58f407dEBb344876b5ee10DEA

The source code of this contract is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTF.sol";

contract MevShareCTFNewContracts is MevShareCTFBase {
    uint256 public magicNumber;

    // maps addresses to child contracts, acts both as check for valid caller and which CTF is being targeted
    //  value of 1 = emitted by address
    //  value of 2 = emitted by salt
    mapping (address => uint256) childContracts;

    event Activate(address newlyDeployedContract);
    event ActivateBySalt(bytes32 salt);

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFBase(_mevShareCaptureLogger) payable {
    }

    function proxyRegisterCapture() external {
        uint256 childContractType = childContracts[msg.sender];
        if (childContractType == 0) {
            revert("Not called by a child contract");
        }
        mevShareCaptureLogger.registerCapture(300 + childContractType, tx.origin);
    }

    function activateRewardNewContract(bytes32 salt) external payable onlyOwner {
        MevShareCTFNewContract newlyDroppedContract = new MevShareCTFNewContract{salt: salt}();
        childContracts[address(newlyDroppedContract)] = 1;
        emit Activate(address(newlyDroppedContract));
    }

    function activateRewardBySalt(bytes32 salt) external payable onlyOwner {
        MevShareCTFNewContract newlyDroppedContract = new MevShareCTFNewContract{salt: salt}();
        childContracts[address(newlyDroppedContract)] = 2;
        emit ActivateBySalt(salt);
    }
}

contract MevShareCTFNewContract {
    MevShareCTFNewContracts immutable mevShareCTFNewContracts;
    uint256 public activeBlock;

    constructor() payable {
        mevShareCTFNewContracts = MevShareCTFNewContracts(msg.sender);
        activeBlock = block.number;
    }

    function claimReward() external {
        require (activeBlock == block.number);
        activeBlock = 0;
        mevShareCTFNewContracts.proxyRegisterCapture();
    }
}
```

From this code, it can be seen that this contract has two challenges, 301 and 302.

The transaction data given in the event stream is as follows:

```typescript
data: {"hash":"0xee08b12e1adca7790108a0c88e531c74fe151f7d0353c10b664268e2960bb4bc","logs":[{"address":"0x5ea0fea0164e5aa58f407debb344876b5ee10dea","topics":["0xf7e9fe69e1d05372bc855b295bc4c34a1a0a5882164dd2b26df30a26c1c8ba15"],"data":"0x00000000000000000000000017bda556c8dfd723c6886f60b87e4b2a2aaa3842"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x27100"}
```

We see that we can backrun the `claimReward` function of the `MevShareCTFNewContract` contract deployed by the activation function.

The `emit Activate(address(newlyDroppedContract))` in the `activateRewardNewContract` function simply gives us the address of the deployed `MevShareCTFNewContract` contract, and we can use it to solve the problem.

The solver is in the writeup for the next challenge.

## Challenge 9: MevShareCTFNewContract (salt)

Challenge contract address: https://goerli.etherscan.io/address/0x5eA0feA0164E5AA58f407dEBb344876b5ee10DEA

The source code of this contract is the same as in the previous challenge.
The transaction data given in the event stream is as follows:

```typescript
data: {"hash":"0xce1fcf4da31b0bf463bfa87fdb98f64e75837dc85b1c3b5ce90d7781b24b66e8","logs":[{"address":"0x5ea0fea0164e5aa58f407debb344876b5ee10dea","topics":["0x71fd33d3d871c60dc3d6ecf7c8e5bb086aeb6491528cce181c289a411582ff1c"],"data":"0xc14628cdd6dca1f66dec7d5ecc3d285ddca8eb8507e63d77865ee27e75cb8f62"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x27100"}
```

The `CREATE2` salt is given via `emit ActivateBySalt(salt)` in the `activateRewardBySalt` function.

The deployed address by `CREATE2` can be calculated using `ethers.utils.getCreate2Address(from ,salt ,initCodeHash)`.
Thus, we need to know the `initCode` to calculate the `initCodeHash`.

The `initCode` can be found from the EVM instruction-level tracing result of `cast` as follows:

```sh
$ cast run 0x7946c084fe313cabe484470310b97f035506ac8de35ac64966af4c318a3c04f7 --trace-printer | grep CREATE2
depth:1, PC:935, gas:0x435a6(275878), OPCODE: "CREATE2"(245)  refund:0x0(0) Stack:[0x00000000000000000000000000000000000000000000000000000000c03f4641_U256, 0x00000000000000000000000000000000000000000000000000000000000000bc_U256, 0xcd04426d29b0bc305d2e8013ae967ce8d3fde4e4ac59ace4afbec4420c9cfd05_U256, 0x0000000000000000000000000000000000000000000000000000000000000000_U256, 0xcd04426d29b0bc305d2e8013ae967ce8d3fde4e4ac59ace4afbec4420c9cfd05_U256, 0xcd04426d29b0bc305d2e8013ae967ce8d3fde4e4ac59ace4afbec4420c9cfd05_U256, 0x000000000000000000000000000000000000000000000000000000000000013c_U256, 0x0000000000000000000000000000000000000000000000000000000000000080_U256, 0x0000000000000000000000000000000000000000000000000000000000000000_U256], Data size:448, Data: 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000060a060405233608052436000556080516101166100266000396000606f01526101166000f3fe6080604052348015600f57600080fd5b506004361060325760003560e01c806396b81609146037578063b88a802f146051575b600080fd5b603f60005481565b60405190815260200160405180910390f35b60576059565b005b4360005414606657600080fd5b600080819055507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663720ecf456040518163ffffffff1660e01b8152600401600060405180830381600087803b15801560c757600080fd5b505af115801560da573d6000803e3d6000fd5b5050505056fea26469706673582212207a00db890eff47285ac0d9c9b8735727d476952aa87b45ee82fd6bb4f42c6fa764736f6c6343000813003300000000
```

The solvers for this challenge and the previous one are as follows:

```typescript
import MevShareClient, { IPendingTransaction } from '@flashbots/mev-share-client'
import { getCreate2Address, keccak256, Contract, JsonRpcProvider, Wallet, ContractTransaction } from 'ethers'
import { MEV_SHARE_CTF_SIMPLE_ABI } from '../10x/abi';
import dotenv from "dotenv"
dotenv.config()

const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545'
const EXECUTOR_KEY = process.env.EXECUTOR_KEY || Wallet.createRandom().privateKey
const FB_REPUTATION_PRIVATE_KEY = process.env.FB_REPUTATION_KEY || Wallet.createRandom().privateKey

const provider = new JsonRpcProvider(RPC_URL)
const executorWallet = new Wallet(EXECUTOR_KEY, provider)
const authSigner = new Wallet(FB_REPUTATION_PRIVATE_KEY, provider)
const mevShare = MevShareClient.useEthereumGoerli(authSigner)

const TARGET_ADDRESS_301 = "0x5ea0fea0164e5aa58f407debb344876b5ee10dea";
const TARGET_ADDRESS_302 = "0x5ea0fea0164e5aa58f407debb344876b5ee10dea";

const MAX_BLOCK = 24

const TX_GAS_LIMIT = 400000
const MAX_GAS_PRICE = 40n
const MAX_PRIORITY_FEE = 30n
const GWEI = 10n ** 9n

async function main() {
    console.log("mev-share auth address: " + authSigner.address)
    console.log("executor address: " + executorWallet.address)
    const nonce = await executorWallet.getNonce("latest")

    mevShare.on('transaction', async (pendingTx: IPendingTransaction) => {
        if (!transactionIsRelatedToTarget(pendingTx)) {
            console.log('skipping tx: ' + pendingTx.hash);
            return
        }
        console.log(pendingTx)
        const currentBlockNumber = await provider.getBlockNumber()

        backrunAttempt(currentBlockNumber, nonce, pendingTx)
    })
}
main()

async function getSignedBackrunTx(backrunTx: ContractTransaction, nonce: number) {
    const backrunTxFull = {
        ...backrunTx,
        chainId: 5,
        maxFeePerGas: MAX_GAS_PRICE * GWEI,
        maxPriorityFeePerGas: MAX_PRIORITY_FEE * GWEI,
        gasLimit: TX_GAS_LIMIT,
        nonce: nonce
    }
    return executorWallet.signTransaction(backrunTxFull)
}

function bigintJsonEncoder(key: any, value: any) {
    return typeof value === 'bigint'
        ? value.toString()
        : value
}

async function backrunAttempt(currentBlockNumber: number, nonce: number, pendingTx: IPendingTransaction) {

    const pendingTxHash = pendingTx.hash;

    const logs = pendingTx.logs;
    if (logs === undefined) {
        throw new Error("logs is undefined")
    }
    console.log("logs", logs);
    const args = logs[0].data;
    if (args === undefined) {
        throw new Error("args is undefined")
    }

    let addr;
    if (args.slice(2, 4) == "00") {
        addr = "0x" + args.slice(24, 64);
    } else {
        const initCode = "0x60a060405233608052436000556080516101166100266000396000606f01526101166000f3fe6080604052348015600f57600080fd5b506004361060325760003560e01c806396b81609146037578063b88a802f146051575b600080fd5b603f60005481565b60405190815260200160405180910390f35b60576059565b005b4360005414606657600080fd5b600080819055507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663720ecf456040518163ffffffff1660e01b8152600401600060405180830381600087803b15801560c757600080fd5b505af115801560da573d6000803e3d6000fd5b5050505056fea26469706673582212207a00db890eff47285ac0d9c9b8735727d476952aa87b45ee82fd6bb4f42c6fa764736f6c63430008130033";
        const initCodeHash = keccak256(initCode);
        addr = getCreate2Address(TARGET_ADDRESS_302, args, initCodeHash);
    }
    console.log("addr", addr);

    const newContract = new Contract(addr, MEV_SHARE_CTF_SIMPLE_ABI, executorWallet)

    const backrunTx = await newContract.claimReward.populateTransaction()
    const backrunSignedTx = await getSignedBackrunTx(backrunTx, nonce);
    try {
        const mevShareBundle = {
            inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + MAX_BLOCK },
            body: [
                { hash: pendingTxHash },
                { tx: backrunSignedTx, canRevert: false }
            ]
        }
        const sendBundleResult = await mevShare.sendBundle(mevShareBundle);
        console.log('Bundle Hash: ' + sendBundleResult.bundleHash)
        if (process.env.BUNDLE_SIMULATION !== undefined) {
            mevShare.simulateBundle(mevShareBundle).then(simResult => {
                console.log(`Simulation result for bundle hash: ${sendBundleResult.bundleHash}`)
                console.log(JSON.stringify(simResult, bigintJsonEncoder))
            }).catch(error => {
                console.log(`Simulation error for bundle hash: ${sendBundleResult.bundleHash}`)
                console.warn(error);
            })
        }
    } catch (e) {
        console.log('err', e)
    }
}

function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return (pendingTx.logs || []).some(log => (log.address === TARGET_ADDRESS_301 || log.address === TARGET_ADDRESS_302));
}
```

## Challenge 10: MevShareCTFTriple

Challenge contract address: https://goerli.etherscan.io/address/0x1eA6Fb65BAb1f405f8Bdb26D163e6984B9108478

The source code of this contract is as follows:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "contracts/MevShareCaptureLogger.sol";
import "./MevShareCTF.sol";

contract MevShareCTFTriple is MevShareCTFBase {
    uint256 public activeBlock;

    mapping (address => mapping (uint256 => uint256)) addressBlockCount;

    event Activate();

    constructor(MevShareCaptureLogger _mevShareCaptureLogger) MevShareCTFBase(_mevShareCaptureLogger) payable {
    }

    function activateRewardTriple() external payable onlyOwner {
        activeBlock = block.number;
        emit Activate();
    }

    function claimReward() external {
        require (activeBlock == block.number);
        require (tx.origin == msg.sender);
        uint256 claimCount = addressBlockCount[tx.origin][block.number] + 1;
        if (claimCount == 3) {
            mevShareCaptureLogger.registerCapture(401, tx.origin);
            return;
        }
        addressBlockCount[tx.origin][block.number] = claimCount;
    }
}
```

The transaction data given in the event stream is as follows:

```typescript
data: {"hash":"0xc47ca9e62168daaca7490f58730c392a299ee5a960c288f894d225796b2534c2","logs":[{"address":"0x1ea6fb65bab1f405f8bdb26d163e6984b9108478","topics":["0x59d3ce47d6ad6c6003cef97d136155b29d88653eb355c8bed6e03fbf694570ca"],"data":"0x"}],"txs":null,"mevGasPrice":"0x2faf080","gasUsed":"0x7530"}
```

It is necessary to call `claimReward` three times in the same block as the `activateRewardTriple` function.

It can be solved by simply constructing a bundle transaction as follows:

```typescript
const mevShareBundle = {
    inclusion: { block: currentBlockNumber + 1, maxBlock: currentBlockNumber + MAX_BLOCK },
    body: [
        { hash: pendingTxHash },
        { tx: backrunSignedTx, canRevert: false },
        { tx: backrunSignedTx2, canRevert: false },
        { tx: backrunSignedTx3, canRevert: false },
    ]
}
```
