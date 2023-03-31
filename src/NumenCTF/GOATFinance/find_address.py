from web3.auto import w3

# calculate the check sum address
mid = "71fA690CcCDC285E3Cb6d5291EA935cfdfE4E0"
for i in range(0x100):
    address = w3.to_checksum_address("0x" + mid + hex(i)[2:].zfill(2))
    if address.startswith("0x" + mid):
        print(address)
    address = w3.to_checksum_address("0x" + hex(i)[2:].zfill(2) + mid)
    if address.endswith(mid):
        print(address)
