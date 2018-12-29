local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Random = require 'map_gen.shared.random'
local degrees = require "utils.math".degrees

local seed = 1000

Event.on_init(
    function()
        local rs = game.forces.player.recipes

        rs['electric-mining-drill'].enabled = false
        rs['inserter'].enabled = false
    end
)

Event.add(
    defines.events.on_research_finished,
    function(event)
        local effects = event.research.effects
        local f = game.forces.player
        local rs = f.recipes

        for _, e in ipairs(effects) do
            local t = e.type
            if t == 'unlock-recipe' then
                local rn = e.recipe
                if rn:find('inserter') then
                    rs[rn].enabled = false
                end
            elseif t == 'stack-inserter-capacity-bonus' then
                f.inserter_stack_size_bonus = f.inserter_stack_size_bonus + e.modifier
            end
        end
    end
)

local dino1 = b.picture(require 'map_gen.data.presets.dino1')
local dino2 = b.picture(require 'map_gen.data.presets.dino2')
local dino4 = b.picture(require 'map_gen.data.presets.dino4')
local dino7 = b.picture(require 'map_gen.data.presets.dino7')
local dino9 = b.picture(require 'map_gen.data.presets.dino9')
local dino13 = b.picture(require 'map_gen.data.presets.dino13')
local dino14 = b.picture(require 'map_gen.data.presets.dino14')
local dino16 = b.picture(require 'map_gen.data.presets.dino16')

local dino17 = b.picture(require 'map_gen.data.presets.dino17')
local dino18 = b.picture(require 'map_gen.data.presets.dino18')
local dino19 = b.picture(require 'map_gen.data.presets.dino19')
local dino20 = b.picture(require 'map_gen.data.presets.dino20')
local dino21 = b.picture(require 'map_gen.data.presets.dino21')
local dino22 = b.picture(require 'map_gen.data.presets.dino22')

local dinos = {
    dino1,
    dino2,
    dino4,
    dino7,
    dino9,
    dino13,
    dino14,
    dino16,
    dino17,
    dino18,
    dino19,
    dino20,
    dino21,
    dino22
}
local land_dino_count = 8
local ore_dino_start = 9
local ore_dino_end = #dinos

local random = Random.new(seed, seed * 2)

local land_pattern = {}
for r = 1, 50 do
    local row = {}
    land_pattern[r] = row
    for c = 1, 50 do
        local x = random:next_int(-256, 256)
        local y = random:next_int(-256, 256)
        local d = random:next_int(0, 360)
        local i = random:next_int(1, land_dino_count)

        local shape = dinos[i]
        shape = b.rotate(shape, degrees(d))
        shape = b.translate(shape, x, y)

        row[c] = shape
    end
end

local function value(base, mult, pow)
    return function(x, y)
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local function non_transform(shape)
    return b.scale(shape, 0.5)
end

local function uranium_transform(shape)
    return b.scale(shape, 0.25)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.25)
    return b.throttle_world_xy(shape, 1, 4, 1, 4)
end

local function empty_transform()
    return b.empty_shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 6},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 16},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50, 1.025), weight = 10},
    {transform = empty_transform, weight = 10}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local ore_pattern = {}

for r = 1, 50 do
    local row = {}
    ore_pattern[r] = row
    for c = 1, 50 do
        local x = random:next_int(-32, 32)
        local y = random:next_int(-32, 32)
        local d = random:next_int(0, 360)
        local i = random:next_int(ore_dino_start, ore_dino_end)
        local shape = dinos[i]

        local ore_data
        i = random:next_int(1, ore_t)
        local index = table.binary_search(total_ore_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        ore_data = ores[index]

        shape = ore_data.transform(shape)
        shape = b.rotate(shape, degrees(d))
        shape = b.translate(shape, x, y)
        local ore = b.resource(shape, ore_data.resource, ore_data.value)

        row[c] = ore
    end
end

local map = b.grid_pattern_full_overlap(land_pattern, 50, 50, 640, 640)
map = b.change_tile(map, false, 'deepwater')
map = b.fish(map, 0.0025)

ores = b.grid_pattern_full_overlap(ore_pattern, 50, 50, 128, 128)
map = b.apply_entity(map, ores)

map = b.translate(map, -50, -160)

return map
