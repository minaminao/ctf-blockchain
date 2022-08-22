# Huff Challenge

## Challenge #1
https://twitter.com/huff_language/status/1559658361469095936

>Huff challenge #1:
Write the minimal Huff code for a contract that returns the current block number if called

```
forge test --match-contract Challenge1Test -vvvv
```

## Challenge #2
https://twitter.com/huff_language/status/1560015751989211136

>Huff challenge #2 (getting slightly harder but still going easy):
Write the most efficient possible Huff contract that returns true (1) if the input is an even number and false (0) if it is odd.

```
forge test --match-contract Challenge2Test -vvvv
```

## Challenge #3
https://twitter.com/huff_language/status/1560750533811376128

>Huff Challenge #3 (a bit harder... and much more real)
Exploit this contract and steal the Ether inside. It's deployed at `0xae7e201257f3f7918e9e8f2f3de998e3d75f7a1d` and has 0.1 ETH for you :)
Interface: deposit(), withdraw(), and setWithdrawer(address)

```
forge test --match-contract Challenge3Test -vvvv
```