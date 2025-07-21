- CTF期間中はインフラが壊れていて取り組めなかった

## Overview
- 添付ファイルとして Setup.sol と Locker.sol が与えられる
- Locker.sol に Setup コントラクトの実態である SetupLocker コントラクトがあるからこれを読む
- SetupLocker の deploy 関数は誰でも呼び出せるが、インスタンスが返るだけで、インスタンスアドレスは `challenge` にセットされない
    - （これは作問ミスだったらしい）
    - ![](assets/image.png)
- Locker はマルチシグウォレットで、deploy 関数呼び出し時に指定した 3 つの署名によって Locker が初期化される
- validateMultiSig 関数を呼び出すと署名が正しいか検証されるが、一度使用した署名は利用できない
- 当然、deploy 時に使った署名も使用できない
- また、その署名に結びつくコントローラーの秘密鍵はわからない

## Solution
- 前提: Ethereum の ECDSA 署名において楕円曲線は secp256k1 を使っている
    - あるメッセージにおいて、`(v, r, s)` と `(v', r, -s mod n)` の二種類の署名が存在する
    - ここで、`n` は secp256k1 曲線の order
    - また、トランザクションは EIP-2 によって、order の半分より大きいと無効になるが、`ECRECOVER` は禁止されていない
- 3つの署名の `(v', r, -s mod n)` を生成し、`distribute` を実行することで署名検証をパスし、 `isSolved` を `true` にできる
