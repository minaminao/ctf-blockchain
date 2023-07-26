# https://pypi.org/project/rlp/
# https://pyrlp.readthedocs.io/en/latest/
import rlp
from Crypto.Hash import keccak
from eth_account import Account
from eth_account._utils.signing import to_standard_v
from rlp.sedes import Binary, big_endian_int, binary

raw_tx = bytes.fromhex("f87080843b9aca0083015f90946b477781b0e68031109f21887e6b5afeaaeb002b808c5468616e6b732c206d616e2129a0a5522718c0f95dde27f0827f55de836342ceda594d20458523dd71a539d52ad7a05710e64311d481764b5ae8ca691b05d14054782c7d489f3511a7abf2f5078962")

"""
>>> rlp.decode(raw_tx)
[b'', b';\x9a\xca\x00', b'\x01_\x90', b'kGw\x81\xb0\xe6\x801\x10\x9f!\x88~kZ\xfe\xaa\xeb\x00+', b'', b'Thanks, man!', b')', b"\xa5R'\x18\xc0\xf9]\xde'\xf0\x82\x7fU\xde\x83cB\xce\xdaYM E\x85#\xddq\xa59\xd5*\xd7", b'W\x10\xe6C\x11\xd4\x81vKZ\xe8\xcai\x1b\x05\xd1@Tx,}H\x9f5\x11\xa7\xab\xf2\xf5\x07\x89b']
"""

class Transaction(rlp.Serializable):
    fields = [
        ('nonce', big_endian_int),
        ('gas_price', big_endian_int),
        ('gas', big_endian_int),
        ('to', Binary.fixed_length(20, allow_empty=True)),
        ('value', big_endian_int),
        ('data', binary),
        ('v', big_endian_int),
        ('r', big_endian_int),
        ('s', big_endian_int),
    ]

tx = rlp.decode(raw_tx, Transaction)

"""
>>> tx
Transaction(nonce=0, gas_price=1000000000, gas=90000, to=b'kGw\x81\xb0\xe6\x801\x10\x9f!\x88~kZ\xfe\xaa\xeb\x00+', value=0, data=b'Thanks, man!', v=41, r=74776771311019569939017621593480679160618399812524181808306514788568607828695, s=39381076589634547203973423246354256320472887426210737547826636053693505964386)
"""

tx_hash = keccak.new(digest_bits=256, data=raw_tx).hexdigest()

# v = CHAIN_ID * 2 + 35 or v = CHAIN_ID * 2 + 36
chain_id = (tx.v - 35) // 2
message = rlp.encode([tx.nonce, tx.gas_price, tx.gas, tx.to, tx.value, tx.data, chain_id, 0, 0])
message_hash = keccak.new(digest_bits=256, data=message).digest()
v_standard = to_standard_v(tx.v)
signature_obj = Account._keys.Signature(vrs=(v_standard, tx.r, tx.s))
addr = Account._recover_hash(message_hash, vrs=(tx.v, tx.r, tx.s))
public_key = signature_obj.recover_public_key_from_msg_hash(message_hash)

print(f"{tx_hash=}")
print(f"{chain_id=}")
print(f"{addr=}")
print(f"{public_key=}")
