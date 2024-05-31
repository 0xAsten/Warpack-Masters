#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${RPC_URL:?Environment variable RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

# export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')
export ACTIONS_ADDRESS='0x591fe4c5c0987dfd20e14e82875494699eda1e47c68c98801df329424e1bb03'


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# id, property, value
# 0. name 1. width 2. height 3. price 4. damage 5. armor 6. chance 7. cooldown 8. heal 9. rarity
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 2,5,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 3,7,5 --wait --rpc-url $RPC_URL 

