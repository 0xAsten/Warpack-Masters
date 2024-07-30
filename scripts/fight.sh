#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

export SYSTEM_ACTION_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::fight::fight_system" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo systen action : $SYSTEM_ACTION_ADDRESS
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $SYSTEM_ACTION_ADDRESS fight --wait --rpc-url $STARKNET_RPC_URL \
	--account-address 0x24564a69b21a2683b82b0211644577213644b1d832b50b444df2c40e0f5253b \
	--private-key 0x7957b76cecb7995b071c16120243268a64e6fa8cf5310d30400b56d7de97adc
