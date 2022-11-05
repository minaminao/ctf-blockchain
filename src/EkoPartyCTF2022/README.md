# EKOPARTY CTF 2022

## Piggy
[Exploit](Piggy/PiggyExploit.s.sol)

## Greedy
[Exploit](Greedy/GreedyExploit.s.sol)

## SmartRev
>This contract compute the flag in memory. Can you see it anyway?
Contract
`0xD7CD577416EBE8375e419e6EF7256a68d07C1592`

Setting for [erever](https://github.com/minaminao/erever):

```
$ export EREVER_RPC_URL=https://rpc.ankr.com/eth_goerli
```

The code of this contract is not publicly available, so read its assembly quickly:
```
$ erever -c 0xD7CD577416EBE8375e419e6EF7256a68d07C1592
0x000: PUSH1 0x80
0x002: PUSH1 0x40
0x004: MSTORE
0x005: CALLVALUE
0x006: DUP1
0x007: ISZERO
0x008: PUSH2 0x0010
0x00b: JUMPI
0x00c: PUSH1 0x00
0x00e: DUP1
0x00f: REVERT
0x010: JUMPDEST
0x011: POP
0x012: PUSH1 0x04
0x014: CALLDATASIZE
0x015: LT
0x016: PUSH2 0x002b
0x019: JUMPI
0x01a: PUSH1 0x00
0x01c: CALLDATALOAD
0x01d: PUSH1 0xe0
0x01f: SHR
0x020: DUP1
0x021: PUSH4 0xb6b22c28
0x026: EQ
(snip)
```

The function selector `0xb6b22c28` is pushed by `PUSH4`, so extract all function selectors:

```
$ erever -c 0xD7CD577416EBE8375e419e6EF7256a68d07C1592 | grep PUSH4
0x021: PUSH4 0xb6b22c28
```

There appears to be only one function.

Check the signature of the function selector:
```
$ cast 4 0xb6b22c28

```

The result is nothing, so it looks good to analyze the function `0xb6b22c28` only.

Trace the execution of the function:
```
$ erever -c 0xD7CD577416EBE8375e419e6EF7256a68d07C1592 --trace --calldata 0xb6b22c28
```

![](https://i.gyazo.com/05c0c1350073e03aaeeafc8b4b83f7a1.png)

The flag is printed out.

Flag: `EKO{0xe0fa604321dcdf006976a959c0125d5fe74b22a5}`