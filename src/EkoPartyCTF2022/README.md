# EKOPARTY CTF 2022

## Byte

Setting for [erever](https://github.com/minaminao/erever):

```
$ export EREVER_RPC_URL=https://rpc.ankr.com/eth_goerli
```

The code of this contract is not publicly available, so read its assembly:

```
$ erever -c 0xa882B173A95BFdb4FC2f7d547AfEAA677f0E60bF
0x00: PUSH1 0x80
0x02: PUSH1 0x40
0x04: MSTORE
0x05: CALLVALUE
0x06: DUP1
0x07: ISZERO
0x08: PUSH1 0x0f
0x0a: JUMPI
0x0b: PUSH1 0x00
0x0d: DUP1
0x0e: REVERT
0x0f: JUMPDEST
0x10: POP
0x11: PUSH1 0x04
0x13: CALLDATASIZE
0x14: LT
0x15: PUSH1 0x28
0x17: JUMPI
0x18: PUSH1 0x00
0x1a: CALLDATALOAD
0x1b: PUSH1 0xe0
0x1d: SHR
0x1e: DUP1
0x1f: PUSH4 0xdffeadd0
0x24: EQ
(snip)
```

The function selector `0xdffeadd0` is pushed by `PUSH4`, so extract all function selectors:

```
$ erever -c 0xa882B173A95BFdb4FC2f7d547AfEAA677f0E60bF | grep PUSH4
0x1f: PUSH4 0xdffeadd0
```

There appears to be only one function.

Check the signature of the function selector:

```
$ cast 4 0xdffeadd0
main()
```

It looks good to analyze the function `main()` only.

Trace the execution of the function:
```
$ erever -c 0xa882B173A95BFdb4FC2f7d547AfEAA677f0E60bF --trace --calldata 0xdffeadd0
```

`JUMP` destinations are not `JUMPDEST`, so the error occurs. 
The stack after executing `0x91: SWAP1` just before the error is `[0x6f, 0x97, 0x30, 0x63, 0x33, 0x74, 0x79, 0x62, 0x7b, 0x4f, 0x4b, 0x45, 0x00, 0x00, 0x33, 0xdffeadd0]`, which seems to be ASCII codes.

Decode the stack:
```
$ erever -c 0xa882B173A95BFdb4FC2f7d547AfEAA677f0E60bF --trace --calldata 0xdffeadd0 --decode-stack
(snip)
0x91: SWAP1(0x97, ..., 0x6f)
	stack	[0x6f, 0x97, 0x30, 0x63, 0x33, 0x74, 0x79, 0x62, 0x7b, 0x4f, 0x4b, 0x45, 0x00, 0x00, 0x33, 0xdffeadd0]
		[o, ., 0, c, 3, t, y, b, {, O, K, E, ., ., 3, ....]
0x92: JUMP(pc:0x6f)Traceback (most recent call last):
(snip)
```

The fragments of the flag were output.
I guessed that if the destinations of `JUMP`/`JUMPI` are not `JUMPDEST` and no error occurs, the flag would be output.

Modify the erever to do so:

```py
case "JUMP":
    # assert OPCODES[context.bytecode[input[0]]][0] == "JUMPDEST"
    next_i = input[0]
case "JUMPI":
    # assert OPCODES[context.bytecode[input[0]]][0] == "JUMPDEST"
    if input[1] != 0:
        next_i = input[0]
```

Run the same command and `grep }`:

![](https://i.gyazo.com/09a65b5082e09eadce4b9dd4c1190fad.png)

`EKO{byt3c0o0od3}` was accepted.

Flag: `EKO{byt3c0o0od3}`

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

The code of this contract is not publicly available, so read its assembly:
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