#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-master/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 1,4,4 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 4,4,3 --wait --rpc-url $RPC_URL 
