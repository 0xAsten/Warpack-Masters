#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://0.0.0.0:5050";

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

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 358486078052,1,3,2,2,0,80,5,0,1 --wait --rpc-url $RPC_URL 
