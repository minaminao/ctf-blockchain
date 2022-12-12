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

## Challenge #4
https://twitter.com/huff_language/status/1583894073487654913

>Huff challenge #4 🗿🍾⛳️:
Write the minimal OR most efficient Huff smart contract that reverses all calldata that it receives

```
forge test --match-contract Challenge4Test -vvvv
```

## Challenge #5
https://twitter.com/huff_language/status/1586401774927126528

> Huff challenge #5 🗿🍾⛳️ : We got another fun one for ya
Implement the most gas efficient contract that returns true if the calldata represents a signed message from the sender of the tx. 
If it isn't, do something that makes the transaction run out of gas.

```
forge test --match-contract Challenge5Test -vvvv
```
