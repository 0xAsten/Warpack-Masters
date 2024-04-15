#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-master/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS fight --wait --rpc-url $RPC_URL \
	--account-address 0x6127f482962eae2119a47542e1a2115f7b7713eebd9a2fa9f02cb118cb737b5 \
	--private-key 0x325721938864cfdb04706bf2b129015d03cdbb3301ac648965bf94d995bf5b4
