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
export DUMMY_STSTEM_ADDRESS=$(cat $MANIFEST_FILE | jq -r '.contracts[] | select(.tag == "Warpacks-dummy_system").address')

echo "---------------------------------------------------------------------------"
echo "Environment: $ENV"
echo "Using manifest: $MANIFEST_FILE"
echo "World: $WORLD_ADDRESS"
echo "System: $DUMMY_STSTEM_ADDRESS"
echo "---------------------------------------------------------------------------"


# Generated pre dummies commands
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 0,0x4e6f6f626965,1,5,1,4,2,0,0,2,2,2,0,0,6,2,2,0,0,5,4,4,0,0,8,5,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 1,0x44756d626965,0,5,1,4,2,0,0,2,2,2,0,0,7,5,2,0,0,9,2,2,0,0,8,4,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 2,0x426572746965,2,5,1,4,2,0,0,2,2,2,0,0,23,5,2,0,0,8,4,4,0,0,11,4,3,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 3,0x4a6f646965,1,7,1,4,2,0,0,2,2,2,0,0,15,2,2,0,0,13,4,4,0,0,8,5,4,0,0,24,3,2,0,0,9,4,2,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 4,0x526f626572746965,0,8,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,4,4,5,0,0,14,5,2,0,0,30,4,2,0,0,16,2,2,0,0,12,2,4,90,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 5,0x486172746965,2,9,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,23,5,2,0,0,24,2,4,0,0,24,3,4,0,0,19,2,2,0,0,20,4,4,0,0,11,4,3,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 6,0x426172646965,1,9,1,4,2,0,0,2,2,2,0,0,3,4,1,0,0,15,4,3,0,0,15,5,3,0,0,24,5,1,0,0,17,2,2,0,0,13,4,2,0,0,5,4,1,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 7,0x546172746965,0,11,1,4,2,0,0,2,2,2,0,0,2,2,0,0,0,2,2,4,0,0,3,4,1,0,0,25,2,0,0,0,15,3,0,0,0,27,3,2,0,0,16,2,4,0,0,12,4,1,0,0,10,5,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 8,0x4b6f6f6c6965,2,11,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,3,4,5,0,0,23,4,3,0,0,23,5,3,0,0,19,2,2,0,0,27,2,4,0,0,20,3,4,0,0,11,3,5,0,0,13,5,2,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 9,0x476f6f626965,1,11,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,3,4,5,0,0,17,2,4,0,0,18,4,3,0,0,13,2,2,0,0,13,2,3,0,0,24,3,2,0,0,20,4,2,0,0,11,5,2,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 10,0x476f6f646965,0,10,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,2,0,0,0,3,4,5,0,0,22,2,0,0,0,19,2,4,0,0,28,4,2,0,0,20,4,4,0,0,11,4,5,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 11,0x5a6970706965,2,14,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,2,0,0,0,3,4,1,0,0,3,4,5,0,0,23,2,3,0,0,23,3,3,0,0,24,2,2,90,0,19,4,1,0,0,28,5,4,0,0,20,4,5,0,0,16,2,0,0,0,15,4,3,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 12,0x506570706965,1,13,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,4,0,0,0,3,4,5,0,0,4,6,5,0,0,17,2,2,0,0,17,2,4,0,0,15,4,3,0,0,18,4,0,0,0,11,6,5,0,0,13,4,5,0,0,24,5,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 13,0x427562626965,0,15,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,4,0,0,0,2,4,5,0,0,2,6,1,0,0,2,6,3,0,0,22,2,2,0,0,25,7,1,0,0,14,6,1,0,0,29,4,0,0,0,19,4,3,0,0,11,6,4,0,0,20,4,5,0,0,28,5,5,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 14,0x4e6574746965,2,15,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,6,1,0,0,2,6,3,0,0,3,4,1,0,0,23,2,2,0,0,23,7,2,0,0,14,6,2,0,0,28,6,1,90,0,16,4,1,0,0,18,3,3,90,0,26,3,5,0,0,11,3,2,0,0,20,2,5,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 15,0x5175696c6c6965,1,15,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,17,2,2,0,0,17,2,4,0,0,18,4,0,0,0,19,4,3,0,0,24,6,1,0,0,14,7,1,0,0,11,6,3,0,0,13,6,4,0,0,13,7,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 16,0x57696e6b6965,0,16,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,2,4,5,0,0,3,6,5,0,0,21,2,2,0,0,22,4,0,0,0,15,6,1,0,0,15,7,1,0,0,18,6,3,0,0,16,4,5,0,0,28,2,5,90,0,11,4,4,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 17,0x52656e6e6965,2,17,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,3,4,5,0,0,23,2,3,0,0,23,3,3,0,0,14,7,1,0,0,28,4,5,90,0,29,4,0,0,0,18,4,3,90,0,11,7,4,90,0,11,2,2,0,0,26,3,2,0,0,20,6,2,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 18,0x487567676965,1,16,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,2,4,5,0,0,3,6,5,0,0,17,6,1,0,0,17,6,4,0,0,18,4,4,0,0,21,2,3,0,0,14,5,3,90,0,23,2,2,90,0,13,4,3,0,0,11,5,2,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 19,0x446f74746965,0,21,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,4,5,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,2,2,0,0,0,2,6,5,0,0,22,2,0,0,0,29,4,0,0,0,14,6,1,0,0,25,7,1,0,0,28,2,4,0,0,27,3,4,0,0,26,6,4,0,0,19,4,3,0,0,11,4,5,0,0,11,4,6,0,0,10,5,5,0,0,20,5,6,0,0 --wait --rpc-url $STARKNET_RPC_URL
sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c 20,0x517561636b6965,2,20,1,4,2,0,0,2,2,2,0,0,2,2,4,0,0,2,4,5,0,0,2,6,1,0,0,2,6,3,0,0,2,4,0,0,0,2,2,0,0,0,3,6,5,0,0,23,2,0,0,0,23,3,0,0,0,14,2,3,0,0,24,3,3,0,0,17,4,0,0,0,21,4,2,0,0,18,6,1,0,0,26,3,5,0,0,20,7,4,0,0,20,7,5,0,0,28,4,5,0,0 --wait --rpc-url $STARKNET_RPC_URL

