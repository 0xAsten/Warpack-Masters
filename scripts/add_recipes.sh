#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifest_dev.json | jq -r '.world.address')

export RECIPE_STSTEM_ADDRESS=$(cat ./manifest_dev.json | jq -r '.contracts[] | select(.tag == "Warpacks-recipe_system").address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo recipe system : $RECIPE_STSTEM_ADDRESS
echo "---------------------------------------------------------------------------"


# Generated add recipes commands
# Pouch,Pouch,Satchel
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 4,4,3 --wait --rpc-url $STARKNET_RPC_URL
# Pack,Satchel,Backpack
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 2,3,1 --wait --rpc-url $STARKNET_RPC_URL
# Herb,Herb,Healing Potion
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 5,5,11 --wait --rpc-url $STARKNET_RPC_URL
# Dagger,Dagger,Augmented Dagger
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 6,6,15 --wait --rpc-url $STARKNET_RPC_URL
# Sword,Sword,Augmented Sword
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 7,7,14 --wait --rpc-url $STARKNET_RPC_URL
# Shield,Spike,Spike Shield
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 9,8,16 --wait --rpc-url $STARKNET_RPC_URL
# Shield,Helmet,Buckler
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 9,10,19 --wait --rpc-url $STARKNET_RPC_URL
# Leather Armor,Shield,Mail Armor
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 12,9,18 --wait --rpc-url $STARKNET_RPC_URL
# Leather Armor,Spike Shield,Blade Armor
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 12,16,29 --wait --rpc-url $STARKNET_RPC_URL
# Leather Armor,Scarlet Cloak,Vampiric Armor
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 12,32,21 --wait --rpc-url $STARKNET_RPC_URL
# Bow,Bow,Longbow
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 23,23,34 --wait --rpc-url $STARKNET_RPC_URL
# Rage Gauntlet,Helmet,Knight Helmet
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 27,10,28 --wait --rpc-url $STARKNET_RPC_URL
# Club,Club,Hammer
sozo execute --world $WORLD_ADDRESS $RECIPE_STSTEM_ADDRESS add_recipe -c 30,30,25 --wait --rpc-url $STARKNET_RPC_URL
