use warpack_masters::models::CharacterItem::Position;

#[derive(Copy, Drop, Serde)]
struct PredefinedItem {
    itemId: usize,
    position: Position,
    // rotation: 0, 90, 180, 270
    rotation: usize,
}

mod Dummy0 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Dagger, Herb, Spike};

    const level: usize = 0;
    const name: felt252 = 'Noobie';
    const wmClass: u8 = 1;
    const health: usize = 25;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Dagger::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Herb::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Spike::id,
            position: Position{ x:5, y:4 },
            rotation: 0,
        });

        items
    }
}

mod Dummy1 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Sword, Shield, Spike};

    const level: usize = 1;
    const name: felt252 = 'Dumbie';
    const wmClass: u8 = 0;
    const health: usize = 35;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Sword::id,
            position: Position{ x:5, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Shield::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Spike::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items
    }
}


mod Dummy2 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Bow, Spike, HealingPotion};

    const level: usize = 2;
    const name: felt252 = 'Bertie';
    const wmClass: u8 = 2;
    const health: usize = 45;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:5, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Spike::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y: 3 },
            rotation: 0,
        });

        items
    }
}

mod Dummy3 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, AugmentedDagger, Poison, Spike, Crossbow, Shield};

    const level: usize = 3;
    const name: felt252 = 'Jodie';
    const wmClass: u8 = 1;
    const health: usize = 55;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Spike::id,
            position: Position{ x:5, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:3, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Shield::id,
            position: Position{ x:4, y: 2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy4 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Pouch, AugmentedSword, Club, SpikeShield, LeatherArmor};

    const level: usize = 4;
    const name: felt252 = 'Robertie';
    const wmClass: u8 = 0;
    const health: usize = 65;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pouch::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:5, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Club::id,
            position: Position{ x:4, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: SpikeShield::id,
            position: Position{ x:2, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: LeatherArmor::id,
            position: Position{ x:2, y: 4 },
            rotation: 90,
        });

        items
    }
}

mod Dummy5 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Bow, Crossbow, Buckler, MagicWater, HealingPotion};

    const level: usize = 5;
    const name: felt252 = 'Hartie';
    const wmClass: u8 = 2;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:5, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:2, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:3, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:2, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:4, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y: 3 },
            rotation: 0,
        });

        items
    }
}

mod Dummy6 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, AugmentedDagger, Crossbow, PlagueFlower, Poison, Herb};

    const level: usize = 6;
    const name: felt252 = 'Bardie';
    const wmClass: u8 = 1;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:5, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:5, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:2, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:4, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Herb::id,
            position: Position{ x:4, y: 1 },
            rotation: 0,
        });

        items
    }
}

mod Dummy7 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Hammer, AugmentedDagger, RageGauntlet, SpikeShield, LeatherArmor, Helmet};

    const level: usize = 7;
    const name: felt252 = 'Tartie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Hammer::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:3, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: RageGauntlet::id,
            position: Position{ x:3, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: SpikeShield::id,
            position: Position{ x:2, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: LeatherArmor::id,
            position: Position{ x:4, y: 1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Helmet::id,
            position: Position{ x:5, y: 4 },
            rotation: 0,
        });

        items
    }
}

mod Dummy8 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Bow, Buckler, RageGauntlet, MagicWater, HealingPotion, Poison};

    const level: usize = 8;
    const name: felt252 = 'Koolie';
    const wmClass: u8 = 2;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:5, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: RageGauntlet::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:3, y: 4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:3, y: 5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:5, y: 2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy9 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, PlagueFlower, MailArmor, Poison, Crossbow, MagicWater, HealingPotion};

    const level: usize = 9;
    const name: felt252 = 'Goobie';
    const wmClass: u8 = 1;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:3, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:4, y: 2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:5, y: 2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy10 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Greatsword, Buckler, KnightHelmet, MagicWater, HealingPotion};

    const level: usize = 10;
    const name: felt252 = 'Goodie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });


        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Greatsword::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y: 5 },
            rotation: 0,
        });

        items
    }
}

mod Dummy11 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Bow, Crossbow, Buckler, KnightHelmet, MagicWater, SpikeShield, AugmentedDagger};

    const level: usize = 11;
    const name: felt252 = 'Zippie';
    const wmClass: u8 = 2;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });


        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:3, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:2, y:2 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:5, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: SpikeShield::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:4, y: 3 },
            rotation: 0,
        });

        items
    }
}

mod Dummy12 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Pouch, PlagueFlower, AugmentedDagger, MailArmor, HealingPotion, Poison, Crossbow};

    const level: usize = 12;
    const name: felt252 = 'Peppie';
    const wmClass: u8 = 1;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });


        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pouch::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:5, y:4 },
            rotation: 0,
        });

        items
    }
}

mod Dummy13 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Greatsword, Hammer, AugmentedSword, BladeArmor, Buckler, HealingPotion, MagicWater, KnightHelmet};

    const level: usize = 13;
    const name: felt252 = 'Bubbie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Greatsword::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Hammer::id,
            position: Position{ x:7, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: BladeArmor::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:6, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:5, y:5 },
            rotation: 0,
        });

        items
    }
}

mod Dummy14 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Bow, AugmentedSword, KnightHelmet, SpikeShield, MailArmor, AmuletOfFury, HealingPotion, MagicWater};

    const level: usize = 14;
    const name: felt252 = 'Nettie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:3, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:7, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:6, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:6, y:1 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: SpikeShield::id,
            position: Position{ x:4, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:3, y:3 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: AmuletOfFury::id,
            position: Position{ x:3, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items
    }
}

mod Dummy15 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, PlagueFlower, MailArmor, Buckler, Crossbow, AugmentedSword, HealingPotion, Poison};

    const level: usize = 15;
    const name: felt252 = 'Quillie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:7, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:6, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:7, y:4 },
            rotation: 0,
        });

        items
    }
}

mod Dummy16 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, VampiricArmor, Greatsword, AugmentedDagger, MailArmor, SpikeShield, KnightHelmet, HealingPotion};

    const level: usize = 16;
    const name: felt252 = 'Winkie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: VampiricArmor::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Greatsword::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedDagger::id,
            position: Position{ x:7, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: SpikeShield::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:5, y:2 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items
    }
}

mod Dummy17 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Bow, AugmentedSword, KnightHelmet, BladeArmor, MailArmor, HealingPotion, AmuletOfFury, MagicWater};

    const level: usize = 17;
    const name: felt252 = 'Rennie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:3, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:7, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:4, y:5 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: BladeArmor::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:4, y:3 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:7, y:4 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AmuletOfFury::id,
            position: Position{ x:3, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:6, y:2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy18 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, PlagueFlower, MailArmor, VampiricArmor, AugmentedSword, Bow, Poison, HealingPotion};

    const level: usize = 18;
    const name: felt252 = 'Huggie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:6, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:4, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: VampiricArmor::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:5, y:3 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:2, y:2 },
            rotation: 90,
        });

        items.append(PredefinedItem {
            itemId: Poison::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:5, y:2 },
            rotation: 0,
        });

        items
    }
}

mod Dummy19 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Greatsword, BladeArmor, AugmentedSword, Hammer, KnightHelmet, RageGauntlet, AmuletOfFury, Buckler, HealingPotion, Helmet, MagicWater};

    const level: usize = 19;
    const name: felt252 = 'Dottie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Greatsword::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: BladeArmor::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Hammer::id,
            position: Position{ x:7, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: RageGauntlet::id,
            position: Position{ x:3, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AmuletOfFury::id,
            position: Position{ x:6, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Buckler::id,
            position: Position{ x:4, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: HealingPotion::id,
            position: Position{ x:4, y:6 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Helmet::id,
            position: Position{ x:5, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:5, y:6 },
            rotation: 0,
        });

        items
    }
}

mod Dummy20 {
    use warpack_masters::models::Character::{WMClass};
    use warpack_masters::models::CharacterItem::Position;
    use super::PredefinedItem;
    use warpack_masters::items::{Backpack, Pack, Satchel, Bow, AugmentedSword, Crossbow, PlagueFlower, VampiricArmor, MailArmor, AmuletOfFury, MagicWater, KnightHelmet};

    const level: usize = 20;
    const name: felt252 = 'Quackie';
    const wmClass: u8 = 0;
    const health: usize = 80;

    fn get_items() -> Array<PredefinedItem> {
        let mut items: Array<PredefinedItem> = array![];
        items.append(PredefinedItem {
            itemId: Backpack::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:6, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Pack::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Satchel::id,
            position: Position{ x:6, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:2, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Bow::id,
            position: Position{ x:3, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AugmentedSword::id,
            position: Position{ x:2, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: Crossbow::id,
            position: Position{ x:3, y:3 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: PlagueFlower::id,
            position: Position{ x:4, y:0 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: VampiricArmor::id,
            position: Position{ x:4, y:2 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MailArmor::id,
            position: Position{ x:6, y:1 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: AmuletOfFury::id,
            position: Position{ x:3, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:7, y:4 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: MagicWater::id,
            position: Position{ x:7, y:5 },
            rotation: 0,
        });

        items.append(PredefinedItem {
            itemId: KnightHelmet::id,
            position: Position{ x:4, y:5 },
            rotation: 0,
        });

        items
    }
}