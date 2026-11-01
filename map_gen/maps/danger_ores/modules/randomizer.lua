-- The Randomizer: every map is a new mix of an ore layout, the water and an overlay, picked by
-- the map seed. The same seed always picks the same mix, so the map comes back the same on every
-- load without saving the pick.
--
-- The pick can only be made once the map's surface exists, and the map is built from it on init
-- and on every load, so the map's config is replaced by one that reads like the preset's, except
-- for the settings the pick changes, which it looks up the first time one is read.
--
-- Turned on with DOC.randomizer.enabled (see configuration.lua).
local B = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Layouts = require 'map_gen.maps.danger_ores.modules.layouts'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
local citadel = require 'map_gen.maps.danger_ores.modules.citadel'
local fault_lines = require 'map_gen.maps.danger_ores.modules.fault_lines'

local Public = {}

Public.layouts = {
    require 'map_gen.maps.danger_ores.layouts.sectors',
    require 'map_gen.maps.danger_ores.layouts.split',
    require 'map_gen.maps.danger_ores.layouts.chessboard',
    require 'map_gen.maps.danger_ores.layouts.circles',
    require 'map_gen.maps.danger_ores.layouts.gradient',
    require 'map_gen.maps.danger_ores.layouts.honeycomb',
    require 'map_gen.maps.danger_ores.layouts.grid_factory',
    require 'map_gen.maps.danger_ores.layouts.spiral',
    require 'map_gen.maps.danger_ores.layouts.hub_spiral',
    require 'map_gen.maps.danger_ores.layouts.tetrominoes',
    require 'map_gen.maps.danger_ores.layouts.voronoi',
    require 'map_gen.maps.danger_ores.layouts.patches',
    require 'map_gen.maps.danger_ores.layouts.petals',
    require 'map_gen.maps.danger_ores.layouts.riches',
    require 'map_gen.maps.danger_ores.layouts.bloom'
}

Public.waters = {
    {name = 'Lakes', settings = {}},
    {name = 'Rivers', settings = {water = require 'map_gen.maps.danger_ores.modules.rivers'}},
    {name = 'Archipelago', settings = {water = require 'map_gen.maps.danger_ores.modules.archipelago'}}
}

-- laid over the finished map
Public.overlays = {
    {name = 'Open', settings = {}},
    {
        name = 'Citadel',
        settings = {
            post_map_func = function(map, config)
                return B.any {citadel(config), map}
            end
        }
    },
    {
        name = 'Fault Lines',
        settings = {
            post_map_func = function(map, config)
                return B.any {fault_lines(config), map}
            end
        }
    }
}

--- Every mix the seed picks from: {layout, water, overlay}.
Public.combinations = {}
for _, layout in pairs(Public.layouts) do
    for _, water in pairs(Public.waters) do
        for _, overlay in pairs(Public.overlays) do
            Public.combinations[#Public.combinations + 1] = {layout, water, overlay}
        end
    end
end

-- every key some recipe sets: reading one of these makes the pick
local rolled_keys = {}
for _, list in pairs({Public.layouts, Public.waters, Public.overlays}) do
    for _, recipe in pairs(list) do
        for key in pairs(recipe.settings) do
            rolled_keys[key] = true
        end
    end
end

--- The mix for `seed`: a few rounds of a Lehmer generator, which are exact in Lua's doubles and
-- send seeds next to each other to mixes far apart.
function Public.pick(seed)
    local h = seed % 2147483647
    for _ = 1, 3 do
        h = h * 48271 % 2147483647
    end
    return Public.combinations[h % #Public.combinations + 1]
end

--- The mix this map's seed picks.
function Public.rolled()
    local surface = RS.get_surface()
    if not surface then
        error('the Randomizer picks the map once its surface exists: read the map config on init or later', 2)
    end
    return Public.pick(surface.map_gen_settings.seed)
end

--- A map config that reads like `base`, except for the settings the mix from `get_mix()` changes.
-- Writing to it writes to `base`.
function Public.map_config(base, get_mix)
    local settings
    return setmetatable({}, {
        __index = function(_, key)
            if not rolled_keys[key] then
                return base[key]
            end
            if not settings then
                settings = {}
                for _, recipe in ipairs(get_mix()) do
                    for k, v in pairs(recipe.settings) do
                        settings[k] = v
                    end
                end
            end
            local value = settings[key]
            if value == nil then
                return base[key]
            elseif value == Layouts.NONE then
                return nil
            end
            return value
        end,
        __newindex = base
    })
end

--- The mix's names, as players see them: 'Voronoi, Rivers, Citadel'.
function Public.describe(mix)
    return table.concat({mix[1].name, mix[2].name, mix[3].name}, ', ')
end

--- @param danger_ores_config the DOC table, whose map_config is replaced
function Public.register(danger_ores_config)
    -- the preset's own config, which the mixes change
    Public.base_config = danger_ores_config.map_config
    danger_ores_config.map_config = Public.map_config(Public.base_config, Public.rolled)

    Event.on_init(function()
        local mix = Public.rolled()
        ScenarioInfo.set_map_name('Danger Ores - Randomizer: ' .. Public.describe(mix))
        ScenarioInfo.add_map_extra_info('  This map is ' .. Public.describe(mix) .. '.')
    end)
end

return Public
