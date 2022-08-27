import hashlib

# cast sig "isValidSignature(bytes32,bytes)"
SELECTOR = b"\x16\x26\xba\x7e"
# cast keccak CHALLENGE_MAGIC
MAGIC = bytes.fromhex("19bb34e293bba96bf0caeea54cdd3d2dad7fdf44cbea855173fa84534fcfb528")

i = 0
while True:
    i += 1
    offset = 0x40.to_bytes(32, "big")
    length_int = (len(hex(i)[2:]) + 1) // 2
    length = length_int.to_bytes(32, "big")
    signature = i.to_bytes(32, "little")
    message = SELECTOR + MAGIC + offset + length + signature
    if SELECTOR == hashlib.sha256(message).digest()[:4]:
        print(message.hex())
        print(signature[:length_int].hex())
        break
