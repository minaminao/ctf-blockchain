for sig in INT QUIT HUP TERM ALRM USR1; do
  trap 'pkill -P $$' $sig
done

# ====================================
# setup script stolen from hxpctf 2025
# ====================================

mkdir /tmp/eth

ACCOUNTS_PATH=/tmp/eth/accounts.json
PLAYER_INFO_PATH=/tmp/eth/player.json

# generate two accounts
#  [0] deployer
#  [1] player
cast wallet new --number=2 --json > "${ACCOUNTS_PATH}"
DEPLOYER_ADDRESS=$(jq -r ".[0].address" < "${ACCOUNTS_PATH}")
DEPLOYER_PRIVATE_KEY=$(jq -r ".[0].private_key" < "${ACCOUNTS_PATH}")

PLAYER_ADDRESS=$(jq -r ".[1].address" < "${ACCOUNTS_PATH}")
PLAYER_PRIVATE_KEY=$(jq -r ".[1].private_key" < "${ACCOUNTS_PATH}")

GETH_IPC=/tmp/eth/geth.ipc

geth --dev --verbosity 2 \
  --ipcpath "$GETH_IPC" --http --http.api="eth,web3,net" --http.vhosts '*' --http.addr "0.0.0.0" \
  --datadir /tmp/eth/ --cache 128 &

# wait for geth to come up
for i in {1..5}; do
  sleep 2
  if cast block-number > /dev/null; then
    break
  fi
done

# fund the accounts
FUND_JS="const tx1 = eth.sendTransaction({from: eth.accounts[0], to: '${DEPLOYER_ADDRESS}', value: web3.toWei(100, 'ether')})"
FUND_JS="${FUND_JS}; const tx2 = eth.sendTransaction({from: eth.accounts[0], to: '${PLAYER_ADDRESS}', value: web3.toWei(100, 'ether')})"
geth attach --exec "${FUND_JS}" "$GETH_IPC"

# ensure that the accounts were funded
SUCCESS=0
for i in {1..5}; do
  # echo "balance check $i"
  sleep 2
  BALANCE1=$(cast balance "${DEPLOYER_ADDRESS}")
  BALANCE2=$(cast balance "${PLAYER_ADDRESS}")
  if [ "$BALANCE1" != "0" ] && [ "$BALANCE2" != "0" ]; then
    SUCCESS=1
    break
  fi
done

if [ "$SUCCESS" != "1" ]; then
  echo "Could not confirm balance of deployer"
  exit 1
fi

# perform the deployment
DEPLOYMENT_INFO_PATH=/tmp/eth/deployment.json
forge create src/Setup.sol:Setup --private-key "${DEPLOYER_PRIVATE_KEY}" --broadcast --json > "${DEPLOYMENT_INFO_PATH}"

SETUP_ADDR=$(jq -r '.deployedTo' < "${DEPLOYMENT_INFO_PATH}")
jq --null-input --arg SETUP "${SETUP_ADDR}" --arg ADDR "${PLAYER_ADDRESS}" --arg KEY "${PLAYER_PRIVATE_KEY}" '. + {"setup": $SETUP, "address": $ADDR, "private_key": $KEY}' > "${PLAYER_INFO_PATH}"

touch /tmp/eth/done

wait
