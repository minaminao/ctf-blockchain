# MapleCTF 2022: Maplebacoin
```
receive(), my favourite function on the EVM. I added it to a token...can't go wrong right?

The live challenge is really slow. why? because blockchain. so you probably want to run this locally for your own sanity.

Note: The actual live infrastructure is different than the provided, however, the solidity code, testnet configuration, and solve.js should be the same. This mimics the real world experience, where a dev environment is more forgiving in certain ways compared to the real blockchain.
```

**Exploit**
```
forge test --match-contract MapleBaCoinExploitTest
```