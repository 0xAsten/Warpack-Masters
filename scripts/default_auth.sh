#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";
: "${RPC_URL:?Environment variable RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

# export ACTIONS_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')
export ACTIONS_ADDRESS='0x591fe4c5c0987dfd20e14e82875494699eda1e47c68c98801df329424e1bb03'

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations
sozo auth grant --world $WORLD_ADDRESS --rpc-url $RPC_URL --wait writer \
  BackpackGrids,$ACTIONS_ADDRESS \
  Character,$ACTIONS_ADDRESS \
  CharacterItemStorage,$ACTIONS_ADDRESS \
  CharacterItemsStorageCounter,$ACTIONS_ADDRESS \
  CharacterItemInventory,$ACTIONS_ADDRESS \
  CharacterItemsInventoryCounter,$ACTIONS_ADDRESS \
  DummyCharacter,$ACTIONS_ADDRESS \
  DummyCharacterCounter,$ACTIONS_ADDRESS \
  DummyCharacterItem,$ACTIONS_ADDRESS \
  DummyCharacterItemsCounter,$ACTIONS_ADDRESS \
  Item,$ACTIONS_ADDRESS \
  ItemsCounter,$ACTIONS_ADDRESS \
  Shop,$ACTIONS_ADDRESS \
  BattleLog,$ACTIONS_ADDRESS \
  BattleLogCounter,$ACTIONS_ADDRESS

echo "Default authorizations have been successfully set."
