#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Add parameter handling for environment and item parameters
ENV=${1:-dev}  # Default to 'dev' if no argument provided
ITEM_ID=${2:?Error: Item ID must be provided as second argument}
ENABLED=${3:?Error: Enabled state (true/false) must be provided as third argument}

MANIFEST_FILE="./manifest_${ENV}.json"

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "Error: Manifest file $MANIFEST_FILE does not exist"
    exit 1
fi

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.world.address')
export ITEM_SYSTEM_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-item_system").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "Item system: $ITEM_SYSTEM_ADDRESS"
echo "Updating item ID: $ITEM_ID to enabled: $ENABLED"
echo "---------------------------------------------------------------------------"

# Execute update_item_enabled command
sozo execute -P ${ENV} Warpacks-item_system update_item_enabled $ITEM_ID $ENABLED --wait --rpc-url $STARKNET_RPC_URL --fee ETH