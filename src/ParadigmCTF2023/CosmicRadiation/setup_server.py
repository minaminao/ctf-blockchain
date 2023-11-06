import socket

import requests
from web3 import Web3

CHALLENGE_HOST = "localhost"
CHALLENGE_PORT = 7777
ANVIL_HOST = "http://localhost"
ANVIL_PORT = 8888
ANVIL_URL = f"{ANVIL_HOST}:{ANVIL_PORT}"
w3 = Web3(Web3.HTTPProvider(ANVIL_URL))


def request_anvil(method: str, params: list):
    headers = {"Content-Type": "application/json"}
    data = {"method": method, "params": params, "id": 1, "jsonrpc": "2.0"}

    response = requests.post(ANVIL_URL, json=data, headers=headers)
    return response.json()


def anvil_setBalance(addr: str, balance: str):
    print("anvil_setBalance", addr, balance, request_anvil("anvil_setBalance", [addr, balance]))


def anvil_setCode(addr: str, code: str):
    print("anvil_setCode", addr, "***", request_anvil("anvil_setCode", [addr, code]))


while True:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((CHALLENGE_HOST, CHALLENGE_PORT))
        s.listen()

        print(f"Waiting for a connection on {CHALLENGE_HOST}:{CHALLENGE_PORT}")
        conn, addr = s.accept()

        with conn:
            try:
                print(f"Connected by {addr}")
                conn.sendall(b"ticket? ")
                _ticket = conn.recv(1024).strip()
                conn.sendall(b"action? ")
                action = conn.recv(1024).strip()

                if action == b"2":
                    conn.close()
                    continue

                assert action == b"1"

                corrupted_addrs = {}

                while True:
                    conn.sendall(b"bitflip? ")

                    bitflip = conn.recv(1024).strip().decode()

                    if bitflip == "":
                        break

                    (addr, *bits) = bitflip.split(":")
                    addr = Web3.to_checksum_address(addr)
                    bits = [int(v) for v in bits]

                    if addr in corrupted_addrs:
                        raise Exception("already corrupted this address")

                    corrupted_addrs[addr] = True

                    balance = w3.eth.get_balance(addr)
                    if balance == 0:
                        raise Exception("invalid target")

                    code = bytearray(w3.eth.get_code(addr))
                    for bit in bits:
                        byte_offset = bit // 8
                        bit_offset = 7 - bit % 8
                        if byte_offset < len(code):
                            code[byte_offset] ^= 1 << bit_offset

                    total_bits = len(code) * 8
                    corrupted_balance = int(balance * (total_bits - len(bits)) / total_bits)

                    anvil_setBalance(addr, hex(corrupted_balance))
                    anvil_setCode(addr, "0x" + code.hex())

                conn.sendall(f" - {ANVIL_URL}\n".encode())
                PLAYER_PRIVATE_KEY = "0x3c7bada9137558d226f16ad476d107bcedd9346d7bf08cc01b9df4b885c1807b"  # cast wallet new
                PLAYER_ADDR = "0xFe26e3dCAdE6660909C5E6A71D964d70589A2Ae6"
                anvil_setBalance(PLAYER_ADDR, hex(1000 * 10**18))
                conn.sendall(f"private key: {PLAYER_PRIVATE_KEY}\n".encode())

                CHALLENGE_CONTRACT_ADDR = "0x2b7fF125061edbC692dF5CF25528323adb738Eb1"
                CHALLENGE_CONTRACT_CODE = "0x6080604052348015600e575f80fd5b50600436106026575f3560e01c8063afd8206714602a575b5f80fd5b60306044565b604051603b91906061565b60405180910390f35b5f47905090565b5f819050919050565b605b81604b565b82525050565b5f60208201905060725f8301846054565b9291505056fea264697066735822122063d06b0aaf3ba599d040b39fb5d1de2423621c87865ab1817f0ef558d6f35acc64736f6c63430008160033"
                conn.sendall(f"challenge contract: {CHALLENGE_CONTRACT_ADDR}\n".encode())
                anvil_setCode(CHALLENGE_CONTRACT_ADDR, CHALLENGE_CONTRACT_CODE)
            except Exception as e:
                print(e)

                try:
                    conn.close()
                except:
                    pass

                continue
