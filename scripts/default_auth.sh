#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export STARKNET_RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";
: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.world.address')
export ACTIONS_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-actions" and .kind == "DojoContract").address')
export DUMMY_STSTEM_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-dummy_system" and .kind == "DojoContract").address')
export FIGHT_STSTEM_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-fight_system" and .kind == "DojoContract").address')
export ITEM_STSTEM_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-item_system" and .kind == "DojoContract").address')
export SHOP_STSTEM_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-shop_system" and .kind == "DojoContract").address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo " "
echo DUMMY_STSTEM : $DUMMY_STSTEM_ADDRESS
echo " "
echo FIGHT_STSTEM : $FIGHT_STSTEM_ADDRESS
echo " "
echo ITEM_STSTEM : $ITEM_STSTEM_ADDRESS
echo " "
echo SHOP_STSTEM : $SHOP_STSTEM_ADDRESS
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
  BackpackGrids,$DUMMY_STSTEM_ADDRESS \
  Character,$DUMMY_STSTEM_ADDRESS \
  CharacterItemStorage,$DUMMY_STSTEM_ADDRESS \
  CharacterItemsStorageCounter,$DUMMY_STSTEM_ADDRESS \
  CharacterItemInventory,$DUMMY_STSTEM_ADDRESS \
  CharacterItemsInventoryCounter,$DUMMY_STSTEM_ADDRESS \
  DummyCharacter,$DUMMY_STSTEM_ADDRESS \
  DummyCharacterCounter,$DUMMY_STSTEM_ADDRESS \
  DummyCharacterItem,$DUMMY_STSTEM_ADDRESS \
  DummyCharacterItemsCounter,$DUMMY_STSTEM_ADDRESS \
  Item,$DUMMY_STSTEM_ADDRESS \
  ItemsCounter,$DUMMY_STSTEM_ADDRESS \
  Shop,$DUMMY_STSTEM_ADDRESS \
  BattleLog,$DUMMY_STSTEM_ADDRESS \
  BattleLogCounter,$DUMMY_STSTEM_ADDRESS\
  NameRecord,$DUMMY_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  BackpackGrids,$FIGHT_STSTEM_ADDRESS \
  Character,$FIGHT_STSTEM_ADDRESS \
  CharacterItemStorage,$FIGHT_STSTEM_ADDRESS \
  CharacterItemsStorageCounter,$FIGHT_STSTEM_ADDRESS \
  CharacterItemInventory,$FIGHT_STSTEM_ADDRESS \
  CharacterItemsInventoryCounter,$FIGHT_STSTEM_ADDRESS \
  DummyCharacter,$FIGHT_STSTEM_ADDRESS \
  DummyCharacterCounter,$FIGHT_STSTEM_ADDRESS \
  DummyCharacterItem,$FIGHT_STSTEM_ADDRESS \
  DummyCharacterItemsCounter,$FIGHT_STSTEM_ADDRESS \
  Item,$FIGHT_STSTEM_ADDRESS \
  ItemsCounter,$FIGHT_STSTEM_ADDRESS \
  Shop,$FIGHT_STSTEM_ADDRESS \
  BattleLog,$FIGHT_STSTEM_ADDRESS \
  BattleLogCounter,$FIGHT_STSTEM_ADDRESS\
  NameRecord,$FIGHT_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  BackpackGrids,$ITEM_STSTEM_ADDRESS \
  Character,$ITEM_STSTEM_ADDRESS \
  CharacterItemStorage,$ITEM_STSTEM_ADDRESS \
  CharacterItemsStorageCounter,$ITEM_STSTEM_ADDRESS \
  CharacterItemInventory,$ITEM_STSTEM_ADDRESS \
  CharacterItemsInventoryCounter,$ITEM_STSTEM_ADDRESS \
  DummyCharacter,$ITEM_STSTEM_ADDRESS \
  DummyCharacterCounter,$ITEM_STSTEM_ADDRESS \
  DummyCharacterItem,$ITEM_STSTEM_ADDRESS \
  DummyCharacterItemsCounter,$ITEM_STSTEM_ADDRESS \
  Item,$ITEM_STSTEM_ADDRESS \
  ItemsCounter,$ITEM_STSTEM_ADDRESS \
  Shop,$ITEM_STSTEM_ADDRESS \
  BattleLog,$ITEM_STSTEM_ADDRESS \
  BattleLogCounter,$ITEM_STSTEM_ADDRESS\
  NameRecord,$ITEM_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  BackpackGrids,$SHOP_STSTEM_ADDRESS \
  Character,$SHOP_STSTEM_ADDRESS \
  CharacterItemStorage,$SHOP_STSTEM_ADDRESS \
  CharacterItemsStorageCounter,$SHOP_STSTEM_ADDRESS \
  CharacterItemInventory,$SHOP_STSTEM_ADDRESS \
  CharacterItemsInventoryCounter,$SHOP_STSTEM_ADDRESS \
  DummyCharacter,$SHOP_STSTEM_ADDRESS \
  DummyCharacterCounter,$SHOP_STSTEM_ADDRESS \
  DummyCharacterItem,$SHOP_STSTEM_ADDRESS \
  DummyCharacterItemsCounter,$SHOP_STSTEM_ADDRESS \
  Item,$SHOP_STSTEM_ADDRESS \
  ItemsCounter,$SHOP_STSTEM_ADDRESS \
  Shop,$SHOP_STSTEM_ADDRESS \
  BattleLog,$SHOP_STSTEM_ADDRESS \
  BattleLogCounter,$SHOP_STSTEM_ADDRESS\
  NameRecord,$SHOP_STSTEM_ADDRESS

echo "Default authorizations have been successfully set."
