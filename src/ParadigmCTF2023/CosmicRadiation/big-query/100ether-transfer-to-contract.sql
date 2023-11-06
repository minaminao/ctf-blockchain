SELECT transactions.hash, transactions.from_address, transactions.to_address, transactions.value, transactions.nonce
FROM `bigquery-public-data.crypto_ethereum.transactions` AS transactions
JOIN `bigquery-public-data.crypto_ethereum.contracts` AS contracts
ON transactions.to_address = contracts.address
WHERE transactions.value > cast('1E20' as NUMERIC) AND transactions.block_number >= 18437825 AND transactions.block_number <= 18451700 AND transactions.receipt_status = 1
ORDER BY transactions.block_number, transactions.nonce
LIMIT 1000
