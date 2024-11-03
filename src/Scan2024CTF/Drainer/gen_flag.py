import re
import web3

with open("trace.txt") as f:
    blocks = f.read().split("--")

    attacker_to_tokens = {}

    for block in blocks:
        lines = block.split("\n")
        for line in lines:
            # <address>::transfer(<address>
            m = re.search(r"(0x[a-fA-F0-9]{40})::transfer\((0x[a-fA-F0-9]{40})", line)
            if m is not None:
                m1 = web3.Web3.to_checksum_address(m.group(1))
                m2 = web3.Web3.to_checksum_address(m.group(2))
                print(m1, m2)
                attacker_to_tokens[m2] = attacker_to_tokens.get(m2, []) + [
                    web3.Web3.to_checksum_address(m1)
                ]
            m = re.search(
                r"(0x[a-fA-F0-9]{40})::transferFrom\(.+, (0x[a-fA-F0-9]{40})", line
            )
            if m is not None:
                m1 = web3.Web3.to_checksum_address(m.group(1))
                m2 = web3.Web3.to_checksum_address(m.group(2))
                print(m1, m2)
                attacker_to_tokens[m2] = attacker_to_tokens.get(m2, []) + [
                    web3.Web3.to_checksum_address(m1)
                ]
            if line.startswith("!"):
                m1, m2 = line[1:].split(",")
                m1 = web3.Web3.to_checksum_address(m1)
                m2 = web3.Web3.to_checksum_address(m2)
                print(m1, m2)
                attacker_to_tokens[m2] = attacker_to_tokens.get(m2, []) + [
                    web3.Web3.to_checksum_address(m1)
                ]

inferno_drainer = "0xaA862F977d6916A1e89E856FC11Fd99a2F2fAbF8"
first = "0x864eCC548dF6a49F4f69cd6106aDB7A6Dd80f765"
sub_groups = []

tmp = sorted(attacker_to_tokens.items(), key=lambda x: len(set(x[1])), reverse=True)
for attacker, tokens in tmp:
    print(attacker, len(set(tokens)))

for attacker, tokens in attacker_to_tokens.items():
    for token in tokens:
        if token in attacker_to_tokens[first]:
            print(attacker, len(set(tokens)))
            if attacker not in [inferno_drainer, first]:
                sub_groups.append(attacker)
            break

print(
    "SCAN2024{"
    + inferno_drainer
    + ":"
    + first
    + ":["
    + ",".join(sorted(sub_groups, key=lambda k: int(k, 16), reverse=True))
    + "]}"
)
