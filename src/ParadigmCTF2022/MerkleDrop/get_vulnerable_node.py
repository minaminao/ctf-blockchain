import json

import web3
from Crypto.Hash import keccak

tree = json.load(open("challenge/tree.json"))
claims = tree['claims']

for account, v in claims.items():
    index = hex(v['index'])
    proofs = v['proof']
    amount = v['amount']
    assert len(proofs) == 6

    k = keccak.new(digest_bits=256)
    index = ("00" * 32 + index[2:])[-32 * 2:]
    account = ("00" * 20 + account[2:])[-20 * 2:]
    amount = ("00" * 12 + amount[2:])[-12 * 2:]
    k.update(bytes.fromhex(index + account + amount))
    node = ("00" * 32 + k.hexdigest())[32 * 2:]

    for i, proof in enumerate(proofs):

        proofElement = ("00" * 32 + proof[2:])[32 * 2:]

        if node < proofElement:
            index_account_amount = node + proofElement
        else:
            index_account_amount = proofElement + node

        index = "0x" + index_account_amount[:32 * 2]
        account = web3.Web3.toChecksumAddress("0x" + index_account_amount[32 * 2:32 * 2 + 20 * 2])
        amount = "0x" + index_account_amount[32 * 2 + 20 * 2:]

        maxi = 75000 * 10**18
        if int(amount, 16) <= maxi:
            print("============")
            print()
            print(f"bytes32[] memory merkleProof = new bytes32[]({len(proofs[i+1:])});")

            for j, p in enumerate(proofs[i + 1:]):
                print(f"merkleProof[{j}] = {p};")

            print(f"merkleDistributor.claim({index}, {account}, {amount}, merkleProof);")
            print()
            print("------------")
            print()
            print("amount           = ", hex(int(amount, 16)))
            print("remaining amount = ", hex(maxi - int(amount, 16)))
            print()
            print("============")
