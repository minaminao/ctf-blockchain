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
