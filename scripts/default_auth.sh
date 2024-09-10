#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# export STARKNET_RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";
: "${STARKNET_RPC_URL:?Environment variable STARKNET_RPC_URL must be set}"

export WORLD_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.world.address')
export ACTIONS_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-actions" and .kind == "DojoContract").address')
export DUMMY_STSTEM_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-dummy_system" and .kind == "DojoContract").address')
export FIGHT_STSTEM_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-fight_system" and .kind == "DojoContract").address')
export ITEM_STSTEM_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-item_system" and .kind == "DojoContract").address')
export SHOP_STSTEM_ADDRESS=$(cat ./manifests/release/deployment/manifest.json | jq -r '.contracts[] | select(.tag == "Warpacks-shop_system" and .kind == "DojoContract").address')


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
  model:Warpacks-BackpackGrids,$ACTIONS_ADDRESS \
  model:Warpacks-Characters,$ACTIONS_ADDRESS \
  model:Warpacks-CharacterItemStorage,$ACTIONS_ADDRESS \
  model:Warpacks-CharacterItemsStorageCounter,$ACTIONS_ADDRESS \
  model:Warpacks-CharacterItemInventory,$ACTIONS_ADDRESS \
  model:Warpacks-CharacterItemsInventoryCounter,$ACTIONS_ADDRESS \
  model:Warpacks-DummyCharacter,$ACTIONS_ADDRESS \
  model:Warpacks-DummyCharacterCounter,$ACTIONS_ADDRESS \
  model:Warpacks-DummyCharacterItem,$ACTIONS_ADDRESS \
  model:Warpacks-DummyCharacterItemsCounter,$ACTIONS_ADDRESS \
  model:Warpacks-Item,$ACTIONS_ADDRESS \
  model:Warpacks-ItemsCounter,$ACTIONS_ADDRESS \
  model:Warpacks-Shop,$ACTIONS_ADDRESS \
  model:Warpacks-BattleLog,$ACTIONS_ADDRESS \
  model:Warpacks-BattleLogCounter,$ACTIONS_ADDRESS\
  model:Warpacks-NameRecord,$ACTIONS_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  model:Warpacks-BackpackGrids,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-Characters,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemStorage,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsStorageCounter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemInventory,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsInventoryCounter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterCounter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItem,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItemsCounter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-Item,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-ItemsCounter,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-Shop,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-BattleLog,$DUMMY_STSTEM_ADDRESS \
  model:Warpacks-BattleLogCounter,$DUMMY_STSTEM_ADDRESS\
  model:Warpacks-NameRecord,$DUMMY_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  model:Warpacks-BackpackGrids,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-Characters,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemStorage,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsStorageCounter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemInventory,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsInventoryCounter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterCounter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItem,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItemsCounter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-Item,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-ItemsCounter,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-Shop,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-BattleLog,$FIGHT_STSTEM_ADDRESS \
  model:Warpacks-BattleLogCounter,$FIGHT_STSTEM_ADDRESS\
  model:Warpacks-NameRecord,$FIGHT_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  model:Warpacks-BackpackGrids,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-Characters,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemStorage,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsStorageCounter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemInventory,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsInventoryCounter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterCounter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItem,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItemsCounter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-Item,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-ItemsCounter,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-Shop,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-BattleLog,$ITEM_STSTEM_ADDRESS \
  model:Warpacks-BattleLogCounter,$ITEM_STSTEM_ADDRESS\
  model:Warpacks-NameRecord,$ITEM_STSTEM_ADDRESS

sozo auth grant --world $WORLD_ADDRESS --rpc-url $STARKNET_RPC_URL --wait writer \
  model:Warpacks-BackpackGrids,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-Characters,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemStorage,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsStorageCounter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemInventory,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-CharacterItemsInventoryCounter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterCounter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItem,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-DummyCharacterItemsCounter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-Item,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-ItemsCounter,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-Shop,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-BattleLog,$SHOP_STSTEM_ADDRESS \
  model:Warpacks-BattleLogCounter,$SHOP_STSTEM_ADDRESS\
  model:Warpacks-NameRecord,$SHOP_STSTEM_ADDRESS

echo "Default authorizations have been successfully set."
