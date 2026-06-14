local DOC = require 'map_gen.maps.danger_ores.configuration'
local Event = require 'utils.event'
local Global = require 'utils.global'
local PictureBuilder = require 'map_gen.maps.danger_ores.modules.picture_builder'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local Task = require 'utils.task'
local Token = require 'utils.token'
local b = require 'map_gen.shared.builders'
local math = require 'utils.math'
local table = require 'utils.table'
local random = math.random

local spawn_locations = {} --[[@as [player_index] --> MapPosition]]
Global.register(spawn_locations, function(tbl) spawn_locations = tbl end)

ScenarioInfo.set_map_name('Danger Ores - Joker')
ScenarioInfo.add_map_extra_info([[
    [font=heading-1][color=orange]"The only sensible way to live in this world... is without rules."[/color][/font]

    You arrive on a world that should never have existed. The veins of the land have twisted together into a chaotic mass, as if the planet itself is laughing at the concept of order. Nothing is pure. Nothing is predictable. Everything is tainted.

    Four territories encircle the central wasteland, each marked by a different suit — Clubs, Hearts, Spades, Diamonds — four fragments of a broken deck scattered across a poisoned world.

    Beyond these fractured beginnings, rail lines snake through the dust like old scars, laid long before you arrived. They lead outward into the dark... but never back.

    Welcome to the scenario.
    Welcome to the joke you can't escape.
]])

DOC.scenario_name = 'danger-ore-joker'
DOC.concrete_on_landfill.enabled = false
DOC.terraforming.start_size = 2 * (512 + 32 * 0) -- # of chunks outside starting area
DOC.terraforming.min_pollution = 200
DOC.map_config.enemy_starting_radius = 512 * math.sqrt2 + 128
DOC.map_config.enemy_scale_factor = 64
DOC.map_config.main_ores_rotate = nil
DOC.map_config.main_ores = require 'map_gen.maps.danger_ores.config.joker_outer_area'
DOC.map_config.main_ores_builder = require 'map_gen.maps.danger_ores.modules.main_ores_exclusive_shapes'
DOC.radioactivity.enabled = true

local remnants = require 'resources.remnants'
local wrecks = {
    { weight = 01, name = 'bulk-inserter' },
    { weight = 01, name = 'passive-provider-chest' },
    { weight = 01, name = 'storage-chest' },
    { weight = 04, name = 'fast-inserter' },
    { weight = 04, name = 'fast-transport-belt' },
    { weight = 04, name = 'fast-underground-belt' },
    { weight = 04, name = 'medium-electric-pole' },
    { weight = 04, name = 'steel-chest' },
    { weight = 04, name = 'wooden-chest' },
    { weight = 16, name = 'burner-inserter' },
    { weight = 16, name = 'gate' },
    { weight = 16, name = 'long-handed-inserter' },
    { weight = 32, name = 'inserter' },
    { weight = 32, name = 'iron-chest' },
    { weight = 32, name = 'pipe-to-ground' },
    { weight = 64, name = 'pipe' },
    { weight = 64, name = 'small-electric-pole' },
    { weight = 64, name = 'stone-wall' },
    { weight = 64, name = 'transport-belt' },
    { weight = 64, name = 'underground-belt' },
}
local weighted_wrecks = b.prepare_weighted_array(wrecks)

local artifacts = function(shape)
    local remnants_shape = function()
        if random(128) == 1 then
            return { name = remnants[random(#remnants)], force = 'neutral' }
        end
    end

    local wrecks_shape = function()
        if random(1024) == 1 then
            local i = random() * weighted_wrecks.total
            local index = table.binary_search(weighted_wrecks, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            return { name = wrecks[index].name, force = 'player' }
        end
    end

    return b.apply_entities(shape, { wrecks_shape, remnants_shape })
end

local water = b.fish(b.change_tile(b.rectangle(1024), true, 'water'), 0.05)
water = b.subtract(water, b.rectangle(984))
water = b.add(water, b.change_tile(b.rectangle(984), true, 'nuclear-ground'))
water = b.subtract(water, b.rectangle(982)) -- 1 tile offset in each direction to allow offshore pumps at the corners
water = b.subtract(water, b.any{ b.rectangle(1024, 832), b.rectangle(832, 1024) })

local poker_starts = {}

local function start_area(pic, x_offset, y_offset, tile)
    local size = 196
    local start = {
        x = x_offset * (1024 - size - 112) / 2,
        y = y_offset * (1024 - size - 112) / 2,
    }
    poker_starts[#poker_starts+1] = start

    pic = b.picture(b.decompress(pic))
    pic = b.scale(pic, size/512)
    pic = b.change_tile(pic, true, tile or 'nuclear-ground')
    pic = b.translate(pic, start.x, start.y)
    return pic
end

local poker = b.any {
    start_area(require('map_gen.data.presets.poker_club'), -1, -1, 'lab-white'),
    start_area(require('map_gen.data.presets.poker_heart'), 1, -1, 'red-refined-concrete'),
    start_area(require('map_gen.data.presets.poker_spade'), 1, 1, 'lab-white'),
    start_area(require('map_gen.data.presets.poker_diamond'), -1, 1, 'red-refined-concrete'),
}

local fox = PictureBuilder{
    pic = require 'map_gen.data.presets.fox',
    ores = require 'map_gen.maps.danger_ores.config.joker_starter_area',
    func_map = {
        [2] = 'coal',
        [3] = 'coal',
        [12] = 'copper-ore',
        [14] = 'uranium-ore',
        [20] = 'iron-ore',
        [21] = 'iron-ore',
        [22] = 'stone',
        [29] = 'copper-ore',
    },
    tile_map = {
        [2] = 'nuclear-ground',
        [3] = 'concrete',
        [12] = 'brown-refined-concrete',
        [14] = 'green-refined-concrete',
        [20] = 'lab-dark-1',
        [21] = 'lab-dark-2',
        [22] = 'lab-white',
        [29] = 'orange-refined-concrete',
    }
}

local chart_token = Token.register(function()
    local r = 15 * 32
    game.forces.player.chart(game.surfaces[1], {{x = -r, y = -r}, {x = r, y = r}})
end)

DOC.game.on_init = function()
    local surface = game.surfaces.nauvis
    for _, position in pairs(poker_starts) do
        surface.request_to_generate_chunks(position, 1)
    end
    surface.force_generate_chunk_requests()

    Task.set_timeout(3, chart_token)
end

DOC.map_config.spawn_builder = function()
    return b.any{ water, poker, fox }
end

---@param player LuaPlayer
---@param position MapPosition
local function teleport_safe(player, position)
    local character = player.character
    if not (character and character.valid) then
        return
    end

    local target = character.surface.find_non_colliding_position(character.type, position, 8, 0.02, false)
    if not target then
        -- try again with larger radius if a water body is in the way
        target = character.surface.find_non_colliding_position(character.type, position, 50, 0.02, false)
    end

    if not target then
        return
    end

    character.teleport(target)
end

--- Send players to a random spawn area, save the origin
Event.add(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    local position = poker_starts[random(#poker_starts)]
    spawn_locations[player.index] = position
    teleport_safe(player, position)

    player.print(ScenarioInfo.get_map_extra_info())
end)

--- Respawn player at their assigned starting areas
Event.add(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    teleport_safe(player, spawn_locations[player.index])
end)

return artifacts(Scenario.register(DOC))
