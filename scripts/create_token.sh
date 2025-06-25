#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# Add parameter handling for environment
ENV=${1:-dev}  # Default to 'dev' if no argument provided
ITEM_ID=${2:-6}  # Default to item ID 6 (Dagger) if no item ID provided
MANIFEST_FILE="./manifest_${ENV}.json"

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "Error: Manifest file $MANIFEST_FILE does not exist"
    exit 1
fi

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.world.address')
export TOKEN_FACTORY_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-token_factory_system").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "Token Factory: $TOKEN_FACTORY_ADDRESS"
echo "Creating token for item ID: $ITEM_ID"
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $TOKEN_FACTORY_ADDRESS create_token_for_item -c $ITEM_ID --wait --rpc-url $STARKNET_RPC_URL \
	--account-address 0x1e59eb74ce98fced4e9b10cb8d9db58f856194da24984fd64193e0d787ce519 \
	--private-key 0x76468ff8e97cf4ad25412f6134f3b3ce835ee9732da92b3b6b1974de76b8975 