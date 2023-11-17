from erever.secp256k1 import G, n


s = 55683273551335019790586685050782793822601528258733375343877633243398613931099
d = 1

k = pow(2, -1, n)
half_G = G * k
r = int(half_G.x)

# s = (m + r * d) * pow(k, -1, n) % n
m = (s * k - r * d) % n

print(hex(r)[2:].zfill(64))
print(hex(m)[2:].zfill(64))
