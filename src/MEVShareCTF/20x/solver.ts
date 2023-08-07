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
