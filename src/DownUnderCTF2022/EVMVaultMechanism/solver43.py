from Crypto.Hash import keccak

for i in range(256**3):
    data = b"\x62" + i.to_bytes(3, "little")
    k = keccak.new(digest_bits=256, data=data)
    if k.digest()[-1] == 0x77:
        print(data.hex())
        break

bytecode = bytes.fromhex("6901020304050607080910624500007f434343430000000000000000000000000000000000000000000000000000000060005260006000600860006000736e4198c61c75d1b4d1cbcd00707aac7d76867cf861fffff1")
for i in range(256**10):
    bytecode_ = bytecode.replace(bytes.fromhex("01020304050607080910"), i.to_bytes(10, "little"))
    assert len(bytecode_) == len(bytecode)
    k = keccak.new(digest_bits=256, data=bytecode_)
    if k.digest()[-4] == len(bytecode):
        print(bytecode_.hex(), k.hexdigest(), hex(len(bytecode)))
        break
