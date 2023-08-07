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

const TARGET_ADDRESS = "0x65459dd36b03af9635c06bad1930db660b968278"
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
        return
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

// 101
// function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
//     return (pendingTx.logs || []).some(log => log.address === TARGET_ADDRESS)
// }

// 102, 103
function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
    return pendingTx.to === TARGET_ADDRESS
}

// 102, 103
// function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
//     return pendingTx.functionSelector == "0xa3c356e4"
// }

// 104 0x20a1A5857fDff817aa1BD8097027a841D4969AA5
// function transactionIsRelatedToTarget(pendingTx: IPendingTransaction) {
//     return true
// }
