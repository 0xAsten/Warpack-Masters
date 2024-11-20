#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifest_dev.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifest_dev.json | jq -r '.contracts[] | select(.tag == "Warpacks-actions").address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# id, property, value
# 0. name 1. width 2. height 3. price 4. damage 5. armor 6. chance 7. cooldown 8. heal 9. rarity
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 2,5,1 --wait --rpc-url $STARKNET_RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 3,7,5 --wait --rpc-url $STARKNET_RPC_URL 

