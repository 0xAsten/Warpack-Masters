const fs = require('fs')
const path = require('path')

const { shortString } = require('starknet')

const itemsFilePath = path.join(__dirname, '../src/items.cairo')
const outputFilePath = path.join(__dirname, '../scripts/add_item.sh')

// Read the Items.cairo file
const itemsFileContent = fs.readFileSync(itemsFilePath, 'utf8')

// Extract item data
const itemRegex = /mod\s+(\w+)\s*{([\s\S]*?)}/g
const items = []
let match
while ((match = itemRegex.exec(itemsFileContent)) !== null) {
  const itemName = match[1]
  const itemData = match[2]

  const item = { name: itemName }
  const dataRegex = /const\s+(\w+):\s+\w+\s*=\s*([^;]+);/g
  let dataMatch
  while ((dataMatch = dataRegex.exec(itemData)) !== null) {
    item[dataMatch[1]] = dataMatch[2].trim()
  }
  // remove name signle quotes
  item.name = item.name.replace(/'/g, '')
  item.name = shortString.encodeShortString(item.name)
  items.push(item)
}

// Generate the shell script commands
const commands = items
  .map((item) => {
    const {
      id,
      name,
      itemType,
      width,
      height,
      price,
      damage,
      cleansePoison,
      chance,
      cooldown,
      rarity,
      armor,
      armorActivation,
      regen,
      regenActivation,
      reflect,
      reflectActivation,
      poison,
      poisonActivation,
      empower,
      empowerActivation,
      vampirism,
      vampirismActivation,
      energyCost,
    } = item
    return `sozo execute --world $WORLD_ADDRESS $ITEM_STSTEM_ADDRESS add_item -c ${id},${name},${itemType},${width},${height},${price},${damage},${cleansePoison},${chance},${cooldown},${rarity},${armor},${armorActivation},${regen},${regenActivation},${reflect},${reflectActivation},${poison},${poisonActivation},${empower},${empowerActivation},${vampirism},${vampirismActivation},${energyCost} --wait --rpc-url $STARKNET_RPC_URL`
  })
  .join('\n')

// Read the existing shell script content
let shellScriptContent = fs.readFileSync(outputFilePath, 'utf8')

// Append the generated commands to the shell script
shellScriptContent += `\n\n# Generated item commands\n${commands}\n`

// Write the updated content to the shell script
fs.writeFileSync(outputFilePath, shellScriptContent)

console.log(`Successfully added ${items.length} item commands to add_item.sh`)
