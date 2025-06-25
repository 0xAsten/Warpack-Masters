#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Add parameter handling for environment
ENV=${1:-dev}  # Default to 'dev' if no argument provided
MANIFEST_FILE="./manifest_${ENV}.json"

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "Error: Manifest file $MANIFEST_FILE does not exist"
    exit 1
fi

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.world.address')
export RECIPE_STSTEM_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-recipe_system").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "Recipe system: $RECIPE_STSTEM_ADDRESS"
echo "---------------------------------------------------------------------------"


# Generated add recipes commands
# Pouch Pouch Satchel
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 4 4 3 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Pack Satchel Backpack
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 2 3 1 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Herb Herb Healing Potion
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 5 5 11 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Dagger Dagger Augmented Dagger
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 6 6 15 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Sword Sword Augmented Sword
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 7 7 14 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Shield Spike Spike Shield
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 9 8 16 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Shield Helmet Buckler
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 9 10 19 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Leather Armor Shield Mail Armor
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 12 9 18 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Leather Armor Spike Shield Blade Armor
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 12 16 29 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Leather Armor Scarlet Cloak Vampiric Armor
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 12 32 21 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Bow Bow Longbow
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 23 23 34 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Rage Gauntlet Helmet Knight Helmet
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 27 10 28 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
# Club Club Hammer
sozo execute -P ${ENV} Warpacks-recipe_system add_recipe 30 30 25 --wait --rpc-url $STARKNET_RPC_URL --fee ETH
