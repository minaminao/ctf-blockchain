from random import SystemRandom
from ecdsa import ecdsa
import sha3
import binascii
from typing import Tuple
import uuid
import os


def gen_keypair() -> Tuple[ecdsa.Private_key, ecdsa.Public_key]:
    """
    generate a new ecdsa keypair
    """
    g = ecdsa.generator_secp256k1
    d = SystemRandom().randrange(1, g.order())
    pub = ecdsa.Public_key(g, g * d)
    priv = ecdsa.Private_key(pub, d)
    return priv, pub


def gen_session_secret() -> int:
    """
    generate a random 32 byte session secret
    """
    with open("/dev/urandom", "rb") as rnd:
        seed1 = int(binascii.hexlify(rnd.read(32)), 16)
        seed2 = int(binascii.hexlify(rnd.read(32)), 16)
    return seed1 ^ seed2


def hash_message(msg: str) -> int:
    """
    hash the message using keccak256, truncate if necessary
    """
    k = sha3.keccak_256()
    k.update(msg.encode("utf8"))
    d = k.digest()
    n = int(binascii.hexlify(d), 16)
    olen = ecdsa.generator_secp256k1.order().bit_length() or 1
    dlen = len(d)
    n >>= max(0, dlen - olen)
    return n


if __name__ == "__main__":
    flag = os.getenv("FLAG", "PCTF{placeholder}")

    priv, pub = gen_keypair()
    session_secret = gen_session_secret()

    for _ in range(4):
        message = input("message? ")
        hashed = hash_message(message)
        sig = priv.sign(hashed, session_secret)
        print(f"r=0x{sig.r:032x}")
        print(f"s=0x{sig.s:032x}")

    test = hash_message(uuid.uuid4().hex)
    print(f"test=0x{test:032x}")

    r = int(input("r? "), 16)
    s = int(input("s? "), 16)

    if not pub.verifies(test, ecdsa.Signature(r, s)):
        print("better luck next time")
        exit(1)

    print(flag)