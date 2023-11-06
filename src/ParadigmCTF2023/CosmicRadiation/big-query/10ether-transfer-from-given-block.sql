SELECT DISTINCT traces.from_address
FROM `bigquery-public-data.crypto_ethereum.traces` AS traces
WHERE traces.value > cast('1E19' as NUMERIC) AND traces.block_number >= 18437825 AND traces.block_number <= 18451700
LIMIT 100000
