#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.world.address')

export ITEM_STSTEM_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-item_system" and .kind == "DojoContract").address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo item system : $ITEM_STSTEM_ADDRESS
echo "---------------------------------------------------------------------------"

# Generated item commands
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 1,0x4261636b7061636b,4,2,3,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 2,0x5061636b,4,2,2,4,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 3,0x5361746368656c,4,2,1,3,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 4,0x506f756368,4,1,1,2,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 5,0x48657262,3,1,1,2,0,0,100,0,1,0,0,1,1,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 6,0x446167676572,1,1,2,2,3,0,90,4,1,0,0,0,0,0,0,0,0,0,0,20 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 7,0x53776f7264,1,1,3,2,5,0,80,5,1,0,0,0,0,0,0,0,0,0,0,30 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 8,0x5370696b65,3,1,1,2,0,0,100,0,1,0,0,0,0,1,1,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 9,0x536869656c64,3,2,2,3,0,0,100,0,1,15,1,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 10,0x48656c6d6574,3,1,1,3,0,0,50,0,1,3,2,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 11,0x4865616c696e6720506f74696f6e,3,1,1,4,0,0,100,0,2,0,0,2,1,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 12,0x4c6561746865722041726d6f72,3,2,3,5,0,0,100,0,2,35,1,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 13,0x506f69736f6e,3,1,1,5,0,0,100,0,2,0,0,0,0,0,0,2,1,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 14,0x4175676d656e7465642053776f7264,1,1,3,6,8,0,80,5,2,0,0,0,0,0,0,0,0,0,0,30 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 15,0x4175676d656e74656420446167676572,1,1,2,6,5,0,90,4,2,0,0,0,0,0,0,0,0,0,0,20 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 16,0x5370696b6520536869656c64,3,2,2,7,0,0,75,0,2,0,0,0,0,2,2,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 17,0x506c6167756520466c6f776572,3,2,2,12,0,0,80,4,3,0,0,0,0,0,0,3,3,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 18,0x4d61696c2041726d6f72,3,2,3,12,0,0,100,0,3,75,1,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 19,0x4275636b6c6572,3,2,2,8,0,0,60,0,2,10,2,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 20,0x4d61676963205761746572,3,1,1,4,0,5,90,5,2,0,0,0,0,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 21,0x56616d70697269632041726d6f72,3,2,3,10,0,0,70,0,3,0,0,3,4,0,0,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 22,0x477265617473776f7264,1,2,4,8,20,0,70,7,2,0,0,0,0,0,0,0,0,0,0,60 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 23,0x426f77,2,1,3,6,10,0,90,7,2,0,0,0,0,0,0,0,0,0,0,25 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 24,0x43726f7373626f77,2,1,2,2,3,0,90,5,1,0,0,0,0,0,0,0,0,0,0,15 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 25,0x48616d6d6572,1,1,4,3,10,0,70,7,1,0,0,0,0,0,0,0,0,0,0,45 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 26,0x416d756c6574206f662046757279,3,1,1,7,0,0,75,0,2,0,0,0,0,0,0,0,0,2,2,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 27,0x52616765204761756e746c6574,3,1,2,4,0,0,65,0,1,0,0,0,0,0,0,0,0,1,4,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 28,0x4b6e696768742048656c6d6574,3,1,2,10,0,0,100,5,3,0,0,0,0,0,0,0,0,3,3,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 29,0x426c6164652041726d6f72,3,2,3,10,0,0,80,5,3,0,0,0,0,5,3,0,0,0,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c 30,0x436c7562,2,1,2,2,6,0,70,6,1,0,0,0,0,0,0,0,0,0,0,35 --wait --rpc-url $STARKNET_RPC_URL
