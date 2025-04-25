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
sozo execute -P ${ENV} Warpacks-item_system add_item 1 0x4261636b7061636b 4 0 2 3 10 9 6 0 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 2 0x5061636b 4 2 2 2 4 9 4 0 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 3 0x5361746368656c 4 1 2 1 3 9 2 0 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 4 0x506f756368 4 1 1 1 2 9 1 0 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 5 0x48657262 3 1 1 1 2 4 1 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 6 0x446167676572 1 1 1 2 2 1 3 3 90 4 20 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 7 0x53776f7264 1 1 1 3 2 1 5 3 80 5 30 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 8 0x5370696b65 3 1 1 1 2 5 2 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 9 0x536869656c64 3 1 2 2 3 3 15 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 10 0x48656c6d6574 3 1 1 1 3 3 2 2 50 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 11 0x4865616c696e6720506f74696f6e 3 2 1 1 4 4 2 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 12 0x4c6561746865722041726d6f72 3 2 2 3 5 3 25 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 13 0x506f69736f6e 3 2 1 1 5 6 2 0 100 0 0 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 14 0x4175676d656e7465642053776f7264 1 2 1 3 6 1 8 3 80 5 30 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 15 0x4175676d656e74656420446167676572 1 2 1 2 6 1 5 3 90 4 20 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 16 0x5370696b6520536869656c64 3 2 2 2 7 5 2 2 75 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 17 0x506c6167756520466c6f776572 3 3 2 2 12 6 3 0 80 0 0 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 18 0x4d61696c2041726d6f72 3 3 2 3 12 3 55 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 19 0x4275636b6c6572 3 2 2 2 8 3 5 2 70 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 20 0x4d61676963205761746572 3 2 1 1 4 2 5 3 90 5 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 21 0x56616d70697269632041726d6f72 3 3 2 3 12 8 2 2 55 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 22 0x477265617473776f7264 1 2 2 4 8 1 20 3 70 7 60 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 23 0x426f77 2 2 1 3 6 1 10 3 90 7 25 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 24 0x43726f7373626f77 2 1 1 2 2 1 3 3 90 5 15 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 25 0x48616d6d6572 1 1 1 4 3 1 10 3 70 7 45 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 26 0x416d756c6574206f662046757279 3 1 1 1 5 7 1 0 65 0 0 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 27 0x52616765204761756e746c6574 3 2 1 2 7 7 1 0 45 0 0 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 28 0x4b6e696768742048656c6d6574 3 3 1 2 10 7 3 0 50 0 0 1 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 29 0x426c6164652041726d6f72 3 3 2 3 10 5 5 3 80 5 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 30 0x436c7562 2 1 1 2 2 1 6 3 70 6 35 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 31 0x46616e67 3 1 1 1 3 8 1 1 100 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 32 0x536361726c657420436c6f616b 3 2 2 2 6 8 1 4 45 0 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 33 0x44726163756c61204772696d6f697265 3 3 2 2 12 8 2 3 65 7 0 0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute -P ${ENV} Warpacks-item_system add_item 34 0x4c6f6e67626f77 2 3 1 4 10 1 15 3 90 7 35 0 --wait --rpc-url $STARKNET_RPC_URL
