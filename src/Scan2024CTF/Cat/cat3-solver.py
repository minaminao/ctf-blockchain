recovery_key = "ee24ea0267c90806e0928d432e506ca7f10c5c40cac6c5c79c142d295eeca63d5343414e32303234"

recovery_key_values = [
    "5343414e32303234",
    "4c495855534145434150",
    "039a6cd58a84dfda002182d337751e6cbe38a714dffadd1b7bc37c58c82b973b1e",
    "035c161281edc46c35c542c625314f69f7bda684440e345ce741afeac6b19f3ad7"
]
recovery_key_values.sort(reverse=True)

print(f"SCAN2024{{[{",".join(recovery_key_values)}]:{recovery_key}}}")