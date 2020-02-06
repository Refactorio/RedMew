local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Popup = require 'features.gui.popup'

local config = global.config

local degrees = require 'utils.math'.degrees

local groundhog_mode = false -- Toggle to enable groundhogs

local seed = 210
RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none
    }
)

RestrictEntities.add_banned(
    {
        'inserter',
        'long-handed-inserter',
        'fast-inserter',
        'filter-inserter',
        'stack-inserter',
        'stack-filter-inserter',
        'electric-mining-drill'
    }
)

-- config changes
config.hail_hydra.enabled = true
config.autodeconstruct.enabled = false
config.redmew_qol.loaders = false

Event.add(
    defines.events.on_research_finished,
    function(event)
        local effects = event.research.effects
        local f = game.forces.player

        for _, e in pairs(effects) do
            local t = e.type
            if t == 'stack-inserter-capacity-bonus' then
                f.inserter_stack_size_bonus = f.inserter_stack_size_bonus + e.modifier
            end
        end
    end
)

Event.add(
    RestrictEntities.events.on_restricted_entity_destroyed,
    function(event)
        local p = event.player
        if not p or not p.valid then
            return
        end

        if not event.ghost then
            Popup.player(p, [[
                You don't know how to operate this item!

                Advice: Only burner inserters and burner mining drills work in this prehistoric land
                ]], nil, nil, 'prehistoric_entity_warning')
        end
    end
)

-- Map

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

local land_dino_count = 8
local ore_dino_start = 9
local dinos = {dino1, dino2, dino4, dino7, dino9, dino13, dino14, dino16}

if groundhog_mode then
    local groundhog1 = b.picture(b.decompress(require 'map_gen.data.presets.groundhog1'))
    local groundhog2 = b.picture(b.decompress(require 'map_gen.data.presets.groundhog2'))
    local groundhog3 = b.picture(b.decompress(require 'map_gen.data.presets.groundhog3'))
    local groundhog4 = b.picture(b.decompress(require 'map_gen.data.presets.groundhog4'))
    local groundhog5 = b.picture(b.decompress(require 'map_gen.data.presets.groundhog5'))

    table.add_all(dinos, {groundhog1, groundhog2, groundhog3, groundhog4, groundhog5})

    land_dino_count = 13
    ore_dino_start = 14
end

table.add_all(dinos, {dino17, dino18, dino19, dino20, dino21, dino22})

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
    {transform = non_transform, resource = 'iron-ore', value = value(300, 0.425, 1.1), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(250, 0.425, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(150, 0.2, 1.05), weight = 6},
    {transform = non_transform, resource = 'coal', value = value(250, 0.25, 1.075), weight = 16},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(50000, 50, 1.025), weight = 10},
    {transform = empty_transform, weight = 65}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in pairs(ores) do
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
