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

sozo execute -P ${ENV} Warpacks-token_factory batch_create_tokens_for_items 0x06cac844965c5d6517f3194ea13a884388fff54fae265a6d9e7ceec428a53a19 0x035997337274dff77d12521875c8f5eec22a8ce54c7bf84aa42ede007ba404cd  --wait --rpc-url $STARKNET_RPC_URL

