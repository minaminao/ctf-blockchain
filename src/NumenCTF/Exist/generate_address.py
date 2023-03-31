from web3.auto import w3

while True:
    account = w3.eth.account.create()
    private_key = account.key
    address = account.address

    if "5a54" in address:
        print("Private Key: ", private_key.hex())
        print("Address: ", address)
        break
