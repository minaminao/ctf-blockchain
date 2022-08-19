# CTF Blockchain問まとめ 🐈
過去CTFに出題されたBlockchain問のテーマ別まとめです。ネタバレに注意してください。

問題の並びは適当で難易度順やおすすめ順ではありません。

一部の問題はExploitを公開しています（例: [Ethernaut](src/Ethernaut/), [Paradigm CTF 2021](src/ParadigmCTF2021/)）。

何か間違い等あればissueかPRで教えて下さい。

| [English](README.md) | 日本語 |
| -------------------- | ------ |

---

**目次**
- Ethereum
  - Ethereum/コントラクトの基礎
  - EVMの仕様を利用したパズル
  - `tx.origin`の誤用
  - オンチェーンで生成する擬似乱数は予測可能
  - ERC-20の基礎
  - `delegatecall`を悪用したストレージ書き換え
  - `delegatecall`のコンテキスト不一致
  - 整数のオーバーフロー
  - コントラクトへの通常のEther送金が必ず実行できるとは限らない
  - `selfdestruct`によるコントラクトへの強制送金
  - コントラクトコール後に全ての処理が実行できるとは限らない
  - インターフェース/抽象コントラクトの関数への`view`/`pure`の指定忘れ
  - `view`関数は同じ値が返るとは限らない
  - `storage`,`memory`の設定ミス
  - トランザクションの追跡
  - ステートのReversing（コントラクトに秘密情報を含んではならない）
  - トランザクションのReversing
  - EVMバイトコードのReversing
  - EVMバイトコードゴルフ
  - Gas最適化
  - Re-entrancy Attack
  - フラッシュローンの基礎
  - スナップショット時のフラッシュローン実行による権利の大量獲得
  - プッシュ型フラッシュローンの返済のバイパス
  - AMMの価格計算アルゴリズムの穴をついた資金流出
  - 独自トークンを悪用した資金流出
  - オラクルの操作による資金流出（フラッシュローン無）
  - オラクルの操作による資金流出（フラッシュローン有）
  - Sandwich Attack
  - Same Nonce Attackによる秘密鍵の復元
  - アドレスの総当り
  - 公開鍵の復元
  - secp256k1における暗号化と復号
  - 秘密鍵が既知のウォレットが持つERC-20トークンをBot回避して奪取
  - 配列の長さを`2^256-1`にすることによる任意ストレージ書き換え（< Solidity 0.6.0）
  - コンストラクタがtypoでただの関数に（< Solidity 0.5.0）
  - 初期化されていないストレージポインタを利用したストレージ書き換え（< Solidity 0.5.0）
  - その他アドホックな脆弱性・手法
- Bitcoin
  - Bitcoinの基礎
  - Same Nonce Attackによる秘密鍵の復元
  - BitcoinのPoWデータベースを利用した他アプリケーションのPoWバイパス
- Solana
- その他ブロックチェーン関連
  - IPFS

---

## Ethereum

注意点
- 特定のバージョンで有効で最新のバージョンで有効でない場合は末尾にバージョンを記載。現状Solidityのみ該当。
- 表記ゆれ回避のため用語は可能な限りSolidityのキーワードで統一し、Ethereum Virtual Machine (EVM)のキーワードは最低限にする。

### Ethereum/コントラクトの基礎
- Ethereumの基礎、Solidityの基本的な[言語仕様](https://solidity-ja.readthedocs.io/)、コントラクトの基本的な操作方法について知っていれば解ける。

| 問題                                                             | 備考、キーワード        |
| ---------------------------------------------------------------- | ----------------------- |
| Capture The Ether: Deploy a contract                             | faucet                  |
| Capture The Ether: Call me                                       | コントラクトコール      |
| Capture The Ether: Guess the number                              | コントラクトコール      |
| Capture The Ether: Guess the secret number                       | `keccak256`             |
| [Ethernaut: 0. Hello Ethernaut](src/Ethernaut#0-hello-ethernaut) | コントラクトコール、ABI |
| [Ethernaut: 1. Fallback](src/Ethernaut#1-fallback)               | receive Ether関数       |
| [Paradigm CTF 2021: Hello](src/ParadigmCTF2021/)                 | コントラクトコール      |
| 0x41414141 CTF: sanity-check                                     | コントラクトコール      |
| 0x41414141 CTF: crackme.sol                                      | コード理解              |

### EVMの仕様を利用したパズル
- EVMの仕様を理解していれば解けるパズル系の問題。
- 特に脆弱性を利用したり攻撃手法を用いたりはしない。

| 問題                                                               | 備考、キーワード                                                 |
| ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| Capture The Ether: Guess the new number                            | `block.number`、`block.timestamp` (旧: `now`)                    |
| Capture The Ether: Predict the block hash                          | `blockhash` (旧: `block.blockhash`)                              |
| [Ethernaut: 13. Gatekeeper One](src/Ethernaut#13-gatekeeper-one)   | `msg.sender != tx.origin`、`gasleft().mod(8191) == 0`、型変換    |
| [Ethernaut: 14. Gatekeeper Two](src/Ethernaut#14-gatekeeper-two)   | `msg.sender != tx.origin`、`extcodesize`を0に                    |
| Cipher Shastra: Minion                                             | `msg.sender != tx.origin`、`extcodesize`を0に、`block.timestamp` |
| SECCON Beginners CTF 2020: C4B                                     | `block.number`                                                   |
| [Paradigm CTF 2021: Babysandbox](src/ParadigmCTF2021/Babysandbox/) | `staticcall`, `call`, `delegatecall`, `extcodesize`を0に         |
| Paradigm CTF 2021: Lockbox                                         | `ecrecover`、`abi.encodePacked`、`msg.data.length`               |
| [EthernautDAO: 6. (No Name)](src/EthernautDAO/NoName/)             | `block.number`, gas price war                                    |
| [fvictorio's EVM Puzzles](src/FvictorioEVMPuzzles/)                |                                                                  |

### `tx.origin`の誤用
- `tx.origin`はトランザクションの発行者のアドレスを指し、コントラクトコール元のアドレス（すなわち`msg.sender`）として使ってはならない。

| 問題                                                 | 備考、キーワード |
| ---------------------------------------------------- | ---------------- |
| [Ethernaut: 4. Telephone](src/Ethernaut#4-telephone) |                  |

### オンチェーンで生成する擬似乱数は予測可能
- プログラムであるコントラクトのバイトコードは公開されているため、オンチェーンで生成が完結する（オフチェーンの情報を利用せずステートだけを利用する）ような擬似乱数は容易に予測できる。
- 擬似乱数生成器のパラメータが全て公開されていると考えればいかに脆弱かわかる。
- 誰にも予測不可能な乱数を用いたい場合、乱数機能を持つ分散型オラクルを使用すれば良い。例えばVerifiable Random Function (VRF)を実装した[Chainlink VRF](https://docs.chain.link/docs/chainlink-vrf/)など。

| 問題                                                 | 備考、キーワード |
| ---------------------------------------------------- | ---------------- |
| Capture The Ether: Predict the future                |                  |
| [Ethernaut: 3. Coin Flip](src/Ethernaut#3-coin-flip) |                  |

### ERC-20の基礎
- [ERC-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)の仕様を理解していれば解ける。

| 問題                                                       | 備考、キーワード                      |
| ---------------------------------------------------------- | ------------------------------------- |
| [Ethernaut: 15. Naught Coin](src/Ethernaut#15-naught-coin) | `transfer`、`approve`、`transferFrom` |
| [Paradigm CTF 2021: Secure](src/ParadigmCTF2021)           | WETH                                  |

### `delegatecall`を悪用したストレージ書き換え
- `delegatecall`は呼び出し先の関数が呼び出し元コントラクトのストレージを書き換え可能であるため脆弱性の原因になりやすい。

| 問題                                                           | 備考、キーワード                                                                                    |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [Ethernaut: 6. Delegation](src/Ethernaut#6-delegation)         | 変数の書き換え                                                                                      |
| [Ethernaut: 16. Preservation](src/Ethernaut#16-preservation)   | ストレージの書き換え                                                                                |
| [Ethernaut: 24. Puzzle Wallet](src/Ethernaut#24-puzzle-wallet) | プロキシパターン                                                                                    |
| [Ethernaut: 25. Motorbike](src/Ethernaut#25-motorbike)         | プロキシパターン、[EIP-1967: Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967) |

### `delegatecall`のコンテキスト不一致
- `delegatecall`で呼ばれる関数は、呼び出し元コントラクトのコンテキストで実行されるが、その関数がコンテキストをしっかり考慮していないとバグが生まれる。

| 問題                                                      | 備考、キーワード        |
| --------------------------------------------------------- | ----------------------- |
| [EthernautDAO: 3. CarMarket](src/EthernautDAO/CarMarket/) | `address(this)`の不使用 |

### 整数のオーバーフロー	
- 例えば`uint`の変数の値が`0`のとき`1`引くと算術オーバーフローする。
- Solidity v0.8.0から算術オーバフローを検出し、リバートするようになった。
- それ以前のバージョンでは[SafeMathライブラリ](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol)を使うことでチェックできる。

| 問題                                         | 備考、キーワード |
| -------------------------------------------- | ---------------- |
| Capture The Ether: Token sale                | 掛け算           |
| Capture The Ether: Token whale               | 引き算           |
| [Ethernaut: 5. Token](src/Ethernaut#5-token) | 引き算           |

### コントラクトへの通常のEther送金が必ず実行できるとは限らない
- 宛先アドレスへ必ず通常のEther送金（`.send()`や`.transfer()`）ができる前提でコントラクトを書いてはならない。
- 宛先がコントラクトでreceive Ether関数及びpayable fallback関数が無い場合、Etherの送金ができない。
- ただし、通常の送金方法ではなく、後述する`selfdestruct`を用いればそのようなコントラクトにも送金を強制できる。

| 問題                                       | 備考、キーワード |
| ------------------------------------------ | ---------------- |
| [Ethernaut: 9. King](src/Ethernaut#9-king) |                  |

### `selfdestruct`によるコントラクトへの強制送金
- コントラクトにreceive Ether関数及びpayable fallback関数が無いならばEtherを受け取らないことが保証されているわけではない。
- あるコントラクトが`selfdestruct`を行う際にそのコントラクトが持つEtherを他のコントラクトあるいはEOAに送金でき、この`selfdestruct`による送金は宛先コントラクトにreceive Ether関数及びpayable fallback関数が無くても強制的に送金できる（この送金はそれら関数のチェックを受けない）。
- 所持するEtherが`0`である前提でアプリケーションを作るとバグになる。

| 問題                                         | 備考、キーワード |
| -------------------------------------------- | ---------------- |
| Capture The Ether: Retirement fund           |                  |
| [Ethernaut: 7. Force](src/Ethernaut#7-force) |                  |

### コントラクトコール後に全ての処理が実行できるとは限らない
- `call`先でループや再帰によりガスが大量に消費され、残りの処理のガスが足りなくなる場合がある。
- Solidity v0.8.0まではゼロ除算や`assert(false)`などでもガスを消費し切れていた。

| 問題                                             | 備考、キーワード |
| ------------------------------------------------ | ---------------- |
| [Ethernaut: 20. Denial](src/Ethernaut#20-denial) |                  |

### インターフェース/抽象コントラクトの関数への`view`/`pure`の指定忘れ
- 関数に`view`,`pure`を指定したと思い込み、その関数を実行してもステートが変更されないという前提でアプリケーションを設計するとバグになる。

| 問題                                                 | 備考、キーワード |
| ---------------------------------------------------- | ---------------- |
| [Ethernaut: 11. Elevator](src/Ethernaut#11-elevator) |                  |

### `view`関数は同じ値が返るとは限らない
- `view`関数はステートを読み込めるためステートをもとに条件分岐が可能であり同じ値が返るとは限らない。

| 問題                                         | 備考、キーワード |
| -------------------------------------------- | ---------------- |
| [Ethernaut: 21. Shop](src/Ethernaut#21-shop) |                  |

### `storage`,`memory`の設定ミス
- `storage`,`memory`を適切に設定しなかった場合に古い値を参照してしまったり書き換えが起こらなかったりして脆弱性になる。

| 問題                 | 備考、キーワード                                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| N1CTF 2021: BabyDefi | [Cover Protocolの無限ミントバグ](https://coverprotocol.medium.com/12-28-post-mortem-34c5f9f718d4)とフラッシュローンの組み合わせ |

### トランザクションの追跡
- トランザクションの処理の流れを追うだけでも様々な情報が手に入れられる。
- Etherscanなどのブロックチェーンエクスプローラーが便利。

| 問題                                                 | 備考、キーワード                       |
| ---------------------------------------------------- | -------------------------------------- |
| [Ethernaut: 17. Recovery](src/Ethernaut#17-recovery) | デプロイしたコントラクトアドレスの紛失 |

### ステートのReversing（コントラクトに秘密情報を含んではならない）
- ステート（とコントラクトのバイトコード）は公開されるため、private変数も含めて全ての変数は読むことが可能。
- private変数は他のコントラクトから直接読めないことを保証しているだけであり、ブロックチェーン外の存在である我々は読める。
- トランザクションによって秘密情報を与えている場合、トランザクションを読むことでも解ける。

| 問題                                                          | 備考、キーワード |
| ------------------------------------------------------------- | ---------------- |
| Capture The Ether: Guess the random number                    |                  |
| [Ethernaut: 8. Vault](src/Ethernaut#8-vault)                  |                  |
| [Ethernaut: 12. Privacy](src/Ethernaut#12-privacy)            |                  |
| Cipher Shastra: Sherlock                                      |                  |
| 0x41414141 CTF: secure enclave                                |                  |
| [EthernautDAO: 1. PrivateData](src/EthernautDAO/PrivateData/) |                  |

### トランザクションのReversing
- トランザクションの中身あるいはトランザクションによってどうステートが変化したかをReversingする。Etherscanが便利。

| 問題                                            | 備考、キーワード |
| ----------------------------------------------- | ---------------- |
| [darkCTF: Secret Of The Contract](src/DarkCTF/) |                  |

### EVMバイトコードのReversing
- コードが全部あるいは一部だけ与えられていないコントラクトをReversingする。
- デコンパイラ（[panoramix](https://github.com/eveem-org/panoramix)や[ethervm.io](https://ethervm.io/decompile)など）やディスアセンブラ（[ethersplay](https://github.com/crytic/ethersplay)など）を駆使する。

| 問題                             | 備考、キーワード                |
| -------------------------------- | ------------------------------- |
| Incognito 2.0: Ez                | 平文で保持                      |
| Real World CTF 3rd: Re:Montagy   | Jump Oriented Programming (JOP) |
| 0x41414141 CTF: Crypto Casino    |                                 |
| Paradigm CTF 2021: Babyrev       |                                 |
| Paradigm CTF 2021: JOP           | Jump Oriented Programming (JOP) |
| 34C3 CTF: Chaingang              |                                 |
| Blaze CTF 2018: Smart? Contract  |                                 |
| DEF CON CTF Qualifier 2018: SAG? |                                 |
| pbctf 2020: pbcoin               |                                 |

### EVMバイトコードゴルフ
- オペコードの数やバイトコードの長さに制限がある問題。

| 問題                                                       | 備考、キーワード                                                                   |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Ethernaut: 18. MagicNumber](src/Ethernaut#18-magicnumber) |                                                                                    |
| [Paradigm CTF 2021: Rever](src/ParadigmCTF2021/Rever/)     | 回文判定。さらにそのバイトコードを反転させたコードも回文判定できなくてはならない。 |
| [Huff Challenge: Challenge #1](src/HuffChallenge)          |

### Gas最適化
- 使用できるgasに制限がある問題。

| 問題                                              | 備考、キーワード |
| ------------------------------------------------- | ---------------- |
| [Huff Challenge: Challenge #2](src/HuffChallenge) |                  |

### Re-entrancy Attack
- コントラクトAのある関数内に別のコントラクトBとのインタラクションやBへのEther送金が含まれている場合、一時的にBに制御が移る。
- この制御の中で、BはAにコールできるため、Aがその関数の実行途中にコールされない前提の設計になっているとバグになる。
- 例えば、BがAにデポジットしたEtherを引き出す`withdraw`関数を実行したとき、Ether送金でBに制御が移り`withdraw`関数途中にBがもう一度Aの`withdraw`関数を実行する、といったことが可能になる。単純に2回呼び出すなら限度額以上の引き出しができない設計になっていても、`withdraw`関数の途中に`withdraw`関数が実行されるとその限度額のチェックをバイパスできる設計になってしまっている場合がある。
- Re-entrancy Attackを防ぐためにはChecks-Effects-Interactionsパターンを利用する。

| 問題                                                                | 備考、キーワード |
| ------------------------------------------------------------------- | ---------------- |
| Capture The Ether: Token bank                                       |                  |
| [Ethernaut: 10. Re-entrancy](src/Ethernaut#10-re-entrancy)          |                  |
| Paradigm CTF 2021: Yield Aggregator                                 |                  |
| HTB University CTF 2020 Quals: moneyHeist                           |                  |
| [EthernautDAO: 4. VendingMachine](src/EthernautDAO/VendingMachine/) |                  |

### フラッシュローンの基礎
- フラッシュローン（Flash Loan）は、トランザクションの終了までに借りた資産が返却される限り、無担保で資産を借入できるローンのこと。借り手はトランザクション内であれば借りた資産をどのように扱っても良い。
- 大きな額の資産を動かすことで、DeFiアプリケーションの資金を掠め取る攻撃や、ガバナンスへの参加権を大量に獲得する攻撃が可能。
- フラッシュローンを用いてオラクルの値を歪める攻撃への対策は分散型オラクルを利用すること。

| 問題                                   | 備考、キーワード                                                                                                      |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Damn Vulnerable DeFi: 1. Unstoppable   | 単一トークンのシンプルなフラッシュローン。トークンを直接送信すると破綻。                                              |
| Damn Vulnerable DeFi: 2. Naivereceiver | `flashLoan`関数に`borrower`を指定できるがreceiver側はTX送信者を認証していないためreceiverの資金を手数料として排出可能 |
| Damn Vulnerable DeFi: 3. Truster       | コールのターゲットをトークンにし自分宛にapproveすることでトークンを奪取可能                                           |
| Damn Vulnerable DeFi: 4. Sideentrance  | 各ユーザーがdeposit/withdrawできるフラッシュローン。フラッシュローン時にdepositを行うとノーコストでdepositが可能。    |

### スナップショット時のフラッシュローン実行による権利の大量獲得
- ロジックがスナップショット時のトークン残高を利用して権利を配布するもので、悪意あるユーザーのトランザクションがスナップショットのトリガーになりえる場合、フラッシュローンを利用することで大量の権利を獲得できる。
- ロック期間を設けることでこの攻撃を回避できる。

| 問題                                 | 備考、キーワード                                 |
| ------------------------------------ | ------------------------------------------------ |
| Damn Vulnerable DeFi: 5. Therewarder | 預けたトークン残高に応じて報酬のトークンを獲得   |
| Damn Vulnerable DeFi: 6. Selfie      | 預けたトークン残高に応じてガバナンス参加権を獲得 |

### プッシュ型フラッシュローンの返済のバイパス
- フラッシュローンにはプッシュ型とプル型があり、プッシュ型はUniswapやAave v1、プル型はAave v2やdYdXに代表される。
- [EIP-3156: Flash Loans](https://eips.ethereum.org/EIPS/eip-3156)はプル型。

| 問題                       | 備考、キーワード                                     |
| -------------------------- | ---------------------------------------------------- |
| Paradigm CTF 2021: Upgrade | トークンに実装されたレンディング機能を用いてバイパス |

### AMMの価格計算アルゴリズムの穴をついた資金流出
- Automated Market Maker (AMM)の価格計算アルゴリズムに穴があると単純な取引の組み合わせで資金流出が可能。

| 問題                                       | 備考、キーワード |
| ------------------------------------------ | ---------------- |
| [Ethernaut: 22. Dex](src/Ethernaut#22-dex) |                  |

### 独自トークンを悪用した資金流出
- アプリケーションが任意のトークンを利用できること自体は悪いことではないが攻撃ベクタになりうる。
- また、任意のトークンを利用できない前提のホワイトリスト設計であるのに、任意のトークンを利用できてしまうバグがあると資金流出の原因になりうる。

| 問題                                               | 備考、キーワード |
| -------------------------------------------------- | ---------------- |
| [Ethernaut: 23. Dex Two](src/Ethernaut#23-dex-two) |                  |

### オラクルの操作による資金流出（フラッシュローン無）
- オラクルの値を故意に歪め、そのオラクルを参照しているアプリケーションの資金を流出させる。

| 問題                                 | 備考、キーワード                                                                      |
| ------------------------------------ | ------------------------------------------------------------------------------------- |
| Paradigm CTF 2021: Broker            | Uniswapの価格を歪めてその価格を参照するレンディングプラットフォームのポジションを清算 |
| Damn Vulnerable DeFi: 7. Compromised | オフチェーンで秘密鍵流出＆オラクルの操作                                              |

### オラクルの操作による資金流出（フラッシュローン有）
- フラッシュローンを利用することでオラクルの値を故意に歪め、そのオラクルを参照しているアプリケーションの資金を流出させる。
- フラッシュローンにより多額の資金を動かすことができるためオラクルを歪めやすく被害が大きくなりやすい。

| 問題                            | 備考、キーワード                                                                         |
| ------------------------------- | ---------------------------------------------------------------------------------------- |
| Damn Vulnerable DeFi: 8. Puppet | Uniswap V1の価格を歪めてその価格を参照するレンディングプラットフォームからトークンを流出 |

### Sandwich Attack
- 他者の大きな取引トランザクションを自分のトランザクションで挟んで（サンドイッチして）フロントランニングする攻撃。
- 例えば、他者のトークンAを売りBを買う取引があったら、その前にAを売りBを買うトランザクションを入れ、後に同量のBを売りAを買うトランザクションを入れることで、最終的に攻撃者はAの量が増加し利益を得られる。
- 一般的にこのような「マイナーが生成するブロックに含むトランザクションを選択・挿入・並び替えすることで得られる収益」のことをMiner Extractable Value (MEV)という。最近はMaximal Extractable Valueとも呼ばれる。

| 問題                                              | 備考、キーワード                      |
| ------------------------------------------------- | ------------------------------------- |
| [Paradigm CTF 2021: Farmer](src/ParadigmCTF2021/) | COMP→WETH→DAIのトレードをサンドイッチ |


### Same Nonce Attackによる秘密鍵の復元
- 一般的にSame Nonce Attackは楕円曲線DSAにおいて異なるメッセージに対して同一のnonceを利用している場合に有効な攻撃で、秘密鍵が求まってしまう。
- Ethereumの文脈においてはトランザクションの署名に用いているnonceが同じになってしまっている。

| 問題                                                 | 備考、キーワード |
| ---------------------------------------------------- | ---------------- |
| Capture The Ether: Account Takeover                  |                  |
| [Paradigm CTF 2021: Babycrypto](src/ParadigmCTF2021) |                  |


### アドレスの総当り
- ブルートフォースすればアドレスの先頭や末尾を特定の値にできる。

| 問題                              | 備考、キーワード |
| --------------------------------- | ---------------- |
| Capture The Ether: Fuzzy identity |                  |

### 公開鍵の復元
- アドレスは公開鍵を`keccak256`ハッシュにかけたものであり、アドレスから公開鍵を復元することはできない。
- トランザクションが一つでも送信されていれば、そこから公開鍵を逆算できる。
- 具体的にはトランザクションをシリアライズすることでRecursive Length Prefix (RLP)エンコードを施したデータに対して`keccak256`を適用した値と、署名`(r,s,v)`から復元できる。

| 問題                          | 備考、キーワード |
| ----------------------------- | ---------------- |
| Capture The Ether: Public Key |                  |

### secp256k1における暗号化と復号

| 問題                      | 備考、キーワード                                             |
| ------------------------- | ------------------------------------------------------------ |
| 0x41414141 CTF: Rich Club | 鍵ペアを自分で用意。与えた公開鍵で暗号化されたフラグを復号。 |

### 秘密鍵が既知のウォレットが持つERC-20トークンをBot回避して奪取
- 秘密鍵がわかっているウォレットがERC-20トークン持っていてEtherを持っていない場合、通常そのERC-20トークンを回収するにはまずそのウォレットにEtherを送って次にERC-20トークンを`transfer`する必要がある。
- しかし、このとき送られたEtherを即時に回収するbotが動いていると、単純にEtherを送ってもそのEtherが回収されてしまう。
- Flashbotsのバンドルトランザクションを使用するか、トークンが[EIP-2612 permit](https://eips.ethereum.org/EIPS/eip-2612)に対応しているなら`permit`して`transferFrom`すれば良い。

| 問題                                                                      | 備考、キーワード |
| ------------------------------------------------------------------------- | ---------------- |
| [EthernautDAO: 5. EthernautDaoToken](src/EthernautDAO/EthernautDaoToken/) |                  |

### 配列の長さを`2^256-1`にすることによる任意ストレージ書き換え（< Solidity 0.6.0）
- 例えば、配列の長さを負に算術オーバーフローして`2^256-1`にすることで任意のストレージが書き換え可能になる。
- オーバーフローを起因とする必要はない。
- v0.6.0から`length`プロパティはread-onlyになった。

| 問題                                                       | 備考、キーワード |
| ---------------------------------------------------------- | ---------------- |
| Capture The Ether: Mapping                                 |                  |
| [Ethernaut: 19. Alien Codex](src/Ethernaut#19-alien-codex) |                  |
| Paradigm CTF 2021: Bank                                    |                  |

### コンストラクタがtypoでただの関数に（< Solidity 0.5.0）
- v0.4.22より前のバージョンだとコンストラクタをコントラクトと同名の関数で定義していたため、コンストラクタ名をtypoするとただの関数になってしまいバグになることがあった。
- v0.5.0からはこの仕様が廃止され`constructor`キーワードを用いなければならない。

| 問題                                             | 備考、キーワード |
| ------------------------------------------------ | ---------------- |
| Capture The Ether: Assume ownership              |                  |
| [Ethernaut: 2. Fallout](src/Ethernaut#2-fallout) |                  |

### 初期化されていないストレージポインタを利用したストレージ書き換え（< Solidity 0.5.0）
- v0.5.0からは初期化されていないストレージ変数は禁止されるようになったためこのバグは起こり得ない。

| 問題                           | 備考、キーワード                                                                       |
| ------------------------------ | -------------------------------------------------------------------------------------- |
| Capture The Ether: Donation    |                                                                                        |
| Capture The Ether: Fifty years |                                                                                        |
| ~~Ethernaut: Locked~~          | [削除された](https://forum.openzeppelin.com/t/ethernaut-locked-with-solidity-0-5/1115) |

### その他アドホックな脆弱性・手法
| 問題                                                              | 備考、キーワード                                                                                  |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| [Paradigm CTF 2021: Bouncer](src/ParadigmCTF2021/Bouncer/)        | バッチ処理に必要な資金が単一処理と同じになってしまっている                                        |
| Paradigm CTF 2021: Market                                         | Eternal Storageパターンのキーのズレを利用して、あるフィールドの値を別のフィールドの値と認識させる |
| [EthernautDAO: 2. WalletLibrary](src/EthernautDAO/WalletLibrary/) | m-of-nマルチシグウォレットのmとnを変更可能                                                        |

## Bitcoin
注意点
- トランザクションモデルがUnspent Transaction Output (UTXO)であるBitcoinの亜種の問題も含む。

### Bitcoinの基礎
| 問題                                   | 備考、キーワード            |
| -------------------------------------- | --------------------------- |
| TsukuCTF 2021: genesis                 | Genesisブロック             |
| WORMCON 0x01: What's My Wallet Address | Bitcoinアドレス、RIPEMD-160 |

### Same Nonce Attackによる秘密鍵の復元
- 実際にバグがあり[RFC6979](https://datatracker.ietf.org/doc/html/rfc6979)を用いて修正済み。
- https://github.com/daedalus/bitcoin-recover-privkey

| 問題                                      | 備考、キーワード |
| ----------------------------------------- | ---------------- |
| [darkCTF: Duplicacy Within](src/DarkCTF/) |                  |

### BitcoinのPoWデータベースを利用した他アプリケーションのPoWバイパス
- BitcoinではSHA-256のハッシュ値の先頭に0が連なることをProof of Work (PoW)としているが、他のアプリケーションでも同じような設計をした場合にBitcoinの過去のPoW結果から条件に合うものを選ぶことでPoW時間を大幅に短縮できるケースがある。

| 問題                        | 備考、キーワード |
| --------------------------- | ---------------- |
| Dragon CTF 2020: Bit Flip 2 | 64ビットのPoW    |


## Solana

| 問題                          | 備考、キーワード                                                 |
| ----------------------------- | ---------------------------------------------------------------- |
| ALLES! CTF 2021: Secret Store | `solana`,`spl-token`コマンドを駆使して条件に合うようトークン操作 |
| ALLES! CTF 2021: Legit Bank   |                                                                  |
| ALLES! CTF 2021: Bugchain     |                                                                  |
| ALLES! CTF 2021: eBPF         | eBPFのReversing                                                  |

## その他ブロックチェーン関連
- ブロックチェーンではないがエコシステムの一部になっているもの。

### IPFS
- InterPlanetary File System (IPFS)。

| 問題                                   | 備考、キーワード            |
| -------------------------------------- | --------------------------- |
| TsukuCTF 2021: InterPlanetary Protocol | アドレスはlowercaseのBase32 |
