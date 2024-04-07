#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://0.0.0.0:5050"

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations
sozo auth grant --world $WORLD_ADDRESS --wait writer --rpc-url $RPC_URL \
  Item,$ACTIONS_ADDRESS 

echo "Default authorizations have been successfully set."
