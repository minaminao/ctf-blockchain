import requests

master_address = "mhbqfwLN6Lw2dAjvsYCNcmc3HERbBx1eAW"

broker_addresses = [
    "mppJi8gGGjWEdzahhH3MdbBjNXEwE3hVxJ",
    "mjfUXLaQgVYK4Meas1TnYbBZbNCFJmxqgC",
    "mrczRAsCPKbSwnyCwc6FY7HzTDzUAP2DEf",
]

victim_addresses = []

for broker_address in broker_addresses:
    url = f"https://api.whatsonchain.com/v1/bsv/test/address/{broker_address}/confirmed/history?limit=200"
    response = requests.get(url)
    assert response.status_code == 200
    data = response.json()

    txs = data["result"]
    print(len(txs))
    for tx in txs:
        print(tx)
        url = f"https://api.whatsonchain.com/v1/bsv/test/tx/hash/{tx["tx_hash"]}"
        response = requests.get(url)
        assert response.status_code == 200
        tx_data = response.json()
        vout = tx_data["vout"]
        for vout_x in vout:
            if not (
                vout_x["value"] == 0.000105
                and vout_x["scriptPubKey"]["addresses"][0] == broker_address
            ):
                continue
            url = f"https://api.whatsonchain.com/v1/bsv/test/tx/hash/{tx_data["vin"][0]["txid"]}"
            response = requests.get(url)
            assert response.status_code == 200
            prev_tx_data = response.json()
            prev_vout = prev_tx_data["vout"]
            victim_addresses.append(prev_vout[0]["scriptPubKey"]["addresses"][0])
            print(victim_addresses)

flag_broker = ",".join(sorted(broker_addresses, reverse=True))
flag_victim = ",".join(sorted(victim_addresses, reverse=True))

print(f"SCAN2024{{[{flag_victim}]:[{flag_broker}],{master_address}}}")
