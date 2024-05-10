#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-masters-v2/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"


# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
# 358486078052 is Sword
# 91707909958756 is Shield
# 1468365686984687211050012787699566 is Healing Potion
# 75185137345906 Dagger
# name,width,height,price,damage,armor,chance,cooldown,heal,rarity

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 358486078052,1,3,2,4,0,80,5,0,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 91707909958756,2,2,2,0,1,90,0,0,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 1468365686984687211050012787699566,1,1,1,0,0,70,5,1,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 75185137345906,1,2,2,3,0,90,4,0,1 --wait --rpc-url $RPC_URL 