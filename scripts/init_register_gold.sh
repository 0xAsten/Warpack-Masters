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
export TOKEN_FACTORY_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-token_factory").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "Token Factory: $TOKEN_FACTORY_ADDRESS"
echo "---------------------------------------------------------------------------"

sozo execute -P ${ENV} Warpacks-token_factory reigster_gold 0x034dc20ea98d615518c783f498869d08d260dffec86fdef9448bd04ff8482001 --wait --rpc-url $STARKNET_RPC_URL