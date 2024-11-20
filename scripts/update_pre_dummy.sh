#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifest_dev.json | jq -r '.world.address')

export DUMMY_STSTEM_ADDRESS=$(cat ./manifest_dev.json | jq -r '.contracts[] | select(.tag == "Warpacks-dummy_system").address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo dummy system : $DUMMY_STSTEM_ADDRESS
echo "---------------------------------------------------------------------------"


sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,0,0x4e6f6f626965,1,5,1,4,2,0,0,2,2,2,0,0,6,2,2,0,0,5,4,4,0,0,8,5,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
