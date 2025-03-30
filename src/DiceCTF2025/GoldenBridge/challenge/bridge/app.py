from eth_account import Account as EthAccount
from flask import Flask, render_template, request
import json
import os
from solana.rpc.api import Client as Solana
from solders.keypair import Keypair
from solders.message import Message as SolanaMessage
from solders.pubkey import Pubkey
from solders.transaction import Transaction as SolanaTransaction
from spl.token.client import Token as SPLToken
from spl.token.constants import TOKEN_PROGRAM_ID
import spl.token.instructions as spl_token
import traceback
from web3 import Web3
from web3.contract.contract import ContractFunction
from werkzeug.middleware.proxy_fix import ProxyFix

player_info = json.loads(open("/tmp/player.json").read())

# setup web3 connection
w3 = Web3(Web3.HTTPProvider("http://localhost:8545"))
assert w3.is_connected()
eth_deployer = EthAccount.from_key(json.loads(open("/tmp/eth/accounts.json").read())[0]["private_key"])
eth_Setup = w3.eth.contract(
   json.loads(open("/tmp/eth/deployment.json").read())["deployedTo"],
   abi=json.loads(open("../eth/out/Setup.sol/Setup.json").read())["abi"],
)
eth_Bubble = w3.eth.contract(
   eth_Setup.functions.bubble().call(),
   abi=json.loads(open("../eth/out/Bubble.sol/Bubble.json").read())["abi"],
)
eth_Bridge = w3.eth.contract(
   eth_Setup.functions.bridge().call(),
   abi=json.loads(open("../eth/out/Bridge.sol/Bridge.json").read())["abi"],
)
print(f"Ethereum connected!")

# setup solana connection
solana = Solana("http://localhost:8899")
assert solana.is_connected()
sol_bridge = Keypair.from_json(open("/tmp/sol/bridge.json").read())
sol_bbl = Keypair.from_json(open("/tmp/sol/bbl.json").read())
sol_bridge_spl = SPLToken(solana, sol_bbl.pubkey(), TOKEN_PROGRAM_ID, sol_bridge)
sol_bridge_ata = spl_token.get_associated_token_address(sol_bridge.pubkey(), sol_bbl.pubkey(), TOKEN_PROGRAM_ID)
print(f"Solana connected!")

app = Flask(__name__, static_folder="static")
app.secret_key = os.urandom(32).hex()
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

@app.get("/")
def index():
  return render_template("index.html")

@app.get("/player.json")
def player():
  return player_info

# https://ethereum.stackexchange.com/a/70244
def eth_transact(fun: ContractFunction, signer: EthAccount):
  tx = fun.build_transaction({
    "from": signer.address,
    "nonce": w3.eth.get_transaction_count(signer.address),
  })
  tx_signed = signer.sign_transaction(tx)
  w3.eth.send_raw_transaction(tx_signed.raw_transaction)

# remove $BBL that has been deposited in the Bridge on
# the Ethereum side, then mint $BBL on the Solana side
@app.post("/toSol")
def toSol():
  try:
    key = request.json["key"]
    if not (isinstance(key, str) and key.startswith("0x")):
      return "Invalid key", 400
    amount = request.json["amount"]
    if not (isinstance(amount, int) and amount > 0):
       return "Invalid amount", 400
    target = request.json["target"]
    if not isinstance(target, str):
      return "Invalid target", 400
    
    acc = EthAccount.from_key(key)
    target = Pubkey.from_string(target)
    if not target.is_on_curve():
       return "Invalid target (not on curve)", 400
    target_ata = spl_token.get_associated_token_address(target, sol_bbl.pubkey(), TOKEN_PROGRAM_ID)
    if solana.get_account_info(target_ata).value is None:
      return "Solana account does not have an associated token account for $BBL, please fund one yourself >:D", 400
    
    eth_transact(eth_Bridge.functions.toBridge(acc.address, amount), eth_deployer)
    sol_bridge_spl.mint_to(target_ata, sol_bridge, amount)
    return f"Successfully transferred your $BBL!", 200
  except Exception as e:
    app.logger.error(traceback.format_exc())
    return str(e), 400

# transfer and burn $BBL on the Solana side, then
# credit $BBL into the Bridge on the Ethereum side
@app.post("/toEth")
def toEth():
  try:
    key = request.json["key"]
    if not isinstance(key, str):
      return "Invalid key", 400
    amount = request.json["amount"]
    if not (isinstance(amount, int) and amount > 0):
       return "Invalid amount", 400
    target = request.json["target"]
    if not (isinstance(target, str) and target.startswith("0x")):
      return "Invalid target", 400
    
    src = Keypair.from_json(key)
    src_ata = spl_token.get_associated_token_address(src.pubkey(), sol_bbl.pubkey(), TOKEN_PROGRAM_ID)
    if solana.get_account_info(src_ata).value is None:
      return "Solana account does not have an associated token account for $BBL", 400
    
    # bruh SPLToken doesn't let us compose two instructions
    recent_blockhash = solana.get_latest_blockhash().value.blockhash
    ixs = [
      spl_token.transfer(
        spl_token.TransferParams(
          program_id=TOKEN_PROGRAM_ID,
          source=src_ata,
          dest=sol_bridge_ata,
          owner=src.pubkey(),
          amount=amount,
          signers=[src.pubkey()],
        )
      ),
      spl_token.burn(
        spl_token.BurnParams(
          program_id=TOKEN_PROGRAM_ID,
          account=sol_bridge_ata,
          mint=sol_bbl.pubkey(),
          owner=sol_bridge.pubkey(),
          amount=amount,
          signers=[sol_bridge.pubkey()],
        )
      )
    ]
    solana.send_transaction(
      SolanaTransaction(
        [sol_bridge, src],
        SolanaMessage.new_with_blockhash(ixs, src.pubkey(), recent_blockhash),
        recent_blockhash
      )
    )
    
    eth_transact(eth_Bridge.functions.fromBridge(target, amount), eth_deployer)
    return f"Successfully transferred your $BBL!", 200
  except Exception as e:
    app.logger.error(traceback.format_exc())
    return str(e), 400

# I believe my code is flawless so if you can steal all 1_000_000_000 $BBL gg
# (please return it I will give you a 10% bounty I have a lil megute to feed)
@app.get("/flag")
def flag():
  try:
    if eth_Setup.functions.isSolved().call():
      return os.environ.get("FLAG", "dice{test_flag}")
    return "no flag for u >:D", 403
  except Exception:
    return "no flag for u >:D", 403

if __name__ == "__main__":
    app.run("0.0.0.0", 8000, debug=True)
