import json
import os
import subprocess
import time

print("Waiting for blockchains to start...")
while not (os.path.exists("/tmp/eth/done") and os.path.exists("/tmp/sol/done")):
  time.sleep(1)
print("Blockchains started!\n")

eth_info = json.loads(open("/tmp/eth/player.json").read())
sol_bridge = open("/tmp/sol/bridge-pubkey.txt").read()
sol_mint = open("/tmp/sol/bbl-pubkey.txt").read()
sol_player_pubkey = open("/tmp/sol/player-pubkey.txt").read()
sol_player_keypair = open("/tmp/sol/player.json").read()

print(f"== Ethereum =====================")
print(f"RPC: localhost:5000/eth")
print(f"Setup: {eth_info["setup"]}")
print(f"Address: {eth_info["address"]}")
print(f"Private Key: {eth_info["private_key"]}\n")
print(f"== Solana =======================")
print(f"RPC: localhost:5000/sol")
print(f"Bridge: {sol_bridge}")
print(f"Mint: {sol_mint}")
print(f"Pubkey: {sol_player_pubkey}")
print(f"Keypair: {sol_player_keypair}")
print(f"=================================")

with open("/tmp/player.json", "w") as f:
  json.dump({
    "ethereum": {
      "rpc": "localhost:5000/eth",
      "setup": eth_info["setup"],
      "address": eth_info["address"],
      "private_key": eth_info["private_key"],
    },
    "solana": {
      "rpc": "localhost:5000/sol",
      "bridge": sol_bridge,
      "mint": sol_mint,
      "pubkey": sol_player_pubkey,
      "keypair": json.loads(sol_player_keypair),
    }
  }, f)

print("\nStarting frontend...", flush=True)
subprocess.run(["gunicorn", "-w", "1", "app:app", "-b", "0.0.0.0:5001"], cwd="/bridge")
