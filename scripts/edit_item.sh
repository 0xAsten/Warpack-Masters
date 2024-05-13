#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# id, property, value
# 0. name 1. width 2. height 3. price 4. damage 5. armor 6. chance 7. cooldown 8. heal 9. rarity
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 2,5,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS edit_item -c 3,7,5 --wait --rpc-url $RPC_URL 

