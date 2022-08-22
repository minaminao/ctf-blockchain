# from API requests
flag_fragments = ["0x504354467b64306e", "0x375f7930755f3130", "0x76335f66316e6431", "0x6e395f3064347935", "0x5f316e5f345f6337", "0x667d"]

flag = b""
for fragment in flag_fragments:
    flag += bytes.fromhex(fragment[2:])

print(flag)