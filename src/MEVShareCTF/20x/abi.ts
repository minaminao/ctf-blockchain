export const MEV_SHARE_CTF_MAGIC_NUMBER = [{ "inputs": [{ "internalType": "contract MevShareCaptureLogger", "name": "_mevShareCaptureLogger", "type": "address" }], "stateMutability": "payable", "type": "constructor" }, { "anonymous": false, "inputs": [{ "indexed": false, "internalType": "uint256", "name": "lowerBound", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "upperBound", "type": "uint256" }], "name": "Activate", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" }], "name": "OwnershipTransferred", "type": "event" }, { "inputs": [{ "internalType": "uint256", "name": "_lowerBound", "type": "uint256" }, { "internalType": "uint256", "name": "_upperBound", "type": "uint256" }, { "internalType": "uint256", "name": "_magicNumber", "type": "uint256" }], "name": "activateRewardMagicNumber", "outputs": [], "stateMutability": "payable", "type": "function" }, { "inputs": [], "name": "activeBlock", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "destination", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" }, { "internalType": "bytes", "name": "data", "type": "bytes" }], "name": "call", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_magicNumber", "type": "uint256" }], "name": "claimReward", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "renounceOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }];
export const CLEAR_CHECKER = [
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "captureId",
                "type": "uint256"
            }
        ],
        "name": "requireClear",
        "outputs": [],
        "stateMutability": "view",
        "type": "function"
    }
];
