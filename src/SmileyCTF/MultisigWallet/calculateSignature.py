curve_order = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141

s1 = -0x6f326347e65ae8b25830beee7f3a4374f535a8f6eedb5221efba0f17eceea9a9 % curve_order
s2 = -0x694430205a6b625cc8506e945208ad32bec94583bf4ec116598708f3b65e4910 % curve_order
s3 = -0x6c0c845b7a88f5a2396d7f75b536ad577bbdb27ea8c03769a958b2a9d67117d2 % curve_order

print(f"s1: {hex(s1)}")
print(f"s2: {hex(s2)}")
print(f"s3: {hex(s3)}")