-- Glittery ores, provide a mix value, and all patches outside uranium will be a full mix.
-- Gameplay comment 9/22/2017 -- After a playtest,  we learned that at 1:1 ratio of iron/copper
-- creates a LARGE amount of extra copper from the start. Also a 4:1 ratio for stone is quite heavy.
-- Suggest modifying the sprinkle_factor out of 100% to make for a less game about warehousing ore,
-- to one about picking patches that are mostly the preferred ore, along with a % of the wrong ores.

-- Sets the buffer distance before ores are scrambled
local starting_distance = 125

-- 1-100% chance of sprinkling any individual ore
local sprinkle_factor = 20

local ore_ratios = {
  ["iron-ore"] = 1.0,
  ["coal"] = 0.5,
  ["copper-ore"] = 1,
  ["stone"] = 0.25
}

starting_distance = starting_distance ^ 2

local ore_mix = {}
local ore_mix_max = 0
-- Prime the array
for a, b in pairs(ore_ratios) do
  for i = 1, (b * 1000) do
    ore_mix_max = ore_mix_max + 1
    ore_mix[ore_mix_max] = a
  end
end

return function(_, _, world)
  local d = world.x * world.x + world.y * world.y
  if d <= starting_distance then
    return nil
  end

  local pos = {world.x + 0.5, world.y + 0.5}
  local entities = world.surface.find_entities_filtered {position = pos, type = "resource"}

  for _, entity in ipairs(entities) do
    if ore_ratios[entity.name] ~= nil then
      if sprinkle_factor == 100 or math.random(100) <= sprinkle_factor then
        local amount_old = entity.amount

        entity.destroy()

        return {
          name = ore_mix[math.random(ore_mix_max)],
          amount = amount_old
        }
      end
    end
  end
end
