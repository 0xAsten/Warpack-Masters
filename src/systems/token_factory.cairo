use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    fn create_token_for_item(ref self: TContractState, item_id: u32, name: ByteArray, symbol: ByteArray, owner: ContractAddress, erc20_class_hash: ClassHash) -> ContractAddress;
    fn get_token_address(self: @TContractState, item_id: u32) -> ContractAddress;
    fn batch_create_tokens_for_items(ref self: TContractState, owner: ContractAddress, erc20_class_hash: ClassHash);
    fn reigster_gold(ref self: TContractState, gold_address: ContractAddress)
}

#[dojo::contract]
pub mod token_factory {
    use super::ITokenFactory;
    use starknet::{
        ContractAddress, contract_address_const,
        syscalls::deploy_syscall, get_caller_address, ClassHash
    };
    use dojo::model::{ModelStorage};
    
    use warpack_masters::models::{
        TokenRegistry::{TokenRegistry},
        Item::Item,
    };
    use warpack_masters::items;

    use warpack_masters::constants::constants::{TOKEN_SUPPLY_BASE, GOLD_ITEM_ID};

    use dojo::world::{IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl TokenFactoryImpl of ITokenFactory<ContractState> {
        fn create_token_for_item(ref self: ContractState, item_id: u32, name: ByteArray, symbol: ByteArray, owner: ContractAddress, erc20_class_hash: ClassHash) -> ContractAddress {
            let mut world = self.world(@"Warpacks");

            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

            // check if item is valid
            let item: Item = world.read_model(item_id);
            assert(item.name == name, 'Item name does not match');
            
            // Check if token already exists
            let existing_registry: TokenRegistry = world.read_model(item_id);
            assert(existing_registry.token_address == contract_address_const::<0>(), 'Token already exists');
                        
            // Deploy the ERC-20 token contract
            let mut constructor_calldata = ArrayTrait::new();
            name.serialize(ref constructor_calldata);
            symbol.serialize(ref constructor_calldata);
            TOKEN_SUPPLY_BASE.serialize(ref constructor_calldata); // 10M tokens with 18 decimals
            owner.serialize(ref constructor_calldata); // recipient
            owner.serialize(ref constructor_calldata); // owner
            
            let (token_address, _) = deploy_syscall(
                erc20_class_hash,
                0, // salt
                constructor_calldata.span(),
                false
            ).unwrap();
            
            // Register the token
            let token_registry = TokenRegistry {
                item_id,
                name,
                symbol,
                token_address,
                is_active: true,
            };
            
            world.write_model(@token_registry);
            
            token_address
        }
        
        fn get_token_address(self: @ContractState, item_id: u32) -> ContractAddress {
            let world = self.world(@"Warpacks");
            let registry: TokenRegistry = world.read_model(item_id);
            registry.token_address
        }

        fn batch_create_tokens_for_items(ref self: ContractState, owner: ContractAddress, erc20_class_hash: ClassHash) {
            let mut world = self.world(@"Warpacks");

            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'caller not world owner');

            // Create tokens for all items
            // Item 1: Backpack
            self.create_token_for_item(items::Backpack::id, items::Backpack::name(), "BACKPACK", owner, erc20_class_hash);
            
            // Item 2: Pack
            self.create_token_for_item(items::Pack::id, items::Pack::name(), "PACK", owner, erc20_class_hash);
            
            // Item 3: Satchel
            self.create_token_for_item(items::Satchel::id, items::Satchel::name(), "SATCHEL", owner, erc20_class_hash);
            
            // Item 4: Pouch
            self.create_token_for_item(items::Pouch::id, items::Pouch::name(), "POUCH", owner, erc20_class_hash);
            
            // Item 5: Herb
            self.create_token_for_item(items::Herb::id, items::Herb::name(), "HERB", owner, erc20_class_hash);
            
            // Item 6: Dagger
            self.create_token_for_item(items::Dagger::id, items::Dagger::name(), "DAGGER", owner, erc20_class_hash);
            
            // Item 7: Sword
            self.create_token_for_item(items::Sword::id, items::Sword::name(), "SWORD", owner, erc20_class_hash);
            
            // Item 8: Spike
            self.create_token_for_item(items::Spike::id, items::Spike::name(), "SPIKE", owner, erc20_class_hash);
            
            // Item 9: Shield
            self.create_token_for_item(items::Shield::id, items::Shield::name(), "SHIELD", owner, erc20_class_hash);
            
            // Item 10: Helmet
            self.create_token_for_item(items::Helmet::id, items::Helmet::name(), "HELMET", owner, erc20_class_hash);
            
            // Item 11: Healing Potion
            self.create_token_for_item(items::HealingPotion::id, items::HealingPotion::name(), "HEAL_POT", owner, erc20_class_hash);
            
            // Item 12: Leather Armor
            self.create_token_for_item(items::LeatherArmor::id, items::LeatherArmor::name(), "LEATHER", owner, erc20_class_hash);
            
            // Item 13: Poison
            self.create_token_for_item(items::Poison::id, items::Poison::name(), "POISON", owner, erc20_class_hash);
            
            // Item 14: Augmented Sword
            self.create_token_for_item(items::AugmentedSword::id, items::AugmentedSword::name(), "AUG_SWORD", owner, erc20_class_hash);
            
            // Item 15: Augmented Dagger
            self.create_token_for_item(items::AugmentedDagger::id, items::AugmentedDagger::name(), "AUG_DAGGER", owner, erc20_class_hash);
            
            // Item 16: Spike Shield
            self.create_token_for_item(items::SpikeShield::id, items::SpikeShield::name(), "SPIKE_SHIELD", owner, erc20_class_hash);
            
            // Item 17: Plague Flower
            self.create_token_for_item(items::PlagueFlower::id, items::PlagueFlower::name(), "PLAGUE_FLOWER", owner, erc20_class_hash);
            
            // Item 18: Mail Armor
            self.create_token_for_item(items::MailArmor::id, items::MailArmor::name(), "MAIL_ARMOR", owner, erc20_class_hash);
            
            // Item 19: Buckler
            self.create_token_for_item(items::Buckler::id, items::Buckler::name(), "BUCKLER", owner, erc20_class_hash);
            
            // Item 20: Magic Water
            self.create_token_for_item(items::MagicWater::id, items::MagicWater::name(), "MAGIC_WATER", owner, erc20_class_hash);
            
            // Item 21: Vampiric Armor
            self.create_token_for_item(items::VampiricArmor::id, items::VampiricArmor::name(), "VAMPIRIC", owner, erc20_class_hash);
            
            // Item 22: Greatsword
            self.create_token_for_item(items::Greatsword::id, items::Greatsword::name(), "GREATSWORD", owner, erc20_class_hash);
            
            // Item 23: Bow
            self.create_token_for_item(items::Bow::id, items::Bow::name(), "BOW", owner, erc20_class_hash);
            
            // Item 24: Crossbow
            self.create_token_for_item(items::Crossbow::id, items::Crossbow::name(), "CROSSBOW", owner, erc20_class_hash);
            
            // Item 25: Hammer
            self.create_token_for_item(items::Hammer::id, items::Hammer::name(), "HAMMER", owner, erc20_class_hash);
            
            // Item 26: Amulet of Fury
            self.create_token_for_item(items::AmuletOfFury::id, items::AmuletOfFury::name(), "FURY_AMULET", owner, erc20_class_hash);
            
            // Item 27: Rage Gauntlet
            self.create_token_for_item(items::RageGauntlet::id, items::RageGauntlet::name(), "RAGE_GAUNTLET", owner, erc20_class_hash);
            
            // Item 28: Knight Helmet
            self.create_token_for_item(items::KnightHelmet::id, items::KnightHelmet::name(), "KNIGHT_HELMET", owner, erc20_class_hash);
            
            // Item 29: Blade Armor
            self.create_token_for_item(items::BladeArmor::id, items::BladeArmor::name(), "BLADE_ARMOR", owner, erc20_class_hash);
            
            // Item 30: Club
            self.create_token_for_item(items::Club::id, items::Club::name(), "CLUB", owner, erc20_class_hash);
            
            // Item 31: Fang
            self.create_token_for_item(items::Fang::id, items::Fang::name(), "FANG", owner, erc20_class_hash);
            
            // Item 32: Scarlet Cloak
            self.create_token_for_item(items::ScarletCloak::id, items::ScarletCloak::name(), "SCARLET_CLOAK", owner, erc20_class_hash);
            
            // Item 33: Dracula Grimoire
            self.create_token_for_item(items::DraculaGrimoire::id, items::DraculaGrimoire::name(), "DRACULA_GRIM", owner, erc20_class_hash);
            
            // Item 34: Longbow
            self.create_token_for_item(items::Longbow::id, items::Longbow::name(), "LONGBOW", owner, erc20_class_hash);
        }

        fn reigster_gold(ref self: ContractState, gold_address: ContractAddress) {
            let token_registry = TokenRegistry {
                GOLD_ITEM_ID,
                "Gold",
                "gold",
                token_address,
                is_active: true,
            };
            
            world.write_model(@token_registry);
        }
    }
} 