## Overview
- Stake: ETH と WETH をステークできるコントラクト
- `allowance(address,address)` と `transferFrom(address,address,uint256)` が、`abi.encodeWithSelector` を用いて呼び出されている

## Solution
- `allowance(address,address)` と `transferFrom(address,address,uint256)` が成功したかどうかがチェックされていない
- `transferFrom` が失敗するが、`StakeWETH` が成功するようなトランザクションを投げれば良い
- 条件 `_instance.balance != 0 && instance.totalStaked() > _instance.balance && instance.UserStake(_player) == 0 && instance.Stakers(_player)` を満たすために被害者コントラクトを用意する
