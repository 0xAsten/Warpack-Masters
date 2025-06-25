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
export ITEM_STSTEM_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-item_system").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "Item system: $ITEM_STSTEM_ADDRESS"
echo "---------------------------------------------------------------------------"

# Generated item commands
sozo execute -P ${ENV} Warpacks-item_system batch_add_items --wait --rpc-url $STARKNET_RPC_URL