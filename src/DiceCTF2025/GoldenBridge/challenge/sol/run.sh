for sig in INT QUIT HUP TERM ALRM USR1; do
  trap 'pkill -P $$' $sig
done

mkdir /tmp/sol

solana-test-validator --quiet \
  --reset --ledger /tmp/sol/ledger --limit-ledger-size 1000 \
  --clone TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA --clone ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL --url mainnet-beta \
  --faucet-sol 201 &

# wait for solana-test-validator to come up
while ! timeout 1 bash -c "bash -c 'echo > /dev/tcp/localhost/8899' 2> /dev/null"; do
  sleep 1
done

solana config set --url localhost

# generate three accounts: bridge (the $BBL mint authority), bbl (the $BBL mint account), and the player
# fund both bridge and the player with 100 
BRIDGE_KEYPAIR=/tmp/sol/bridge.json
BRIDGE_PUBKEY=$(solana-keygen new --no-bip39-passphrase --force -o "$BRIDGE_KEYPAIR" | sed -n 's/^pubkey: //p')
printf "$BRIDGE_PUBKEY" > /tmp/sol/bridge-pubkey.txt
solana --keypair $BRIDGE_KEYPAIR airdrop 100

BBL_KEYPAIR=/tmp/sol/bbl.json
BBL_PUBKEY=$(solana-keygen new --no-bip39-passphrase --force -o "$BBL_KEYPAIR" | sed -n 's/^pubkey: //p')
printf "$BBL_PUBKEY" > /tmp/sol/bbl-pubkey.txt

PLAYER_KEYPAIR=/tmp/sol/player.json
PLAYER_PUBKEY=$(solana-keygen new --no-bip39-passphrase --force -o "$PLAYER_KEYPAIR" | sed -n 's/^pubkey: //p')
printf "$PLAYER_PUBKEY" > /tmp/sol/player-pubkey.txt
solana --keypair $PLAYER_KEYPAIR airdrop 100

# deploy $BBL, and make an associated token account for the bridge
spl-token create-token --fee-payer "$BRIDGE_KEYPAIR" --mint-authority "$BRIDGE_KEYPAIR" --decimals 0 "$BBL_KEYPAIR"
spl-token create-account --fee-payer "$BRIDGE_KEYPAIR" --owner "$BRIDGE_PUBKEY" "$BBL_PUBKEY"

touch /tmp/sol/done

wait
