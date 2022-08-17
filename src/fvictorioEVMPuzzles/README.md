# fvictorio's EVM Puzzles

https://github.com/fvictorio/evm-puzzles

EVMバイトコードが与えられる。
このEVMバイトコードが正常に終了するようなvalueやcalldataを組むパズル。
`REVERT`させずに`STOP`を実行させれば良い。

**Table of Contents**
- [Puzzle 1](#puzzle-1)
- [Puzzle 2](#puzzle-2)
- [Puzzle 3](#puzzle-3)
- [Puzzle 4](#puzzle-4)
- [Puzzle 5](#puzzle-5)
- [Puzzle 6](#puzzle-6)
- [Puzzle 7](#puzzle-7)
- [Puzzle 8](#puzzle-8)
- [Puzzle 9](#puzzle-9)
- [Puzzle 10](#puzzle-10)

## Puzzle 1

### 問題
```
00      34      CALLVALUE
01      56      JUMP
02      FD      REVERT
03      FD      REVERT
04      FD      REVERT
05      FD      REVERT
06      FD      REVERT
07      FD      REVERT
08      5B      JUMPDEST
09      00      STOP
```

### Writeup
`08`の`JUMPDEST`に飛ばす。

```
? Enter the value to send: 8
```

## Puzzle 2

### 問題
```
00      34      CALLVALUE
01      38      CODESIZE
02      03      SUB
03      56      JUMP
04      FD      REVERT
05      FD      REVERT
06      5B      JUMPDEST
07      00      STOP
08      FD      REVERT
09      FD      REVERT
```

### Writeup
`CODESIZE`は10であり、`06`の`JUMPDEST`に飛ばしたいから、valueは`10 - 6 = 4`。
```
? Enter the value to send: 4
```

## Puzzle 3

### 問題
```
00      36      CALLDATASIZE
01      56      JUMP
02      FD      REVERT
03      FD      REVERT
04      5B      JUMPDEST
05      00      STOP
```

### Writeup
`04`の`JUMPDEST`に飛ばしたいから4バイトのcalldataを作る。

```
? Enter the calldata: 0x00010203
```

## Puzzle 4

### 問題
```
00      34      CALLVALUE
01      38      CODESIZE
02      18      XOR
03      56      JUMP
04      FD      REVERT
05      FD      REVERT
06      FD      REVERT
07      FD      REVERT
08      FD      REVERT
09      FD      REVERT
0A      5B      JUMPDEST
0B      00      STOP
```

### Writeup
`0A`(10)の`JUMPDEST`に飛ばしたい。`CODESIZE`は12であるから、valueは`12 ^ 10 = 6`。

```
? Enter the value to send: 6
```

## Puzzle 5

### 問題
```
00      34          CALLVALUE
01      80          DUP1
02      02          MUL
03      610100      PUSH2 0100
06      14          EQ
07      600C        PUSH1 0C
09      57          JUMPI
0A      FD          REVERT
0B      FD          REVERT
0C      5B          JUMPDEST
0D      00          STOP
0E      FD          REVERT
0F      FD          REVERT
```

### Writeup
`value * value`が`0100`(256)になれば良い。

```
? Enter the value to send: 16
```

## Puzzle 6

### 問題
```
00      6000      PUSH1 00
02      35        CALLDATALOAD
03      56        JUMP
04      FD        REVERT
05      FD        REVERT
06      FD        REVERT
07      FD        REVERT
08      FD        REVERT
09      FD        REVERT
0A      5B        JUMPDEST
0B      00        STOP
```

### Writeup
`CALLDATALOAD`は指定したインデックスから32バイトをスタックに読み込む。

```
? Enter the calldata: 0x000000000000000000000000000000000000000000000000000000000000000A
```

## Puzzle 7

### 問題
```
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      80        DUP1
04      37        CALLDATACOPY
05      36        CALLDATASIZE
06      6000      PUSH1 00
08      6000      PUSH1 00
0A      F0        CREATE
0B      3B        EXTCODESIZE
0C      6001      PUSH1 01
0E      14        EQ
0F      6013      PUSH1 13
11      57        JUMPI
12      FD        REVERT
13      5B        JUMPDEST
14      00        STOP
```

### Writeup
スタックの変化:
```
00      36        CALLDATASIZE  [calldatasize]
01      6000      PUSH1 00      [0x00, calldatasize]
03      80        DUP1          [0x00, 0x00, calldatasize]
04      37        CALLDATACOPY  []
05      36        CALLDATASIZE  [calldatasize]
06      6000      PUSH1 00      [0x00, calldatasize]
08      6000      PUSH1 00      [0x00, 0x00, calldatasize]
0A      F0        CREATE        []
0B      3B        EXTCODESIZE   [extcodesize]
0C      6001      PUSH1 01      [0x01, extcodesize]
0E      14        EQ            [result]
0F      6013      PUSH1 13      [0x13, result]
11      57        JUMPI         []
12      FD        REVERT
13      5B        JUMPDEST
14      00        STOP
```

`EXTCODESIZE`の結果、すなわちアカウントのコードのサイズが1になれば良い。
`CREATE`によって実行される初期化コードのリターンデータがアカウントのコードになるからHuff言語で、
```
0x01
0x00
RETURN
```
であれば良い。

```
? Enter the calldata: 0x60016000F3
```

## Puzzle 8

### 問題
```
00      36        CALLDATASIZE
01      6000      PUSH1 00
03      80        DUP1
04      37        CALLDATACOPY
05      36        CALLDATASIZE
06      6000      PUSH1 00
08      6000      PUSH1 00
0A      F0        CREATE
0B      6000      PUSH1 00
0D      80        DUP1
0E      80        DUP1
0F      80        DUP1
10      80        DUP1
11      94        SWAP5
12      5A        GAS
13      F1        CALL
14      6000      PUSH1 00
16      14        EQ
17      601B      PUSH1 1B
19      57        JUMPI
1A      FD        REVERT
1B      5B        JUMPDEST
1C      00        STOP
```

### Writeup
`CREATE`されるコントラクトの`CALL`結果が`00`、すなわち失敗すれば良い。
`REVERT`を使わなくても、適当に命令を失敗させればいい。

デプロイするコントラクト（Huff）:
```
ADD
```
バイトコードは`0x01`になる。

初期化コード（Huff）:
```
0x01 0x00 MSTORE
0x01 0x1f RETURN
```
メモリが`00 ... 00 01`になっているためoffsetに`0x1f`を指定する。
バイトコードは`0x60016000526001601ff3`になる。

```
? Enter the calldata: 0x60016000526001601fF3
```

## Puzzle 9

### 問題
```
00      36        CALLDATASIZE
01      6003      PUSH1 03
03      10        LT
04      6009      PUSH1 09
06      57        JUMPI
07      FD        REVERT
08      FD        REVERT
09      5B        JUMPDEST
0A      34        CALLVALUE
0B      36        CALLDATASIZE
0C      02        MUL
0D      6008      PUSH1 08
0F      14        EQ
10      6014      PUSH1 14
12      57        JUMPI
13      FD        REVERT
14      5B        JUMPDEST
15      00        STOP
```

### Writeup
次の条件を満たせばよい。
- `3 < calldatasize`
- `calldatasize * callvalue == 8`

`calldatasize = 4`, `callvalue = 2`となるようにする。

```
? Enter the value to send: 2
? Enter the calldata: 0x00010203
```

## Puzzle 10

### 問題
```
00      38          CODESIZE
01      34          CALLVALUE
02      90          SWAP1
03      11          GT
04      6008        PUSH1 08
06      57          JUMPI
07      FD          REVERT
08      5B          JUMPDEST
09      36          CALLDATASIZE
0A      610003      PUSH2 0003
0D      90          SWAP1
0E      06          MOD
0F      15          ISZERO
10      34          CALLVALUE
11      600A        PUSH1 0A
13      01          ADD
14      57          JUMPI
15      FD          REVERT
16      FD          REVERT
17      FD          REVERT
18      FD          REVERT
19      5B          JUMPDEST
1A      00          STOP
```

### Writeup

`09`から`14`までのスタックの変化を追う。
```
09      36          CALLDATASIZE    [calldatasize]
0A      610003      PUSH2 0003      [0x0003, calldatasize]
0D      90          SWAP1           [calldatasize, 0x0003]
0E      06          MOD             [calldatasize % 0x0003]
0F      15          ISZERO          [calldatasize % 0x0003 == 0]
10      34          CALLVALUE       [callvalue, calldatasize % 0x0003 == 0]
11      600A        PUSH1 0A        [0x0A, callvalue, calldatasize % 0x0003 == 0]
13      01          ADD             [0x0A + callvalue, calldatasize % 0x0003 == 0]
14      57          JUMPI           []
```

`calldatasize % 0x0003 == 0`を満たせば、`0x0A + callvalue`に飛べるとわかる。

よって次の条件を満たせば良い。
- `codesize > callvalue`
- `calldatasize % 0x0003 == 0`
- `0x0A + callvalue == 0x19`

```
? Enter the value to send: 15
? Enter the calldata: 0x000102
```