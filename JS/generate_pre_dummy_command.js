const fs = require('fs')
const path = require('path')

const { shortString } = require('starknet')

function extractData(content, regex) {
  const match = content.match(regex)
  return match ? match[1] : null
}

const predefinedDummiesContent = fs.readFileSync(
  '../src/prdefined_dummies.cairo',
  'utf-8',
)

const itemsContent = fs.readFileSync('../src/items.cairo', 'utf-8')

const itemIds = {}
const itemRegex = /mod (\w+) \{[\s\S]+?const id: usize = (\d+);/g
let match
while ((match = itemRegex.exec(itemsContent)) !== null) {
  itemIds[match[1]] = match[2]
}

const dummyRegex =
  /mod\s+Dummy(\d+)\s*{([\s\S]+?)fn\s+get_items\(\)\s*->\s*Array<PredefinedItem>\s*{([\s\S]+?)}\s*}/g

const itemDetailsRegex =
  /items.append\(PredefinedItem\s*{\s*itemId:\s*(\w+)::id,[\s\S]+?position:\s*Position\s*{\s*x:\s*(\d+),\s*y:\s*(\d+)\s*},[\s\S]+?rotation:\s*(\d+)/g

const levelRegex = /const\s+level:\s+usize\s+=\s+(\d+);/
const nameRegex = /const\s+name:\s+felt252\s+=\s+'([^']+)';/
const wmClassRegex = /const\s+wmClass:\s+WMClass\s+=\s+WMClass::([a-zA-Z]+);/

const wmClassMap = {
  'Warrior': 0,
  'Warlock': 1,
  'Archer': 2,
};

let commands = ''
while ((match = dummyRegex.exec(predefinedDummiesContent)) !== null) {
  const dummyContent = match[2]

  const levelMatch = dummyContent.match(levelRegex)
  const nameMatch = dummyContent.match(nameRegex)
  const wmClassMatch = dummyContent.match(wmClassRegex)

  const level = levelMatch ? levelMatch[1] : null
  const name = nameMatch ? nameMatch[1] : null
  const wmClass = wmClassMatch ? wmClassMap[wmClassMatch[1]] : null

  const encodedName = shortString.encodeShortString(name)

  let itemDetails = ''
  let itemCount = 0
  let itemMatch

  while ((itemMatch = itemDetailsRegex.exec(match[3])) !== null) {
    const itemId = itemIds[itemMatch[1]]
    const x = itemMatch[2]
    const y = itemMatch[3]
    const rotation = itemMatch[4]

    itemDetails += `${itemId},${x},${y},${rotation},0,`
    itemCount++
  }

  // Remove the trailing comma from itemDetails
  itemDetails = itemDetails.slice(0, -1)
  console.log(itemDetails)

  // Construct the command line
  const commandLine = `sozo execute --world $WORLD_ADDRESS $DUMMY_STSTEM_ADDRESS prefine_dummy -c ${level},${encodedName},${wmClass},${itemCount},${itemDetails} --wait --rpc-url $STARKNET_RPC_URL`

  commands += `${commandLine}\n`
  // Output the constructed command line
  //   console.log(commandLine)
}

const outputFilePath = path.join(__dirname, '../scripts/pre_dummies.sh')
let shellScriptContent = fs.readFileSync(outputFilePath, 'utf8')
shellScriptContent += `\n\n# Generated pre dummies commands\n${commands}\n`

fs.writeFileSync(outputFilePath, shellScriptContent)
