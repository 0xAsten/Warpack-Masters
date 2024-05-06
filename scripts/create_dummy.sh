#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-masters-v2/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS create_dummy --wait --rpc-url $RPC_URL \
	--account-address 0x24564a69b21a2683b82b0211644577213644b1d832b50b444df2c40e0f5253b \
	--private-key 0x7957b76cecb7995b071c16120243268a64e6fa8cf5310d30400b56d7de97adc
