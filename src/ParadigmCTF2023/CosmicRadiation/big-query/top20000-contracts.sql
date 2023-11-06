SELECT contracts.address, balances.eth_balance
FROM `bigquery-public-data.crypto_ethereum.contracts` AS contracts
JOIN `bigquery-public-data.crypto_ethereum.balances` AS balances
ON balances.address = contracts.address
ORDER BY balances.eth_balance DESC
LIMIT 20000
