from ecdsa import ecdsa
from Crypto.Util.number import isPrime
import random


def gen_key():
    g = ecdsa.generator_secp256k1

    while True:
        private_key = random.randint(0, 1 << 256 - 1)
        public_key = private_key * g
        x = str(hex(public_key.x())[2:])
        x = ("00" * 32 + x)[-32 * 2:]
        y = str(hex(public_key.y())[2:])
        y = ("00" * 32 + y)[-32 * 2:]
        public_key_hex = x + y

        if public_key_hex[:2] == "00":
            return private_key, public_key_hex


def pad(n, hexdata):
    return ("00" * n + hexdata)[-n * 2:]


def main():

    private_key, public_key_hex = gen_key()
    print(f"{private_key = }")
    print(f"{public_key_hex = }")

    calldata = ""

    for i in range(0x60, 0x100):
        if isPrime(i):
            arg_0 = i
            break

    for i in range(0x100, 0x200):
        if isPrime(i):
            arg_1 = i
            break

    # Base: stage5_payload = "60025A0660085700"
    stage5_payload = "60025A06600857005b5b5b30"

    calldata += "890d6908"  # selector
    calldata += pad(32, hex(arg_0)[2:])
    calldata += pad(32, hex(arg_1)[2:])
    calldata += pad(32, hex(arg_1 >> 8)[2:])
    calldata += pad(32, hex(1)[2:])
    calldata += "00"
    offset = pad(1, hex(9 + len(stage5_payload) // 2)[2:])
    calldata += stage5_payload + f"60408060{offset}3d393df3"
    calldata += public_key_hex
    calldata = (calldata + "00" * 500)[:1000 - 2]

    print()
    print(f"{calldata = }")
    print()

    print(calldata[:4 * 2])
    for i in range(10):
        print(calldata[(4 + i * 0x20) * 2:(4 + (i + 1) * 0x20) * 2], f"[{hex(i * 0x20)}, {hex((i + 1) * 0x20)})")


if __name__ == "__main__":
    main()