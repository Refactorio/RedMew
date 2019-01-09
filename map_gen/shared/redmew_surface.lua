--[[
    Creates a custom surface for all redmew maps so that we can ignore all user input at time of world creation.

    Allows map makers to define the map gen settings, map settings, and difficulty settings in as much or as little details as they want.
    The aim is to make this a very easy process for map makers, while eliminating the need for some of the existing builder functions.
    For example by preventing ores from spawning we no longer need to manually scan for and remove ores.

    When you create a new map you're given many options. These options break into 3 categories which are not made explicitly
    clear in the game itself:
    map_gen_settings, map_settings, and difficulty_settings

    map_gen_settings: Only affect a given surface. These settings determine everything that surface is made of:
    ores, tiles, entities, boundaries, etc. It also contains a less obvious setting: peaceful_mode.

    map_settings: Are kind of a misnomer since they apply to the game at large. Contain settings for pollution, enemy_evolution, enemy_expansion,
    unit_group, steering, path_finder, and something called max_failed_behavior_count (shrug)
    lastly, difficulty_settings

    difficulty_settings: contains only recipe_difficulty, technology_difficulty (not used in vanilla), and technology_price_multiplier

    In the 16.51 version of factorio's Map Generator page difficulty_settings make up the "Recipes/Technology" section of the
    "Advanced settings" tab. map_settings make up the rest of that tab.
    map_gen_settings are detemined by everything in the remaining 3 tabs (Basic settings, Resource settings, Terrain settings)

    Unless fed arguments via the public functions, this module will simply clone nauvis, respecting all user settings.
    To pass settings to redmew_surface, each of the above-mentioned 3 settings components has a public function.
    set_map_gen_settings, set_map_settings, and set_difficulty_settings
    The functions all take a list of tables which contain settings. The tables then overwrite any existing user settings.
    Therefore, for any settings not explicitly set the user's settings persist.

    Tables of settings can be constructed manually or can be taken from the resource files by the same names (resources/map_gen_settings, etc.)

    Example: to select a 4x tech cost you would call:
    RS.set_difficulty_settings({difficulty_settings_presets.tech_x4})

    It should be noted that tables earlier in the list will be overwritten by tables later in the list.
    So in the following example the resulting tech cost would be 4, not 3.

    RS.set_difficulty_settings({difficulty_settings_presets.tech_x3, difficulty_settings_presets.tech_x4})

    To create a map with no ores, no enemies, no pollution, no enemy evolution, 3x tech costs, and sand set to high we would use the following:

    -- We require redmew_surface to access the public functions and assign the table Public to the RS variable to access them easily.
    local RS = require 'map_gen.shared.redmew_surface'
    -- We require the resources tables so that we don't have to write settings components by hand.
    local MGSP = require 'resources.map_gen_settings' -- map gen settings presets
    local DSP = require 'resources.difficulty_settings' -- difficulty settings presets
    local MSP = require 'resources.map_settings' -- map settings presets

    -- We create a custom table for the niche settings of wanting more sand
    local extra_sand = {
        autoplace_controls = {
            sand = {frequency = 'high', size = 'high'}
        }
    }

    RS.set_map_gen_settings({MGSP.enemy_none, MGSP.ore_none, MGSP.oil_none, extra_sand})
    RS.set_difficulty_settings({DSP.tech_x3})
    RS.set_map_settings({MSP.enemy_evolution_off, MSP.pollution_off})
]]
-- Dependencies
require 'util'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Token = require 'utils.token'

-- Localized functions
local insert = table.insert
local merge = util.merge
local format = string.format

-- Local vars
local Public = {}

-- Constants
local surface_name = 'redmew'
local set_error_message = 'set_%s has already been called. You cannot call set twice as earlier values may be overwritten.'

-- Global tokens
local data = {
    ['map_gen_settings_components'] = {},
    ['map_settings_components'] = {},
    ['difficulty_settings_components'] = {}
}

-- This just creates an empty primitives table, the definitions are to document what primitives might exist.
local primitives = {
    ['first_player_position_check_override'] = nil,
    ['set_difficulty_settings'] = nil,
    ['set_map_gen_settings'] = nil,
    ['set_map_settings'] = nil,
}

Global.register(
    {
        primitives = primitives,
        data = data
    },
    function(tbl)
        primitives = tbl.primitives
        data = tbl.data
    end
)

-- Local functions

--- Add the tables inside components into the given data_table
local function combine_settings(components, data_table)
    for _, v in pairs(components) do
        insert(data_table, v)
    end
end

--- Sets up the difficulty settings
local function set_difficulty_settings()
    if global.config.redmew_surface.enabled and global.config.redmew_surface.difficulty then
        local combined_difficulty_settings = merge(data.difficulty_settings_components)
        for k, v in pairs(combined_difficulty_settings) do
            game.difficulty_settings[k] = v
        end
    end
end

--- Sets up the map settings
local function set_map_settings()
    if global.config.redmew_surface.enabled and global.config.redmew_surface.map_settings then
        local combined_map_settings = merge(data.map_settings_components)

        -- Iterating through individual tables because game.map_settings is read-only
        if combined_map_settings.pollution then
            for k, v in pairs(combined_map_settings.pollution) do
                game.map_settings.pollution[k] = v
            end
        end
        if combined_map_settings.enemy_evolution then
            for k, v in pairs(combined_map_settings.enemy_evolution) do
                game.map_settings.enemy_evolution[k] = v
            end
        end
        if combined_map_settings.enemy_expansion then
            for k, v in pairs(combined_map_settings.enemy_expansion) do
                game.map_settings.enemy_expansion[k] = v
            end
        end
        if combined_map_settings.unit_group then
            for k, v in pairs(combined_map_settings.unit_group) do
                game.map_settings.unit_group[k] = v
            end
        end
        if combined_map_settings.steering then
            if combined_map_settings.steering.default then
                for k, v in pairs(combined_map_settings.steering.default) do
                    game.map_settings.steering.default[k] = v
                end
            end
            if combined_map_settings.steering.moving then
                for k, v in pairs(combined_map_settings.steering.moving) do
                    game.map_settings.steering.moving[k] = v
                end
            end
        end
        if combined_map_settings.path_finder then
            for k, v in pairs(combined_map_settings.path_finder) do
                game.map_settings.path_finder[k] = v
            end
        end
        if combined_map_settings.max_failed_behavior_count then
            game.map_settings.max_failed_behavior_count = combined_map_settings.max_failed_behavior_count
        end
    end
end

--- On player create, teleport the player to the redmew surface
local player_created =
    Token.register(
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        local surface = game.surfaces[surface_name]

        local pos = surface.find_non_colliding_position('player', {0, 0}, 50, 1)
        if pos and not primitives['first_player_position_check_override'] then
            player.teleport(pos, surface)
        else
            -- if there's no position available within range or a map needs players at 0,0: create an island and place the player there
            surface.set_tiles(
                {
                    {name = 'lab-white', position = {-1, -1}},
                    {name = 'lab-white', position = {-1, 0}},
                    {name = 'lab-white', position = {0, -1}},
                    {name = 'lab-white', position = {0, 0}}
                }
            )
            player.teleport({0, 0}, surface)
            primitives['first_player_position_check_override'] = nil
        end
        Public.remove_player_created_event()
    end
)

local function init()
    if global.config.redmew_surface.enabled and global.config.redmew_surface.map_gen_settings then
        Public.create_redmew_surface()
    else
        surface_name = 'nauvis'
    end
end

-- Public functions

--- Creates a new surface with the settings provided by the map file and the player.
function Public.create_redmew_surface()
    local surface

    -- Add the user's map gen settings as the first entry in the table
    local combined_map_gen = {game.surfaces.nauvis.map_gen_settings}
    -- Take the map's settings and add them into the table
    for _, v in pairs(data.map_gen_settings_components) do
        insert(combined_map_gen, v)
    end

    surface = game.create_surface(surface_name, merge(combined_map_gen))
    set_difficulty_settings()
    set_map_settings()

    surface.request_to_generate_chunks({0, 0}, 4)
    surface.force_generate_chunk_requests()
    game.forces.player.set_spawn_position({0, 0}, surface)
end

--- Removes the player_created event.
function Public.remove_player_created_event()
    Event.remove_removable(defines.events.on_player_created, player_created)
end

--- Sets components to the difficulty_settings_components table
-- It is an error to call this twice as later calls will overwrite earlier ones if values overlap.
-- @param components <table> list of difficulty settings components (usually from resources.difficulty_settings)
function Public.set_difficulty_settings(components)
    if primitives['set_difficulty_settings'] then
        error(format(set_error_message, 'difficulty_settings'))
    end
    combine_settings(components, data.difficulty_settings_components)
    primitives['set_difficulty_settings'] = true
end

--- Adds components to the map_gen_settings_components table
-- It is an error to call this twice as later calls will overwrite earlier ones if values overlap.
-- @param components <table> list of map gen components (usually from resources.map_gen_settings)
function Public.set_map_gen_settings(components)
    if primitives['set_map_gen_settings'] then
        error(format(set_error_message, 'map_gen_settings'))
    end
    combine_settings(components, data.map_gen_settings_components)
    primitives['set_map_gen_settings'] = true
end

--- Adds components to the map_settings_components table
-- It is an error to call this twice as later calls will overwrite earlier ones if values overlap.
-- @param components <table> list of map setting components (usually from resources.map_settings)
function Public.set_map_settings(components)
    if primitives['set_map_settings'] then
        error(format(set_error_message, 'map_settings'))
    end
    combine_settings(components, data.map_settings_components)
    primitives['set_map_settings'] = true
end

--- Returns the LuaSurface that the map is created on
function Public.get_surface()
    return game.surfaces[surface_name]
end

--- Returns the string name of the surface that the map is created on
function Public.get_surface_name()
    return surface_name
end

--- Allows maps to set first_player_position_check_override
-- This is a hack for diggy and forces the first created player to be teleported to {0, 0} and skip the collision check.
function Public.set_first_player_position_check_override(bool)
    primitives['first_player_position_check_override'] = bool
end

Event.on_init(init)

Event.add_removable(defines.events.on_player_created, player_created)

return Public
