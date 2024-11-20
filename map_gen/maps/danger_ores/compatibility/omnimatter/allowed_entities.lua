local entities =  {
  -- belts
  'basic-transport-belt',
  'transport-belt',
  'fast-transport-belt',
  'express-transport-belt',
  -- undergrounds
  'basic-underground-belt',
  'underground-belt',
  'fast-underground-belt',
  'express-underground-belt',
  -- pipes
  'pipe',
  'pipe-to-ground',
  -- poles
  'small-electric-pole',
  'small-iron-electric-pole',
  'small-omnium-electric-pole',
  'medium-electric-pole',
  'big-electric-pole',
  'substation',
  -- drills
  'electric-mining-drill',
  'burner-mining-drill',
  -- vehicles
  'car',
  'tank',
  'spidertron',
  -- rails
  'straight-rail',
  'curved-rail',
  'rail-signal',
  'rail-chain-signal',
  'train-stop',
  'locomotive',
  'cargo-wagon',
  'fluid-wagon',
  'artillery-wagon',
}

local list = {}
for _, e in pairs(entities) do
  table.insert(list, e)
  table.insert(list, e .. '-compressed-compact')
  table.insert(list, e .. '-compressed-nanite')
  table.insert(list, e .. '-compressed-quantum')
  table.insert(list, e .. '-compressed-singularity')
end

return list
