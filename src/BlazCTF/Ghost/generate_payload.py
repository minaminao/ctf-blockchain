payload = []

PADD3 = 0 # pointer += 3
PSUB2 = 1 # pointer -= 2
VINC = 2 # *pointer++
NOP = 4
PADD1G = [PADD3, PSUB2]

# 1
payload += [VINC] * VINC + PADD1G

# 3
payload += [VINC] * PADD3 + PADD1G
payload += [VINC] * PSUB2 + PADD1G
for _ in range(3):
    payload += [VINC] * VINC + PADD1G

# 3
payload += [VINC] * PADD3 + PADD1G
payload += [VINC] * PSUB2 + PADD1G
for _ in range(3):
    payload += [VINC] * VINC + PADD1G

# 7
payload += [VINC] * PADD3 + PADD1G
payload += [VINC] * PSUB2 + PADD1G
for _ in range(7):
    payload += [VINC] * VINC + PADD1G

POINTER = 0x14
payload += [PSUB2] * (POINTER // 2)

PAYLOAD_LEN = 0x100
assert len(payload) <= PAYLOAD_LEN

for i in range(PAYLOAD_LEN - len(payload)):
    payload.append(NOP)

payload_s = ""
for i in range(PAYLOAD_LEN):
    payload_s += hex(payload[i])[2:].zfill(32 * 2)
print(payload_s, end="")
