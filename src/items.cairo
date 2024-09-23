
mod Backpack {
    const id: usize = 1;
    const name: felt252 = 'Backpack';
    const itemType: u8 = 4;
    const rarity: u8 = 0;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 10;
    const effectType: u8 = 9;
    const effectStacks: u32 = 6;
    const effectActivationType: u8 = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Pack {
    const id: usize = 2;
    const name: felt252 = 'Pack';
    const itemType: u8 = 4;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 4;
    const effectType: u8 = 9;
    const effectStacks: u32 = 4;
    const effectActivationType: u8 = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Satchel {
    const id: usize = 3;
    const name: felt252 = 'Satchel';
    const itemType: u8 = 4;
    const rarity: u8 = 1;
    const width: usize = 2;
    const height: usize = 1;
    const price: usize = 3;
    const effectType: u8 = 9;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Pouch {
    const id: usize = 4;
    const name: felt252 = 'Pouch';
    const itemType: u8 = 4;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const effectType: u8 = 9;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Herb {
    const id: usize = 5;
    const name: felt252 = 'Herb';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const effectType: u8 = 4;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Dagger {
    const id: usize = 6;
    const name: felt252 = 'Dagger';
    const itemType: u8 = 1;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const effectType: u8 = 1;
    const effectStacks: u32 = 3;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 4;
    const energyCost: u8 = 20;
    const isPlugin: bool = false;
}
          

mod Sword {
    const id: usize = 7;
    const name: felt252 = 'Sword';
    const itemType: u8 = 1;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 2;
    const effectType: u8 = 1;
    const effectStacks: u32 = 5;
    const effectActivationType: u8 = 3;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const energyCost: u8 = 30;
    const isPlugin: bool = false;
}
          

mod Spike {
    const id: usize = 8;
    const name: felt252 = 'Spike';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 2;
    const effectType: u8 = 5;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Shield {
    const id: usize = 9;
    const name: felt252 = 'Shield';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 3;
    const effectType: u8 = 3;
    const effectStacks: u32 = 15;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Helmet {
    const id: usize = 10;
    const name: felt252 = 'Helmet';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 3;
    const effectType: u8 = 3;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 2;
    const chance: usize = 50;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod HealingPotion {
    const id: usize = 11;
    const name: felt252 = 'Healing Potion';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 4;
    const effectType: u8 = 4;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod LeatherArmor {
    const id: usize = 12;
    const name: felt252 = 'Leather Armor';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 5;
    const effectType: u8 = 3;
    const effectStacks: u32 = 25;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Poison {
    const id: usize = 13;
    const name: felt252 = 'Poison';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 5;
    const effectType: u8 = 6;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 0;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = true;
}
          

mod AugmentedSword {
    const id: usize = 14;
    const name: felt252 = 'Augmented Sword';
    const itemType: u8 = 1;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 6;
    const effectType: u8 = 1;
    const effectStacks: u32 = 8;
    const effectActivationType: u8 = 3;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const energyCost: u8 = 30;
    const isPlugin: bool = false;
}
          

mod AugmentedDagger {
    const id: usize = 15;
    const name: felt252 = 'Augmented Dagger';
    const itemType: u8 = 1;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 6;
    const effectType: u8 = 1;
    const effectStacks: u32 = 5;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 4;
    const energyCost: u8 = 20;
    const isPlugin: bool = false;
}
          

mod SpikeShield {
    const id: usize = 16;
    const name: felt252 = 'Spike Shield';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 7;
    const effectType: u8 = 5;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 2;
    const chance: usize = 75;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod PlagueFlower {
    const id: usize = 17;
    const name: felt252 = 'Plague Flower';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 12;
    const effectType: u8 = 6;
    const effectStacks: u32 = 3;
    const effectActivationType: u8 = 0;
    const chance: usize = 80;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = true;
}
          

mod MailArmor {
    const id: usize = 18;
    const name: felt252 = 'Mail Armor';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 12;
    const effectType: u8 = 3;
    const effectStacks: u32 = 55;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Buckler {
    const id: usize = 19;
    const name: felt252 = 'Buckler';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 8;
    const effectType: u8 = 3;
    const effectStacks: u32 = 5;
    const effectActivationType: u8 = 2;
    const chance: usize = 70;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod MagicWater {
    const id: usize = 20;
    const name: felt252 = 'Magic Water';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 4;
    const effectType: u8 = 2;
    const effectStacks: u32 = 5;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 5;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod VampiricArmor {
    const id: usize = 21;
    const name: felt252 = 'Vampiric Armor';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 12;
    const effectType: u8 = 8;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 2;
    const chance: usize = 55;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Greatsword {
    const id: usize = 22;
    const name: felt252 = 'Greatsword';
    const itemType: u8 = 1;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 4;
    const price: usize = 8;
    const effectType: u8 = 1;
    const effectStacks: u32 = 20;
    const effectActivationType: u8 = 3;
    const chance: usize = 70;
    const cooldown: u8 = 7;
    const energyCost: u8 = 60;
    const isPlugin: bool = false;
}
          

mod Bow {
    const id: usize = 23;
    const name: felt252 = 'Bow';
    const itemType: u8 = 2;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 3;
    const price: usize = 6;
    const effectType: u8 = 1;
    const effectStacks: u32 = 10;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 7;
    const energyCost: u8 = 25;
    const isPlugin: bool = false;
}
          

mod Crossbow {
    const id: usize = 24;
    const name: felt252 = 'Crossbow';
    const itemType: u8 = 2;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const effectType: u8 = 1;
    const effectStacks: u32 = 3;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 5;
    const energyCost: u8 = 15;
    const isPlugin: bool = false;
}
          

mod Hammer {
    const id: usize = 25;
    const name: felt252 = 'Hammer';
    const itemType: u8 = 1;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 4;
    const price: usize = 3;
    const effectType: u8 = 1;
    const effectStacks: u32 = 10;
    const effectActivationType: u8 = 3;
    const chance: usize = 70;
    const cooldown: u8 = 7;
    const energyCost: u8 = 45;
    const isPlugin: bool = false;
}
          

mod AmuletOfFury {
    const id: usize = 26;
    const name: felt252 = 'Amulet of Fury';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 5;
    const effectType: u8 = 7;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 0;
    const chance: usize = 65;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = true;
}
          

mod RageGauntlet {
    const id: usize = 27;
    const name: felt252 = 'Rage Gauntlet';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 7;
    const effectType: u8 = 7;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 0;
    const chance: usize = 45;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = true;
}
          

mod KnightHelmet {
    const id: usize = 28;
    const name: felt252 = 'Knight Helmet';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 10;
    const effectType: u8 = 7;
    const effectStacks: u32 = 3;
    const effectActivationType: u8 = 0;
    const chance: usize = 50;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = true;
}
          

mod BladeArmor {
    const id: usize = 29;
    const name: felt252 = 'Blade Armor';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 2;
    const height: usize = 3;
    const price: usize = 10;
    const effectType: u8 = 5;
    const effectStacks: u32 = 5;
    const effectActivationType: u8 = 3;
    const chance: usize = 80;
    const cooldown: u8 = 5;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Club {
    const id: usize = 30;
    const name: felt252 = 'Club';
    const itemType: u8 = 2;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 2;
    const price: usize = 2;
    const effectType: u8 = 1;
    const effectStacks: u32 = 6;
    const effectActivationType: u8 = 3;
    const chance: usize = 70;
    const cooldown: u8 = 6;
    const energyCost: u8 = 35;
    const isPlugin: bool = false;
}
          

mod Fang {
    const id: usize = 31;
    const name: felt252 = 'Fang';
    const itemType: u8 = 3;
    const rarity: u8 = 1;
    const width: usize = 1;
    const height: usize = 1;
    const price: usize = 3;
    const effectType: u8 = 8;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 1;
    const chance: usize = 100;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod ScarletCloak {
    const id: usize = 32;
    const name: felt252 = 'Scarlet Cloak';
    const itemType: u8 = 3;
    const rarity: u8 = 2;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 6;
    const effectType: u8 = 8;
    const effectStacks: u32 = 1;
    const effectActivationType: u8 = 4;
    const chance: usize = 45;
    const cooldown: u8 = 0;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod DraculaGrimoire {
    const id: usize = 33;
    const name: felt252 = 'Dracula Grimoire';
    const itemType: u8 = 3;
    const rarity: u8 = 3;
    const width: usize = 2;
    const height: usize = 2;
    const price: usize = 12;
    const effectType: u8 = 8;
    const effectStacks: u32 = 2;
    const effectActivationType: u8 = 3;
    const chance: usize = 65;
    const cooldown: u8 = 8;
    const energyCost: u8 = 0;
    const isPlugin: bool = false;
}
          

mod Longbow {
    const id: usize = 34;
    const name: felt252 = 'Longbow';
    const itemType: u8 = 2;
    const rarity: u8 = 3;
    const width: usize = 1;
    const height: usize = 4;
    const price: usize = 10;
    const effectType: u8 = 1;
    const effectStacks: u32 = 15;
    const effectActivationType: u8 = 3;
    const chance: usize = 90;
    const cooldown: u8 = 7;
    const energyCost: u8 = 35;
    const isPlugin: bool = false;
}
          