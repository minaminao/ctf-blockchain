# Paradigm CTF 2022 Writeup

## RANDOM

Test:
```
forge test -vvvvv --match-contract RandomExploitTest
```

Exploit:
```
forge script RandomExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

Flag: `PCTF{IT5_C7F_71M3}`

## SOURCECODE

Compile the quine:
```
huffc -r Quine.huff
```

Test:
```
forge test -vvvvv --match-contract SourceCodeExploitTest
```

Exploit:
```
forge script SourceCodeExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

Flag: `PCTF{QUiNE_QuiNe_qU1n3}`
