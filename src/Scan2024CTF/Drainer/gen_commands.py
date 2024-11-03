import json

f = open("bquxjob_71a354df_192a3345011.json")

txs = json.load(f)

arg_len_set = set()
count = 0
for tx in txs:
    tx_input = tx["transactions"]["input"]
    arg = bytes.fromhex(tx_input[10:])
    assert len(arg) % 32 == 0

    if "aA862F977d6916A1e89E856FC11Fd99a2F2fAbF8".lower() not in tx_input:
        continue

    arg_len = len(arg) // 32

    arg_len_set.add(arg_len)

    print("echo " + tx["transactions"]["hash"])
    print(f"cast run {tx["transactions"]["hash"]} -q | grep transfer")
    print("echo --")
