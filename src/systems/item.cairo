#[starknet::interface]
pub trait IItem<T> {
    fn add_item(
        ref self: T,
        id: u32,
        name: ByteArray,
        itemType: u8,
        rarity: u8,
        width: u32,
        height: u32,
        price: u32,
        effectType: u8,
        effectStacks: u32,
        effectActivationType: u8,
        chance: u32,
        cooldown: u8,
        energyCost: u8,
        isPlugin: bool,
    );

    fn batch_add_items(
        ref self: T,
    );

    fn update_item_enabled(
        ref self: T,
        id: u32,
        enabled: bool,
    );
}

#[dojo::contract]
mod item_system {
    use super::IItem;

    use starknet::{get_caller_address};
    use warpack_masters::models::{Item::{Item, ItemsCounter}};

    use warpack_masters::constants::constants::{GRID_X, GRID_Y, ITEMS_COUNTER_ID};

    use dojo::model::{ModelStorage};
    use dojo::world::{IWorldDispatcherTrait};

    use warpack_masters::{items};

    #[abi(embed_v0)]
    impl ItemImpl of IItem<ContractState> {
        fn add_item(
            ref self: ContractState,
            id: u32,
            name: ByteArray,
            itemType: u8,
            rarity: u8,
            width: u32,
            height: u32,
            price: u32,
            effectType: u8,
            effectStacks: u32,
            effectActivationType: u8,
            chance: u32,
            cooldown: u8,
            energyCost: u8,
            isPlugin: bool,
        ) {
            // TODO: effectStacks can't be 0
            // TODO: Cooldown can't be 0 when effectActivationType is cooldown
            // TODO: The possible value of effectActivationType is 0, 1, 2, 3, 4
            // TODO: The possible value of effectType is 1, 2, 3, 4, 5, 6, 7, 8, 9
            // TODO: The possible value of itemType is 1, 2, 3, 4

            let mut world = self.world(@"Warpacks");

            let player = get_caller_address();

            assert(world.dispatcher.is_owner(0, player), 'player not world owner');

            assert(width > 0 && width <= GRID_X, 'width not in range');
            assert(height > 0 && height <= GRID_Y, 'height not in range');

            assert(price > 0, 'price must be greater than 0');

            assert(
                rarity == 1 || rarity == 2 || rarity == 3 || (rarity == 0 && itemType == 4),
                'rarity not valid'
            );

            assert(
                cooldown == 0 || cooldown == 4 || cooldown == 5 || cooldown == 6 || cooldown == 7,
                'cooldown not valid'
            );

            let counter: ItemsCounter = world.read_model(ITEMS_COUNTER_ID);
            if id > counter.count {
                world.write_model(@ItemsCounter{id: ITEMS_COUNTER_ID, count: id})
            }

            let item = Item {
                id,
                name,
                itemType,
                rarity,
                width,
                height,
                price,
                effectType,
                effectStacks,
                effectActivationType,
                chance,
                cooldown,
                energyCost,
                isPlugin,
                enabled: true,
            };

            world.write_model(@item);
        }

        fn batch_add_items(
            ref self: ContractState,
        ) {
            let mut world = self.world(@"Warpacks");
            let caller = get_caller_address();
            assert(world.dispatcher.is_owner(0, caller), 'player not world owner');

            self.add_item(
                items::Backpack::id,
                items::Backpack::name(),
                items::Backpack::itemType,
                items::Backpack::rarity,
                items::Backpack::width,
                items::Backpack::height,
                items::Backpack::price,
                items::Backpack::effectType,
                items::Backpack::effectStacks,
                items::Backpack::effectActivationType,
                items::Backpack::chance,
                items::Backpack::cooldown,
                items::Backpack::energyCost,
                items::Backpack::isPlugin,
            );

            self.add_item(
                items::Pack::id,
                items::Pack::name(),
                items::Pack::itemType,
                items::Pack::rarity,
                items::Pack::width,
                items::Pack::height,
                items::Pack::price,
                items::Pack::effectType,
                items::Pack::effectStacks,
                items::Pack::effectActivationType,
                items::Pack::chance,
                items::Pack::cooldown,
                items::Pack::energyCost,
                items::Pack::isPlugin,
            );

            self.add_item(
                items::Satchel::id,
                items::Satchel::name(),
                items::Satchel::itemType,
                items::Satchel::rarity,
                items::Satchel::width,
                items::Satchel::height,
                items::Satchel::price,
                items::Satchel::effectType,
                items::Satchel::effectStacks,
                items::Satchel::effectActivationType,
                items::Satchel::chance,
                items::Satchel::cooldown,
                items::Satchel::energyCost,
                items::Satchel::isPlugin,
            );

            self.add_item(
                items::Pouch::id,
                items::Pouch::name(),
                items::Pouch::itemType,
                items::Pouch::rarity,
                items::Pouch::width,
                items::Pouch::height,
                items::Pouch::price,
                items::Pouch::effectType,
                items::Pouch::effectStacks,
                items::Pouch::effectActivationType,
                items::Pouch::chance,
                items::Pouch::cooldown,
                items::Pouch::energyCost,
                items::Pouch::isPlugin,
            );

            self.add_item(
                items::Herb::id,
                items::Herb::name(),
                items::Herb::itemType,
                items::Herb::rarity,
                items::Herb::width,
                items::Herb::height,
                items::Herb::price,
                items::Herb::effectType,
                items::Herb::effectStacks,
                items::Herb::effectActivationType,
                items::Herb::chance,
                items::Herb::cooldown,
                items::Herb::energyCost,
                items::Herb::isPlugin,
            );

            self.add_item(
                items::Dagger::id,
                items::Dagger::name(),
                items::Dagger::itemType,
                items::Dagger::rarity,
                items::Dagger::width,
                items::Dagger::height,
                items::Dagger::price,
                items::Dagger::effectType,
                items::Dagger::effectStacks,
                items::Dagger::effectActivationType,
                items::Dagger::chance,
                items::Dagger::cooldown,
                items::Dagger::energyCost,
                items::Dagger::isPlugin,
            );

            self.add_item(
                items::Sword::id,
                items::Sword::name(),
                items::Sword::itemType,
                items::Sword::rarity,
                items::Sword::width,
                items::Sword::height,
                items::Sword::price,
                items::Sword::effectType,
                items::Sword::effectStacks,
                items::Sword::effectActivationType,
                items::Sword::chance,
                items::Sword::cooldown,
                items::Sword::energyCost,
                items::Sword::isPlugin,
            );

            self.add_item(
                items::Spike::id,
                items::Spike::name(),
                items::Spike::itemType,
                items::Spike::rarity,
                items::Spike::width,
                items::Spike::height,
                items::Spike::price,
                items::Spike::effectType,
                items::Spike::effectStacks,
                items::Spike::effectActivationType,
                items::Spike::chance,
                items::Spike::cooldown,
                items::Spike::energyCost,
                items::Spike::isPlugin,
            );

            self.add_item(
                items::Shield::id,
                items::Shield::name(),
                items::Shield::itemType,
                items::Shield::rarity,
                items::Shield::width,
                items::Shield::height,
                items::Shield::price,
                items::Shield::effectType,
                items::Shield::effectStacks,
                items::Shield::effectActivationType,
                items::Shield::chance,
                items::Shield::cooldown,
                items::Shield::energyCost,
                items::Shield::isPlugin,
            );

            self.add_item(
                items::Helmet::id,
                items::Helmet::name(),
                items::Helmet::itemType,
                items::Helmet::rarity,
                items::Helmet::width,
                items::Helmet::height,
                items::Helmet::price,
                items::Helmet::effectType,
                items::Helmet::effectStacks,
                items::Helmet::effectActivationType,
                items::Helmet::chance,
                items::Helmet::cooldown,
                items::Helmet::energyCost,
                items::Helmet::isPlugin,
            );

            self.add_item(
                items::HealingPotion::id,
                items::HealingPotion::name(),
                items::HealingPotion::itemType,
                items::HealingPotion::rarity,
                items::HealingPotion::width,
                items::HealingPotion::height,
                items::HealingPotion::price,
                items::HealingPotion::effectType,
                items::HealingPotion::effectStacks,
                items::HealingPotion::effectActivationType,
                items::HealingPotion::chance,
                items::HealingPotion::cooldown,
                items::HealingPotion::energyCost,
                items::HealingPotion::isPlugin,
            );

            self.add_item(
                items::LeatherArmor::id,
                items::LeatherArmor::name(),
                items::LeatherArmor::itemType,
                items::LeatherArmor::rarity,
                items::LeatherArmor::width,
                items::LeatherArmor::height,
                items::LeatherArmor::price,
                items::LeatherArmor::effectType,
                items::LeatherArmor::effectStacks,
                items::LeatherArmor::effectActivationType,
                items::LeatherArmor::chance,
                items::LeatherArmor::cooldown,
                items::LeatherArmor::energyCost,
                items::LeatherArmor::isPlugin,
            );

            self.add_item(
                items::Poison::id,
                items::Poison::name(),
                items::Poison::itemType,
                items::Poison::rarity,
                items::Poison::width,
                items::Poison::height,
                items::Poison::price,
                items::Poison::effectType,
                items::Poison::effectStacks,
                items::Poison::effectActivationType,
                items::Poison::chance,
                items::Poison::cooldown,
                items::Poison::energyCost,
                items::Poison::isPlugin,
            );

            self.add_item(
                items::AugmentedSword::id,
                items::AugmentedSword::name(),
                items::AugmentedSword::itemType,
                items::AugmentedSword::rarity,
                items::AugmentedSword::width,
                items::AugmentedSword::height,
                items::AugmentedSword::price,
                items::AugmentedSword::effectType,
                items::AugmentedSword::effectStacks,
                items::AugmentedSword::effectActivationType,
                items::AugmentedSword::chance,
                items::AugmentedSword::cooldown,
                items::AugmentedSword::energyCost,
                items::AugmentedSword::isPlugin,
            );

            self.add_item(
                items::AugmentedDagger::id,
                items::AugmentedDagger::name(),
                items::AugmentedDagger::itemType,
                items::AugmentedDagger::rarity,
                items::AugmentedDagger::width,
                items::AugmentedDagger::height,
                items::AugmentedDagger::price,
                items::AugmentedDagger::effectType,
                items::AugmentedDagger::effectStacks,
                items::AugmentedDagger::effectActivationType,
                items::AugmentedDagger::chance,
                items::AugmentedDagger::cooldown,
                items::AugmentedDagger::energyCost,
                items::AugmentedDagger::isPlugin,
            );

            self.add_item(
                items::SpikeShield::id,
                items::SpikeShield::name(),
                items::SpikeShield::itemType,
                items::SpikeShield::rarity,
                items::SpikeShield::width,
                items::SpikeShield::height,
                items::SpikeShield::price,
                items::SpikeShield::effectType,
                items::SpikeShield::effectStacks,
                items::SpikeShield::effectActivationType,
                items::SpikeShield::chance,
                items::SpikeShield::cooldown,
                items::SpikeShield::energyCost,
                items::SpikeShield::isPlugin,
            );

            self.add_item(
                items::PlagueFlower::id,
                items::PlagueFlower::name(),
                items::PlagueFlower::itemType,
                items::PlagueFlower::rarity,
                items::PlagueFlower::width,
                items::PlagueFlower::height,
                items::PlagueFlower::price,
                items::PlagueFlower::effectType,
                items::PlagueFlower::effectStacks,
                items::PlagueFlower::effectActivationType,
                items::PlagueFlower::chance,
                items::PlagueFlower::cooldown,
                items::PlagueFlower::energyCost,
                items::PlagueFlower::isPlugin,
            );

            self.add_item(
                items::MailArmor::id,
                items::MailArmor::name(),
                items::MailArmor::itemType,
                items::MailArmor::rarity,
                items::MailArmor::width,
                items::MailArmor::height,
                items::MailArmor::price,
                items::MailArmor::effectType,
                items::MailArmor::effectStacks,
                items::MailArmor::effectActivationType,
                items::MailArmor::chance,
                items::MailArmor::cooldown,
                items::MailArmor::energyCost,
                items::MailArmor::isPlugin,
            );

            self.add_item(
                items::Buckler::id,
                items::Buckler::name(),
                items::Buckler::itemType,
                items::Buckler::rarity,
                items::Buckler::width,
                items::Buckler::height,
                items::Buckler::price,
                items::Buckler::effectType,
                items::Buckler::effectStacks,
                items::Buckler::effectActivationType,
                items::Buckler::chance,
                items::Buckler::cooldown,
                items::Buckler::energyCost,
                items::Buckler::isPlugin,
            );

            self.add_item(
                items::MagicWater::id,
                items::MagicWater::name(),
                items::MagicWater::itemType,
                items::MagicWater::rarity,
                items::MagicWater::width,
                items::MagicWater::height,
                items::MagicWater::price,
                items::MagicWater::effectType,
                items::MagicWater::effectStacks,
                items::MagicWater::effectActivationType,
                items::MagicWater::chance,
                items::MagicWater::cooldown,
                items::MagicWater::energyCost,
                items::MagicWater::isPlugin,
            );

            self.add_item(
                items::VampiricArmor::id,
                items::VampiricArmor::name(),
                items::VampiricArmor::itemType,
                items::VampiricArmor::rarity,
                items::VampiricArmor::width,
                items::VampiricArmor::height,
                items::VampiricArmor::price,
                items::VampiricArmor::effectType,
                items::VampiricArmor::effectStacks,
                items::VampiricArmor::effectActivationType,
                items::VampiricArmor::chance,
                items::VampiricArmor::cooldown,
                items::VampiricArmor::energyCost,
                items::VampiricArmor::isPlugin,
            );

            self.add_item(
                items::Greatsword::id,
                items::Greatsword::name(),
                items::Greatsword::itemType,
                items::Greatsword::rarity,
                items::Greatsword::width,
                items::Greatsword::height,
                items::Greatsword::price,
                items::Greatsword::effectType,
                items::Greatsword::effectStacks,
                items::Greatsword::effectActivationType,
                items::Greatsword::chance,
                items::Greatsword::cooldown,
                items::Greatsword::energyCost,
                items::Greatsword::isPlugin,
            );

            self.add_item(
                items::Bow::id,
                items::Bow::name(),
                items::Bow::itemType,
                items::Bow::rarity,
                items::Bow::width,
                items::Bow::height,
                items::Bow::price,
                items::Bow::effectType,
                items::Bow::effectStacks,
                items::Bow::effectActivationType,
                items::Bow::chance,
                items::Bow::cooldown,
                items::Bow::energyCost,
                items::Bow::isPlugin,
            );

            self.add_item(
                items::Crossbow::id,
                items::Crossbow::name(),
                items::Crossbow::itemType,
                items::Crossbow::rarity,
                items::Crossbow::width,
                items::Crossbow::height,
                items::Crossbow::price,
                items::Crossbow::effectType,
                items::Crossbow::effectStacks,
                items::Crossbow::effectActivationType,
                items::Crossbow::chance,
                items::Crossbow::cooldown,
                items::Crossbow::energyCost,
                items::Crossbow::isPlugin,
            );

            self.add_item(
                items::Hammer::id,
                items::Hammer::name(),
                items::Hammer::itemType,
                items::Hammer::rarity,
                items::Hammer::width,
                items::Hammer::height,
                items::Hammer::price,
                items::Hammer::effectType,
                items::Hammer::effectStacks,
                items::Hammer::effectActivationType,
                items::Hammer::chance,
                items::Hammer::cooldown,
                items::Hammer::energyCost,
                items::Hammer::isPlugin,
            );

            self.add_item(
                items::AmuletOfFury::id,
                items::AmuletOfFury::name(),
                items::AmuletOfFury::itemType,
                items::AmuletOfFury::rarity,
                items::AmuletOfFury::width,
                items::AmuletOfFury::height,
                items::AmuletOfFury::price,
                items::AmuletOfFury::effectType,
                items::AmuletOfFury::effectStacks,
                items::AmuletOfFury::effectActivationType,
                items::AmuletOfFury::chance,
                items::AmuletOfFury::cooldown,
                items::AmuletOfFury::energyCost,
                items::AmuletOfFury::isPlugin,
            );

            self.add_item(
                items::RageGauntlet::id,
                items::RageGauntlet::name(),
                items::RageGauntlet::itemType,
                items::RageGauntlet::rarity,
                items::RageGauntlet::width,
                items::RageGauntlet::height,
                items::RageGauntlet::price,
                items::RageGauntlet::effectType,
                items::RageGauntlet::effectStacks,
                items::RageGauntlet::effectActivationType,
                items::RageGauntlet::chance,
                items::RageGauntlet::cooldown,
                items::RageGauntlet::energyCost,
                items::RageGauntlet::isPlugin,
            );

            self.add_item(
                items::KnightHelmet::id,
                items::KnightHelmet::name(),
                items::KnightHelmet::itemType,
                items::KnightHelmet::rarity,
                items::KnightHelmet::width,
                items::KnightHelmet::height,
                items::KnightHelmet::price,
                items::KnightHelmet::effectType,
                items::KnightHelmet::effectStacks,
                items::KnightHelmet::effectActivationType,
                items::KnightHelmet::chance,
                items::KnightHelmet::cooldown,
                items::KnightHelmet::energyCost,
                items::KnightHelmet::isPlugin,
            );

            self.add_item(
                items::BladeArmor::id,
                items::BladeArmor::name(),
                items::BladeArmor::itemType,
                items::BladeArmor::rarity,
                items::BladeArmor::width,
                items::BladeArmor::height,
                items::BladeArmor::price,
                items::BladeArmor::effectType,
                items::BladeArmor::effectStacks,
                items::BladeArmor::effectActivationType,
                items::BladeArmor::chance,
                items::BladeArmor::cooldown,
                items::BladeArmor::energyCost,
                items::BladeArmor::isPlugin,
            );

            self.add_item(
                items::Club::id,
                items::Club::name(),
                items::Club::itemType,
                items::Club::rarity,
                items::Club::width,
                items::Club::height,
                items::Club::price,
                items::Club::effectType,
                items::Club::effectStacks,
                items::Club::effectActivationType,
                items::Club::chance,
                items::Club::cooldown,
                items::Club::energyCost,
                items::Club::isPlugin,
            );

            self.add_item(
                items::Fang::id,
                items::Fang::name(),
                items::Fang::itemType,
                items::Fang::rarity,
                items::Fang::width,
                items::Fang::height,
                items::Fang::price,
                items::Fang::effectType,
                items::Fang::effectStacks,
                items::Fang::effectActivationType,
                items::Fang::chance,
                items::Fang::cooldown,
                items::Fang::energyCost,
                items::Fang::isPlugin,
            );

            self.add_item(
                items::ScarletCloak::id,
                items::ScarletCloak::name(),
                items::ScarletCloak::itemType,
                items::ScarletCloak::rarity,
                items::ScarletCloak::width,
                items::ScarletCloak::height,
                items::ScarletCloak::price,
                items::ScarletCloak::effectType,
                items::ScarletCloak::effectStacks,
                items::ScarletCloak::effectActivationType,
                items::ScarletCloak::chance,
                items::ScarletCloak::cooldown,
                items::ScarletCloak::energyCost,
                items::ScarletCloak::isPlugin,
            );

            self.add_item(
                items::DraculaGrimoire::id,
                items::DraculaGrimoire::name(),
                items::DraculaGrimoire::itemType,
                items::DraculaGrimoire::rarity,
                items::DraculaGrimoire::width,
                items::DraculaGrimoire::height,
                items::DraculaGrimoire::price,
                items::DraculaGrimoire::effectType,
                items::DraculaGrimoire::effectStacks,
                items::DraculaGrimoire::effectActivationType,
                items::DraculaGrimoire::chance,
                items::DraculaGrimoire::cooldown,
                items::DraculaGrimoire::energyCost,
                items::DraculaGrimoire::isPlugin,
            );

            self.add_item(
                items::Longbow::id,
                items::Longbow::name(),
                items::Longbow::itemType,
                items::Longbow::rarity,
                items::Longbow::width,
                items::Longbow::height,
                items::Longbow::price,
                items::Longbow::effectType,
                items::Longbow::effectStacks,
                items::Longbow::effectActivationType,
                items::Longbow::chance,
                items::Longbow::cooldown,
                items::Longbow::energyCost,
                items::Longbow::isPlugin,
            );
        }

        fn update_item_enabled(
            ref self: ContractState,
            id: u32,
            enabled: bool,
        ) {
            let mut world = self.world(@"Warpacks");
            let player = get_caller_address();
            
            assert(world.dispatcher.is_owner(0, player), 'player not world owner');
            
            let mut item: Item = world.read_model(id);
            item.enabled = enabled;
            world.write_model(@item);
        }
    }
}
