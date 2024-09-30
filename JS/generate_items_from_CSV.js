const fs = require('fs');
const csv = require('csv-parser');

// Mapping rules
const itemTypeMap = {
  'Melee Weapon': 1,
  'Ranged Weapon': 2,
  'Effect Item': 3,
  'Bag': 4,
};

const rarityMap = {
  'None': 0,
  'Common': 1,
  'Rare': 2,
  'Legendary': 3,
};

const effectTypeMap = {
  'None': 0,
  'Damage': 1,
  'Cleanse Poison': 2,
  'Armor': 3,
  'Regeneration': 4,
  'Reflect': 5,
  'Poison': 6,
  'Empower': 7,
  'Vampirism': 8,
  'Expand pack': 9,
};

const effectActivationTypeMap = {
  'In armory': 0,
  'On start': 1,
  'On hit': 2,
  'On cooldown': 3,
  'On attack': 4,
};

// Convert item name to camelCase (e.g., "Healing Potion" -> "HealingPotion")
function toCamelCase(str) {
  return str
    .split(' ')
    .map((word, index) => 
        index === 0 ? word : word.charAt(0).toUpperCase() + word.slice(1)
    )
    .join('');
}

// Helper function to ensure mapping and raise error if not found
function getMappedValue(map, key, fieldName) {
  if (!map.hasOwnProperty(key)) {
    throw new Error(`Invalid ${fieldName} value: "${key}"`);
  }
  return map[key];
}

// Read CSV and generate items.cairo
function generateCairoFile(csvFilePath, cairoFilePath) {
  const results = [];

  fs.createReadStream(csvFilePath)
    .pipe(csv())
    .on('data', (row) => {
      results.push(row);
    })
    .on('end', () => {
      try {
        const cairoContent = results.map(item => {
          // Ensure all mappings are valid or raise error
          const itemType = getMappedValue(itemTypeMap, item.itemType, 'itemType');
          const rarity = getMappedValue(rarityMap, item.rarity, 'rarity');
          const effectType = getMappedValue(effectTypeMap, item.effectType, 'effectType');
          const effectActivationType = getMappedValue(effectActivationTypeMap, item.effectActivationType, 'effectActivationType');
          const chance = parseFloat(item.chance); // Convert 100.00% to an integer

          const modName = toCamelCase(item.name); // Convert name to camelCase

          return `
mod ${modName} {
    const id: usize = ${item.id};
    const name: felt252 = '${item.name}';
    const itemType: u8 = ${itemType};
    const rarity: u8 = ${rarity};
    const width: usize = ${item.width};
    const height: usize = ${item.height};
    const price: usize = ${item.price};
    const effectType: u8 = ${effectType};
    const effectStacks: u32 = ${item.effectStacks};
    const effectActivationType: u8 = ${effectActivationType};
    const chance: usize = ${chance};
    const cooldown: u8 = ${item.cooldown.replace(' sec', '')};
    const energyCost: u8 = ${item.energyCost};
    const isPlugin: bool = ${item.isPlugin === 'TRUE' ? 'true' : 'false'};
}
          `;
        }).join('\n');

        fs.writeFileSync(cairoFilePath, cairoContent);
        console.log(`Cairo file generated at ${cairoFilePath}`);
      } catch (error) {
        console.error(`Error generating Cairo file: ${error.message}`);
      }
    });
}

// Generate Cairo file from CSV
generateCairoFile('../src/Warpacks-Items.csv', '../src/items.cairo');