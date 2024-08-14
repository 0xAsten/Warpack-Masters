#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.world.address')

export DUMMY_STSTEM_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-dummy_system" and .kind == "DojoContract").address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo dummy system : $DUMMY_STSTEM_ADDRESS
echo "---------------------------------------------------------------------------"


sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,2,0x426572746965,2,5,1,4,2,0,2,2,2,0,23,5,2,0,8,4,4,0,11,4,3,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,3,0x4a6f646965,1,7,1,4,2,0,2,2,2,0,15,2,2,0,13,4,4,0,8,5,4,0,24,3,2,0,9,4,2,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,4,0x526f626572746965,0,8,1,4,2,0,2,2,2,0,2,2,4,0,4,4,5,0,14,5,2,0,30,4,2,0,16,2,2,0,12,2,4,90 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,5,0x486172746965,2,9,1,4,2,0,2,2,2,0,2,2,4,0,23,5,2,0,24,2,4,0,24,3,4,0,19,2,2,0,20,4,4,0,11,4,3,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,6,0x426172646965,1,9,1,4,2,0,2,2,2,0,3,4,1,0,15,4,3,0,15,5,3,0,24,5,1,0,17,2,2,0,13,4,2,0,5,4,1,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,7,0x546172746965,0,11,1,4,2,0,2,2,2,0,2,2,0,0,2,2,4,0,3,4,1,0,25,2,0,0,15,3,0,0,27,3,2,0,16,2,4,0,12,4,1,0,10,5,4,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,8,0x4b6f6f6c6965,2,11,1,4,2,0,2,2,2,0,2,2,4,0,3,4,5,0,23,4,3,0,23,5,3,0,19,2,2,0,27,2,4,0,20,3,4,0,11,3,5,0,13,5,2,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,9,0x476f6f626965,1,11,1,4,2,0,2,2,2,0,2,2,4,0,3,4,5,0,17,2,4,0,18,4,3,0,13,2,2,0,13,2,3,0,24,3,2,0,20,4,2,0,11,5,2,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,10,0x476f6f646965,0,10,1,4,2,0,2,2,2,0,2,2,4,0,2,2,0,0,3,4,5,0,22,2,0,0,19,2,4,0,28,4,2,0,20,4,4,0,11,4,5,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS update_prefine_dummy -c 1,11,0x5a6970706965,2,14,1,4,2,0,2,2,2,0,2,2,4,0,2,2,0,0,3,4,1,0,3,4,5,0,23,2,3,0,23,3,3,0,24,2,2,90,19,4,1,0,28,5,4,0,20,4,5,0,16,2,0,0,15,4,3,0 --wait --rpc-url $STARKNET_RPC_URL
