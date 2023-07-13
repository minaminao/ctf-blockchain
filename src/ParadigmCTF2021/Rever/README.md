# Paradigm CTF 2021: Rever

## 概要
バイトコードサイズが100以下の回文判定器を作る。
ただし、そのバイトコードを反転させたバイトコードも回文判定できなくてはならない。

## Writeup

まず、普通に回文判定器を作る。

次のようなアルゴリズムが思い浮かぶ。
- calldataを反転する
- xorを取る
- ゼロかどうかを返す

これをHuffで実装してコンパイルすると37バイトになった。
`push 0x00`の代わりに`returndatasize`を使ったり、Huffのデフォルトのラベル機能を使わずラベルを1バイトにしたりして、できるだけサイズを小さくなるようにした。

```js
returndatasize  // [0]
calldataload    // [calldata]
returndatasize  // [i <- 0, calldata]

// for example:
// calldata = "aba" = 0x61626100...
// calldatasize = 3

label03:

    dup1            // [i, i, calldata]
    calldatasize    // [calldatasize, i, i, calldata]
    eq              // [calldatasize == i, i, calldata]
    0x1a            // [label1a, calldatasize == 0, i, calldata]    using PUSH1 not PUSH2
    jumpi           // [i, calldata]

    dup2            // [calldata, i, calldata]
    dup2            // [i, calldata, i, calldata]
    0x01            // [1, i, calldata, i, calldata]
    calldatasize    // [calldatasize, 1, i, calldata, i, calldata]
    sub             // [calldatasize - 1, i, calldata, i, calldata]
    sub             // [s <- calldatasize - 1 - i, calldata, i, calldata]
    byte            // [calldata[s], i, calldata]
    dup2            // [i, calldata[s], i, calldata]
    mstore8         // [i, calldata]
    0x01            // [1, i, calldata]
    add             // [i <- i + 1, calldata]
    0x03            // [label03, i, calldata]
    jump            // [i, calldata]

label1a:
    pop             // [calldata]
    returndatasize  // [0, calldata]
    mload           // [memory[0], calldata]
    xor             // [memory[0] ^ calldata]
    iszero          // [isPalindrome]
    returndatasize mstore
    msize returndatasize return
```

この判定器のバイトコードを反転させたものをくっつければ良い。
`37 * 2 = 74`バイトなので余裕で100バイト以下の条件を満たす。

実装は、まず回文判定器単体を`-r`オプションでコンパイルして、
```solidity
function compilePalindromeChecker() public returns (bytes memory) {
    string[] memory cmds = new string[](3);
    cmds[0] = "huffc";
    cmds[1] = "src/ParadigmCTF2021/Rever/PalindromeChecker.huff";
    cmds[2] = "-r";
    bytes memory bytecode = vm.ffi(cmds);
    return bytecode;
}
```

`Setup.sol`から借用した`flip`関数を使って、
```solidity
function flip(bytes memory a) private pure returns (bytes memory) {
    bytes memory b = new bytes(a.length);
    for (uint256 i = 0; i < a.length; i++) {
        b[b.length - i - 1] = a[i];
    }
    return b;
}
```

`bytes.concat`で反転させたものをくっつけてデプロイ。

```solidity
bytecode = bytes.concat(bytecode, flip(bytecode));
```

ちなみに公式のYul想定解は47 bytesだったからHuffで10 bytes短縮できたことになる。
