x = bytes.fromhex("6bca38432e686d0a2ab98d1cab5f21998075ffef811b6bb03d52812fa9a8f752")

for mask in range(1 << len(x)):
    t = 0
    c = 0
    for i in range(len(x)):
        if (mask >> i) & 1:
            t += x[len(x) - 1 - i]
            c += 1
    if t % 0x0539 == 0x0309 and c == 0x11:
        print(bin(mask), mask, t, c)
        break
