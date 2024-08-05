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


# Generated item commands
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 2 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 3 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 4 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 5 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 6 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 7 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 8 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 9 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 10 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 11 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 12 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 13 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS prefine_dummy -c 14 --wait --rpc-url $STARKNET_RPC_URL
