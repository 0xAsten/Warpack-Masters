#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export STARKNET_RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";
: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')
export SYSTEM_ACTION_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::fight::fight_system" ).address')

echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo " "
echo system action : $SYSTEM_ACTION_ADDRESS
echo "---------------------------------------------------------------------------"

# enable system -> models authorizations
sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
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
  BattleLogCounter,$ACTIONS_ADDRESS\
  NameRecord,$ACTIONS_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  BackpackGrids,$SYSTEM_ACTION_ADDRESS \
  Character,$SYSTEM_ACTION_ADDRESS \
  CharacterItemStorage,$SYSTEM_ACTION_ADDRESS \
  CharacterItemsStorageCounter,$SYSTEM_ACTION_ADDRESS \
  CharacterItemInventory,$SYSTEM_ACTION_ADDRESS \
  CharacterItemsInventoryCounter,$SYSTEM_ACTION_ADDRESS \
  DummyCharacter,$SYSTEM_ACTION_ADDRESS \
  DummyCharacterCounter,$SYSTEM_ACTION_ADDRESS \
  DummyCharacterItem,$SYSTEM_ACTION_ADDRESS \
  DummyCharacterItemsCounter,$SYSTEM_ACTION_ADDRESS \
  Item,$SYSTEM_ACTION_ADDRESS \
  ItemsCounter,$SYSTEM_ACTION_ADDRESS \
  Shop,$SYSTEM_ACTION_ADDRESS \
  BattleLog,$SYSTEM_ACTION_ADDRESS \
  BattleLogCounter,$SYSTEM_ACTION_ADDRESS\
  NameRecord,$SYSTEM_ACTION_ADDRESS

echo "Default authorizations have been successfully set."
