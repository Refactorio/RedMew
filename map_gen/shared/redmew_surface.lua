--[[
    Creates a custom surface for all redmew maps so that we can ignore all user input at time of world creation.

    Allows map makers to define the map gen settings, map settings, and difficulty settings in as much or as little details as they want.
    The aim is to make this a very easy process for map makers, while eliminating the need for many of the existing builder functions.
    For example by preventing ores from spawning we no longer need to manually scan for and remove ores.

    So first, a few concepts: When you create a new map you're given many options. These options break into 3 categories which are not made explicitly
    clear in the game itself:
    map_gen_settings, map_settings, and difficulty_settings
    map_gen_settings: Only affect a given surface. These settings determine everything that surface is made of:
    ores, tiles, entities, boundaries, etc. It also contains a less obvious setting: peaceful_mode.
    map_settings: Are kind of a misnomer since they apply to the game at large. Contain settings for pollution, enemy_evolution, enemy_expansion,
    unit_group, steering, path_finder, and something called max_failed_behavior_count (shrug)
    lastly, difficulty_settings
    difficulty_settings: contains only recipe_difficulty, technology_difficulty (not used in vanilla), and technology_price_multiplier
    In the 16.51 version of factorio's Map Generator page then, difficulty_settings make up the "Recipes/Technology" section of the
    "Advanced settings" tab while map_settings make up the rest of that tab.
    map_gen_settings are detemined by everything in the remaining 3 tabs (Basic settings, Resource settings, Terrain settings)

    Unless fed arguments via the public functions, this module will simply clone nauvis, and respect all user settings.
    To pass settings to redmew_surface, there are two types of public commands: sets and adds.
    `Set` commands will use a copy of the default generation settings and apply map settings on top of that. All user settings for that
    category will be discarded.
    `Add` commands will take the user's settings and apply the map's settings on top (overwriting user settings)
    For both the set and add functions they take a list of tables.

    So for example to select a 4x tech cost while letting the user decide whether to use expensive recipes you would call:
    RS.add_difficulty_settings({difficulty_settings_presets.tech_x4})
    And to select a 4x tech cost while maintaining default settings for everything else you would call:
    RS.set_difficulty_settings({difficulty_settings_presets.tech_x4})

    It should be noted that tables earlier in the list will be overwritten by tables later in the list.
    So in the following example the resulting tech cost would be 4, not 3.

    RS.add_difficulty_settings({difficulty_settings_presets.tech_x3, difficulty_settings_presets.tech_x4})

    To create a map with no ores, no enemies, no pollution, no enemy evolution, 3x tech costs, but leaving everything else up to the user
    we would use the following:

    -- We require redmew_surface to access the public functions and assign the table Public to the RS variable to access them easily.
    local RS = require 'map_gen.shared.redmew_surface'
    -- We require the resources tables so that we don't have to write settings components by hand.
    -- In general, don't create a table custom for a map, instead just add it to the resource files and call that so that others can make use of it.
    local MGSP = require 'resources.map_gen_settings' -- map gen settings presets
    local DSP = require 'resources.difficulty_settings' -- difficulty settings presets
    local MSP = require 'resources.map_settings' -- map settings presets

    RS.add_map_gen_settings({MGSP.enemy_none, MGSP.ore_none, MGSP.oil_none})
    RS.add_difficulty_settings({DSP.tech_x3})
    RS.add_map_settings({MSP.enemy_evolution_off, MSP.pollution_off})
]]
-- Dependencies
require 'util'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Token = require 'utils.token'

local map_settings_presets = require 'resources.map_settings'
local difficulty_settings_presets = require 'resources.difficulty_settings'

-- Localized functions
local insert = table.insert
local merge = util.merge
local format = string.format

-- Local vars
local Public = {}

-- Constants
local surface_name = 'redmew'
local set_error_message = 'set_%s has already been called. You cannot set/add to settings that are already set.'

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
        if primitives['set_difficulty_settings'] then
            combined_difficulty_settings = merge({difficulty_settings_presets.default, combined_difficulty_settings})
        end
        for k, v in pairs(combined_difficulty_settings) do
            game.difficulty_settings[k] = v
        end
    end
end

--- Sets up the map settings
local function set_map_settings()
    -- map_settings_presets.default
    if global.config.redmew_surface.enabled and global.config.redmew_surface.map_settings then
        local combined_map_settings = merge(data.map_settings_components)

        if primitives['set_difficulty_settings'] then
            combined_map_settings = merge({map_settings_presets.default, combined_map_settings})
        end

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

--- Creates a new surface
local function create_redmew_surface()
    local surface

    if global.config.redmew_surface.enabled and global.config.redmew_surface.map_gen_settings then
        -- Add the user's map gen settings as the first entry in the table
        local combined_map_gen = {game.surfaces.nauvis.map_gen_settings}
        -- Take the map's settings and add them into the table
        for _, v in pairs(data.map_gen_settings_components) do
            insert(combined_map_gen, v)
        end

        surface = game.create_surface(surface_name, merge(combined_map_gen))
    else
        surface = game.create_surface(surface_name)
    end

    set_difficulty_settings()
    set_map_settings()

    surface.request_to_generate_chunks({0, 0}, 4)
    surface.force_generate_chunk_requests()
    game.forces.player.set_spawn_position({0, 0}, surface)
end

--- On player create, teleport the player to the redmew surface
--- When placed, locomotives will get a random color
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
    create_redmew_surface()
end

-- Public functions

--- Removes the player_created event.
function Public.remove_player_created_event()
    Event.remove_removable(defines.events.on_built_entity, player_created)
end

--- Sets components to the difficulty_settings_components table
-- Only one call to this may be made, it is an error to call this twice as it is intended to give unique control of settings.
-- @param components <table> list of difficulty settings components (usually from resources.difficulty_settings)
function Public.set_difficulty_settings(components)
    if primitives['set_difficulty_settings'] then
        error(format(set_error_message, 'difficulty_settings'))
    end
    combine_settings(components, data.difficulty_settings_components)
    primitives['set_difficulty_settings'] = true
end

--- Adds components to the difficulty_settings_components table
-- Only one call to this should be made, as later calls can overwrite earlier ones if the values overlap.
-- @param components <table> list of difficulty settings components (usually from resources.difficulty_settings)
function Public.add_difficulty_settings(components)
    if primitives['set_difficulty_settings'] then
        error(format(set_error_message, 'difficulty_settings'))
    end
    combine_settings(components, data.difficulty_settings_components)
end

--- Adds components to the map_gen_settings_components table
-- Only one call to this may be made, it is an error to call this twice as it is intended to give unique control of settings.
-- @param components <table> list of map gen components (usually from resources.map_gen_settings)
function Public.set_map_gen_settings(components)
    if primitives['set_map_gen_settings'] then
        error(format(set_error_message, 'map_gen_settings'))
    end
    combine_settings(components, data.map_gen_settings_components)
    primitives['set_map_gen_settings'] = true
end

--- Adds components to the map_gen_settings_components table
-- Only one call to this should be made, as later calls can overwrite earlier ones if the values overlap.
-- @param components <table> list of map gen components (usually from resources.map_gen_settings)
function Public.add_map_gen_settings(components)
    if primitives['set_map_gen_settings'] then
        error(format(set_error_message, 'map_gen_settings'))
    end
    combine_settings(components, data.map_gen_settings_components)
end

--- Adds components to the map_settings_components table
-- Only one call to this may be made, it is an error to call this twice as it is intended to give unique control of settings.
-- @param components <table> list of map setting components (usually from resources.map_settings)
function Public.set_map_settings(components)
    if primitives['set_map_settings'] then
        error(format(set_error_message, 'map_settings'))
    end
    combine_settings(components, data.map_settings_components)
    primitives['set_map_settings'] = true
end

--- Adds components to the map_settings_components table
-- Only one call to this should be made, as later calls can overwrite earlier ones if the values overlap.
-- @param components <table> list of map setting components (usually from resources.map_settings)
function Public.add_map_settings(components)
    if primitives['set_map_settings'] then
        error(format(set_error_message, 'map_settings'))
    end
    combine_settings(components, data.map_settings_components)
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
