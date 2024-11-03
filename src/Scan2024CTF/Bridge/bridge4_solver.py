import subprocess
from bridge4_txlist import txlist
from tqdm import tqdm

registered_operators = [
    "0x0725EdCF85A4A4eB9820cE1caE2C3E1D380C6555",
    "0x2B217F0205a52A6B9E02B92a98EafB8234EbA4A4",
    "0x4FfA987E473FDB6852844a8A567611c93be8814c",
    "0x78c3F80436dF8b55c462F3d3651e411F90069691",
    "0x7F84691a6d962EC493fd4a2b36156d8BDEC7AbAC",
    "0x8bbdb96633064Dc564760b404866e768283573b1",
    "0x95Eb34fFD1Ff53430d3ac353E876428c5B88C5Ec",
    "0xa8c37372480e04A5D6b0403871b177146F91f065",
    "0xE6B1B6e65dF8CbaA7fD25200504325cC5B394ff2",
    "0xFcC7b4F4fe4A40ebC8948fC9005D2788E4c7919F",
]

for txhash in tqdm(txlist):
    cmd = f"cast run {txhash} --quick"
    result = subprocess.check_output(cmd, shell=True).decode("utf-8")
    for line in result.split("\n"):
        if "[Return]" not in line:
            continue
        if any(
            operator.lower() in line.lower().replace("0x000000000000000000000000", "0x")
            for operator in registered_operators
        ):
            break
        print(txhash)
        exit(0)
