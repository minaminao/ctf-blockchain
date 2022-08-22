# Paradigm CTF 2022 Writeup

## SOURCECODE

Compile the quine:
```
huffc -r Quine.huff
```

Test:
```
forge test -vvvvv --match-contract SourceCodeExploitTest
```

Deploy:
```
forge script SourceCodeExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

flag: `PCTF{QUiNE_QuiNe_qU1n3}`
