#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-actions" and .kind == "DojoContract").address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS spawn -c 0x616c696365,0 --wait --rpc-url $STARKNET_RPC_URL \
	--account-address 0x1e59eb74ce98fced4e9b10cb8d9db58f856194da24984fd64193e0d787ce519 \
	--private-key 0x76468ff8e97cf4ad25412f6134f3b3ce835ee9732da92b3b6b1974de76b8975
