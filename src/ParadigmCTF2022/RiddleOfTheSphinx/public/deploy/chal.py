import cairo_sandbox

from pathlib import Path

from starknet_py.net import AccountClient
from starknet_py.contract import Contract
from starkware.python.utils import to_bytes

async def deploy(client: AccountClient, player_address: int) -> int:
    print("[+] deploying riddle")
    riddle_deployment = await Contract.deploy(
        client=client,
        compiled_contract=Path("compiled/riddle.cairo").read_text(),
        constructor_args=[],
    )
    await riddle_deployment.wait_for_acceptance()

    return riddle_deployment.deployed_contract.address


async def checker(client: AccountClient, riddle_contract: Contract, player_address: int) -> bool:
    solution = (await riddle_contract.functions["solution"].call()).solution

    return to_bytes(solution).lstrip(b"\x00") == b"man"

cairo_sandbox.run_launcher([
    cairo_sandbox.new_launch_instance_action(deploy),
    cairo_sandbox.new_kill_instance_action(),
    cairo_sandbox.new_get_flag_action(checker),
])