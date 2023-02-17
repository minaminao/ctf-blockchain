# QuillHash CTF 2022 Solutions

Here's the link to the challenges page: https://quillctf.super.site/challenges. I highly recommend to solve the problems before checking the solutions!

---

**Table of Contents**
- [QuillHash CTF 2022 Solutions](#quillhash-ctf-2022-solutions)
  - [Road closed:](#road-closed)
  - [VIP Bank:](#vip-bank)
  - [Confidential Hash:](#confidential-hash)
  - [SafeNFT:](#safenft)


---

## Road closed:
https://quillctf.super.site/challenges/quillctf-challenges/road-closed

**Objective**:
- Become the owner of the contract
- Change the value of hacked to true

Goerli link: https://goerli.etherscan.io/address/0xd2372eb76c559586be0745914e9538c17878e812
 
```
forge test --match-contract QuillCTF1Solved -vvvv
```


## VIP Bank:
https://quillctf.super.site/challenges/quillctf-challenges/vip-bank

**Objective:**
At any cost, lock the VIP user balance forever into the contract.

Goerli Link: https://goerli.etherscan.io/address/0x28e42e7c4bda7c0381da503240f2e54c70226be2

```
forge test --match-contract QuillCTF3Solved -vvvv
```

## Confidential Hash:
https://quillctf.super.site/challenges/quillctf-challenges/ctf02

**Objective**:
-Find the keccak256 hash of `aliceHash` and `bobHash`. 

Goerli link: https://goerli.etherscan.io/address/0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66
 
```
forge test --match-contract QuillCTF2Solved -vvvv
```

## SafeNFT:
https://quillctf.super.site/challenges/quillctf-challenges/bulletproof-nft

**Objective**:
Claim multiple NFTs for the price of one.

Goerli Link: https://goerli.etherscan.io/address/0xf0337cde99638f8087c670c80a57d470134c3aae

```
forge test --match-contract SafeNFTSolved -vvvv
```
