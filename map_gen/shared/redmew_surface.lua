-- Creates a generic surface for all maps so that we can ignore all user input at time of world creation.
-- If you want to modify settings for a particular map, see 'Creating a new scenario' in the wiki for examples of how.
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local map_gen_settings_presets = require 'resources.map_gen_settings'
local map_settings_presets = require 'resources.map_settings'
local difficulty_settings_presets = require 'resources.difficulty_settings'

local Public = {}
Public.surface_name = 'redmew'
Public.first_player_position_check_override = false
local first_player_position_check_override = {Public.first_player_position_check_override}

Global.register(
    {
        first_player_position_check_override = first_player_position_check_override,
    },
    function(tbl)
        first_player_position_check_override = tbl.first_player_position_check_override
    end
)

Public.map_gen_settings = map_gen_settings_presets.redmew_default
Public.map_settings = map_settings_presets.default
Public.difficulty_settings = difficulty_settings_presets.default

--- Returns the play surface that the map is created on
Public.get_surface = function()
    return game.surfaces[Public.surface_name]
end

--- Creates a new surface with the name 'redmew'
local create_redmew_surface = function()
    local surface

    if global.config.redmew_surface.map_gen_settings then
        surface = game.create_surface(Public.surface_name, Public.map_gen_settings)
    else
        surface = game.create_surface(Public.surface_name)
    end

    if global.config.redmew_surface.difficulty then
        for k, v in pairs(Public.difficulty_settings) do
            game.difficulty_settings[k] = v
        end
    end

    if global.config.redmew_surface.map_settings then
        for k, v in pairs(Public.map_settings.pollution) do
            game.map_settings.pollution[k] = v
        end
        for k, v in pairs(Public.map_settings.enemy_evolution) do
            game.map_settings.enemy_evolution[k] = v
        end
        for k, v in pairs(Public.map_settings.enemy_expansion) do
            game.map_settings.enemy_expansion[k] = v
        end
        for k, v in pairs(Public.map_settings.unit_group) do
            game.map_settings.unit_group[k] = v
        end
        for k, v in pairs(Public.map_settings.steering.default) do
            game.map_settings.steering.default[k] = v
        end
        for k, v in pairs(Public.map_settings.steering.moving) do
            game.map_settings.steering.moving[k] = v
        end
        for k, v in pairs(Public.map_settings.path_finder) do
            game.map_settings.path_finder[k] = v
        end
        game.map_settings.max_failed_behavior_count = Public.map_settings.max_failed_behavior_count
    end

    surface.request_to_generate_chunks({0, 0}, 4)
    surface.force_generate_chunk_requests()
end

--- Sets a ghost_time_to_live as a quality of life feature: now ghosts
-- are created on death of entities before robot research
-- @param force_name string with name of force
-- @param time number of ticks for ghosts to live
Public.set_ghost_ttl = function(force_name, time)
    force_name = force_name or 'player'
    time = time or (30 * 60 * 60)
    game.forces[force_name].ghost_time_to_live = time
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    local surface = game.surfaces[Public.surface_name]
    local spawn_coords

    local pos = surface.find_non_colliding_position('player', {0, 0}, 50, 1)
    if pos and not first_player_position_check_override[1] then
        player.teleport(pos, surface)
        spawn_coords = pos
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
        spawn_coords = {0, 0}
        first_player_position_check_override[1] = false
    end
    game.forces.player.set_spawn_position(spawn_coords, surface)
end

local function init()
    create_redmew_surface()
    Public.set_ghost_ttl()
end

Event.on_init(init)
Event.add(defines.events.on_player_created, player_created)

return Public
