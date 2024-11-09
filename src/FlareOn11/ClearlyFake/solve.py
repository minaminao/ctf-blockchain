import subprocess
import base64
import json
from pwn import xor

tx_hashes = [
    "0xae4711c6e9d6d8f5d00a88e1adb35595bc7d7a73130e87356e3e71e65e17f337",
    "0xdbf0e117fb3d4db0cd746835cfc4eb026612ac36a80f9f0f248dce061d90ae54",
    "0x820549b2eb77e1078490eea9d2b819c219f0cfef921abaa6580d8cf628a8cd5f",
    "0xef06996ee51d24cc6bfedcaa57bdc31e56975ec98d018f211b7db114fc94b573",
    "0xb2405b84d625688c380a6ebf8e20526e9024b2b2b15700eb83437e2e19812ebe",
    "0x05660d13d9d92bc1fc54fb44c738b7c9892841efc9df4b295e2b7fda79756c47",
    "0x539ab8268334453b5f293948a89fe1b9a75aaa640571046416956c65bc611a79",
    "0x6da2ad09ec61dfc9305d4f58cc2758a0dbe3429e7726cc2098a2ae425bc6c9ef",
    "0xd086acbcedd08bf533457e627529a1206ad5e4461478ae2ce20be51659ac2734",
    "0xd4c9d45de5f45f855d117938b2fb8bea1ac4691aaf43cb6fab5dcb5fcd47c278",
    "0x88336b0a629fd096c5b8e031c603abd78f2fba0a0b09b3b03e1219098849fa73",
    "0x096bc2f76176518f7f0ca267d1ac53e9bda8d49a3e4013f84d812dbd3cf479f8",
    "0x5a6675770eff26562a47efa4e22bbf29d764351c13d8b1dce1f9c4f6a471d2f3",
]

for tx_hash in tx_hashes:
    print(tx_hash)
    cmd = f"cast tx {tx_hash} --json"
    result = subprocess.check_output(cmd, shell=True).decode("utf-8")
    tx_input = json.loads(result)["input"]
    func_args = bytes.fromhex(tx_input[2:])[4:]
    start_position = func_args[:0x20]
    assert start_position == b"\x00" * 31 + b"\x20"
    length = int(func_args[0x20:0x40].hex(), 16)
    string_data = func_args[0x40 : 0x40 + length]
    print(string_data)
    KEY = b"FLAREON24"
    try:
        decoded = base64.b64decode(string_data)
        print(decoded)
        if b" " in decoded:
            decoded = decoded.replace(b" ", b"")
            decoded = bytes.fromhex(decoded.decode())
            print(decoded)
        if len(decoded) <= 1000:
            decoded = xor(decoded, KEY)
            print(decoded)
    except Exception as e:
        print(e)
        decoded = xor(decoded, KEY)
        print(decoded)
    print()
