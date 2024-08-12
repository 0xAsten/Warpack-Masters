#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"


sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS update_prefine_dummy -c 1,19,0x446f74746965,0,21,1,4,2,0,2,2,2,0,2,2,4,0,2,4,5,0,2,6,1,0,2,6,3,0,2,4,0,0,2,2,0,0,2,6,5,0,22,2,0,0,29,4,0,0,14,6,1,0,25,7,1,0,28,2,4,0,27,3,4,0,26,6,4,0,19,4,3,0,11,4,5,0,11,4,6,0,10,5,5,0,20,5,6,0 --wait --rpc-url $STARKNET_RPC_URL
