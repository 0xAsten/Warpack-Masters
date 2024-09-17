use warpack_masters::models::item::ItemRarity;

mod Backpack {
    const id: usize = 1;
    const name: felt252 = 'Backpack';
    const itemType: u8 = 4;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 10;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 0;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::None;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Pack {
    const id: usize = 2;
    const name: felt252 = 'Pack';
    const itemType: u8 = 4;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 4;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 0;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Satchel {
    const id: usize = 3;
    const name: felt252 = 'Satchel';
    const itemType: u8 = 4;
    const width: usize = 2;
    const height: usize = 1;
    const price: usize = 3;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 0;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Pouch {
    const id: usize = 4;
    const name: felt252 = 'Pouch';
    const itemType: u8 = 4;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 0;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Herb {
    const id: usize = 5;
    const name: felt252 = 'Herb';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 1;
    const regenActivation: u8 = 1;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Dagger {
    const id: usize = 6;
    const name: felt252 = 'Dagger';
    const itemType: u8 = 1;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const damage: usize = 3;
    const cleansePoison: usize = 0;
    const chance: usize = 90;
    const cooldown: u8 = 4;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 20;
}

mod Sword {
    const id: usize = 7;
    const name: felt252 = 'Sword';
    const itemType: u8 = 1;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 2;
    const damage: usize = 5;
    const cleansePoison: usize = 0;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 30;
}

mod Spike {
    const id: usize = 8;
    const name: felt252 = 'Spike';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 2;
    const reflectActivation: u8 = 1;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Shield {
    const id: usize = 9;
    const name: felt252 = 'Shield';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 3;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 12;
    const armorActivation: u8 = 1;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Helmet {
    const id: usize = 10;
    const name: felt252 = 'Helmet';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 3;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 50;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 2;
    const armorActivation: u8 = 2;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod HealingPotion {
    const id: usize = 11;
    const name: felt252 = 'Healing Potion';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 4;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 2;
    const regenActivation: u8 = 1;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod LeatherArmor {
    const id: usize = 12;
    const name: felt252 = 'Leather Armor';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 6;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 25;
    const armorActivation: u8 = 1;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Poison {
    const id: usize = 13;
    const name: felt252 = 'Poison';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 5;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 2;
    const poisonActivation: u8 = 1;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod AugmentedSword {
    const id: usize = 14;
    const name: felt252 = 'Augmented Sword';
    const itemType: u8 = 1;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 6;
    const damage: usize = 8;
    const cleansePoison: usize = 0;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 30;
}

mod AugmentedDagger {
    const id: usize = 15;
    const name: felt252 = 'Augmented Dagger';
    const itemType: u8 = 1;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 6;
    const damage: usize = 5;
    const cleansePoison: usize = 0;
    const chance: usize = 90;
    const cooldown: u8 = 4;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 20;
}

mod SpikeShield {
    const id: usize = 16;
    const name: felt252 = 'Spike Shield';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 7;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 75;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 2;
    const reflectActivation: u8 = 2;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod PlagueFlower {
    const id: usize = 17;
    const name: felt252 = 'Plague Flower';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 12;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 80;
    const cooldown: u8 = 4;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 3;
    const poisonActivation: u8 = 3;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod MailArmor {
    const id: usize = 18;
    const name: felt252 = 'Mail Armor';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 12;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 55;
    const armorActivation: u8 = 1;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}


mod Buckler {
    const id: usize = 19;
    const name: felt252 = 'Buckler';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 8;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 70;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 5;
    const armorActivation: u8 = 2;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod MagicWater {
    const id: usize = 20;
    const name: felt252 = 'Magic Water';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 4;
    const damage: usize = 0;
    const cleansePoison: usize = 5;
    const chance: usize = 90;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod VampiricArmor {
    const id: usize = 21;
    const name: felt252 = 'Vampiric Armor';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 12;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 55;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 2;
    const vampirismActivation: u8 = 2;
    const energyCost: u8 = 0;
}

mod Greatsword {
    const id: usize = 22;
    const name: felt252 = 'Greatsword';
    const itemType: u8 = 1;
    const width: usize = 2;
    const height: usize = 4;
    const price: usize = 8;
    const damage: usize = 20;
    const cleansePoison: usize = 0;
    const chance: usize = 70;
    const cooldown: u8 = 7;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 60;
}

mod Bow {
    const id: usize = 23;
    const name: felt252 = 'Bow';
    const itemType: u8 = 2;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 6;
    const damage: usize = 10;
    const cleansePoison: usize = 0;
    const chance: usize = 90;
    const cooldown: u8 = 7;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 25;
}

mod Crossbow {
    const id: usize = 24;
    const name: felt252 = 'Crossbow';
    const itemType: u8 = 2;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const damage: usize = 3;
    const cleansePoison: usize = 0;
    const chance: usize = 90;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 15;
}

mod Hammer {
    const id: usize = 25;
    const name: felt252 = 'Hammer';
    const itemType: u8 = 1;
    const width: usize = 1;
    const height: usize = 4;
    const price: usize = 3;
    const damage: usize = 10;
    const cleansePoison: usize = 0;
    const chance: usize = 70;
    const cooldown: u8 = 7;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 45;
}

mod AmuletOfFury {
    const id: usize = 26;
    const name: felt252 = 'Amulet of Fury';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 7;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 75;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 2;
    const empowerActivation: u8 = 2;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod RageGauntlet {
    const id: usize = 27;
    const name: felt252 = 'Rage Gauntlet';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 4;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 65;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 1;
    const empowerActivation: u8 = 4;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod KnightHelmet {
    const id: usize = 28;
    const name: felt252 = 'Knight Helmet';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 10;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 3;
    const empowerActivation: u8 = 3;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod BladeArmor {
    const id: usize = 29;
    const name: felt252 = 'Blade Armor';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 10;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 5;
    const reflectActivation: u8 = 3;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 0;
}

mod Club {
    const id: usize = 30;
    const name: felt252 = 'Club';
    const itemType: u8 = 2;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const damage: usize = 6;
    const cleansePoison: usize = 0;
    const chance: usize = 70;
    const cooldown: u8 = 6;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 35;
}

mod Fang {
    const id: usize = 31;
    const name: felt252 = 'Fang';
    const itemType: u8 = 3;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 3;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Common;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 1;
    const vampirismActivation: u8 = 1;
    const energyCost: u8 = 0;
}

mod ScarletCloak {
    const id: usize = 32;
    const name: felt252 = 'Scarlet Cloak';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 6;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 45;
    const cooldown: u8 = 0;
    const rarity: u8 = ItemRarity::Rare;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 1;
    const vampirismActivation: u8 = 4;
    const energyCost: u8 = 0;
}

mod DraculaGrimoire {
    const id: usize = 33;
    const name: felt252 = 'Dracula Grimoire';
    const itemType: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 12;
    const damage: usize = 0;
    const cleansePoison: usize = 0;
    const chance: usize = 65;
    const cooldown: u8 = 8;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 2;
    const vampirismActivation: u8 = 3;
    const energyCost: u8 = 0;
}

mod Longbow {
    const id: usize = 34;
    const name: felt252 = 'Longbow';
    const itemType: u8 = 2;
    const width: usize = 1;
    const height: usize = 4;
    const price: usize = 10;
    const damage: usize = 15;
    const cleansePoison: usize = 0;
    const chance: usize = 90;
    const cooldown: u8 = 7;
    const rarity: u8 = ItemRarity::Legendary;
    const armor: usize = 0;
    const armorActivation: u8 = 0;
    const regen: usize = 0;
    const regenActivation: u8 = 0;
    const reflect: usize = 0;
    const reflectActivation: u8 = 0;
    const poison: usize = 0;
    const poisonActivation: u8 = 0;
    const empower: usize = 0;
    const empowerActivation: u8 = 0;
    const vampirism: usize = 0;
    const vampirismActivation: u8 = 0;
    const energyCost: u8 = 35;
}
