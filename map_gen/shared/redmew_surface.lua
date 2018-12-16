-- Creates a generic surface for all maps so that we can ignore all user input at time of world creation.
-- If you want to modify settings for a particular map, see 'Creating a new scenario' in the wiki for examples of how.
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'

local surface_name = 'redmew'

local Public = {}
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

-- These settings are default except:
-- cliffs disabled, enemy bases to high frequency and big size, and starting area to small
Public.map_gen_settings = {
    autoplace_controls = {
        ['coal'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['copper-ore'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['crude-oil'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['enemy-base'] = {
            frequency = 'high',
            richness = 'normal',
            size = 'high'
        },
        ['iron-ore'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['stone'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['uranium-ore'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['desert'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['dirt'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['grass'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['sand'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        },
        ['trees'] = {
            frequency = 'normal',
            richness = 'normal',
            size = 'normal'
        }
    },
    cliff_settings = {
        cliff_elevation_0 = 1024,
        cliff_elevation_interval = 10,
        name = 'cliff'
    },
    terrain_segmentation = 'normal', -- water frequency
    water = 'normal', -- water size
    starting_area = 'low',
    starting_points = {
        {
            x = 0,
            y = 0
        }
    },
    width = 2000000,
    height = 2000000,
    peaceful_mode = false,
    seed = nil
}

-- default settings
Public.map_settings = {
    pollution = {
        enabled = true,
        diffusion_ratio = 0.02,
        min_to_diffuse = 15,
        ageing = 1,
        expected_max_per_chunk = 7000,
        min_to_show_per_chunk = 700,
        min_pollution_to_damage_trees = 3500,
        pollution_with_max_forest_damage = 10000,
        pollution_per_tree_damage = 2000,
        pollution_restored_per_tree_damage = 500,
        max_pollution_to_restore_trees = 1000
    },
    enemy_evolution = {
        enabled = true,
        time_factor = 0.000004,
        destroy_factor = 0.002,
        pollution_factor = 0.000015
    },
    enemy_expansion = {
        enabled = true,
        max_expansion_distance = 7,
        friendly_base_influence_radius = 2,
        enemy_building_influence_radius = 2,
        building_coefficient = 0.1,
        other_base_coefficient = 2.0,
        neighbouring_chunk_coefficient = 0.5,
        neighbouring_base_chunk_coefficient = 0.4,
        max_colliding_tiles_coefficient = 0.9,
        settler_group_min_size = 5,
        settler_group_max_size = 20,
        min_expansion_cooldown = 4 * 3600,
        max_expansion_cooldown = 60 * 3600
    },
    unit_group = {
        min_group_gathering_time = 3600,
        max_group_gathering_time = 10 * 3600,
        max_wait_time_for_late_members = 2 * 3600,
        max_group_radius = 30.0,
        min_group_radius = 5.0,
        max_member_speedup_when_behind = 1.4,
        max_member_slowdown_when_ahead = 0.6,
        max_group_slowdown_factor = 0.3,
        max_group_member_fallback_factor = 3,
        member_disown_distance = 10,
        tick_tolerance_when_member_arrives = 60,
        max_gathering_unit_groups = 30,
        max_unit_group_size = 200
    },
    steering = {
        default = {
            radius = 1.2,
            separation_force = 0.005,
            separation_factor = 1.2,
            force_unit_fuzzy_goto_behavior = false
        },
        moving = {
            radius = 3,
            separation_force = 0.01,
            separation_factor = 3,
            force_unit_fuzzy_goto_behavior = false
        }
    },
    path_finder = {
        fwd2bwd_ratio = 5,
        goal_pressure_ratio = 2,
        max_steps_worked_per_tick = 100,
        use_path_cache = true,
        short_cache_size = 5,
        long_cache_size = 25,
        short_cache_min_cacheable_distance = 10,
        short_cache_min_algo_steps_to_cache = 50,
        long_cache_min_cacheable_distance = 30,
        cache_max_connect_to_cache_steps_multiplier = 100,
        cache_accept_path_start_distance_ratio = 0.2,
        cache_accept_path_end_distance_ratio = 0.15,
        negative_cache_accept_path_start_distance_ratio = 0.3,
        negative_cache_accept_path_end_distance_ratio = 0.3,
        cache_path_start_distance_rating_multiplier = 10,
        cache_path_end_distance_rating_multiplier = 20,
        stale_enemy_with_same_destination_collision_penalty = 30,
        ignore_moving_enemy_collision_distance = 5,
        enemy_with_different_destination_collision_penalty = 30,
        general_entity_collision_penalty = 10,
        general_entity_subsequent_collision_penalty = 3,
        max_clients_to_accept_any_new_request = 10,
        max_clients_to_accept_short_new_request = 100,
        direct_distance_to_consider_short_request = 100,
        short_request_max_steps = 1000,
        short_request_ratio = 0.5,
        min_steps_to_check_path_find_termination = 2000,
        start_to_goal_cost_multiplier_to_terminate_path_find = 500.0
    },
    max_failed_behavior_count = 3
}

-- Default settings
Public.difficulty_settings = {
    recipe_difficulty = defines.difficulty_settings.recipe_difficulty.normal,
    technology_difficulty = defines.difficulty_settings.technology_difficulty.normal,
    technology_price_multiplier = 2
}

--- Returns the play surface that the map is created on
Public.get_surface = function()
    return game.surfaces[surface_name]
end

--- Creates a new surface with the name 'redmew'
local create_redmew_surface = function()
    local surface = game.create_surface(surface_name, Public.map_gen_settings)

    for k, v in pairs(Public.difficulty_settings) do
        game.difficulty_settings[k] = v
    end

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

    surface.request_to_generate_chunks({0,0}, 4)
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
    local surface =  game.surfaces[surface_name]
    local spawn_coords

    local pos = surface.find_non_colliding_position('player', {0,0}, 50, 1)
    if pos and not first_player_position_check_override[1] then
        player.teleport(pos, surface)
        spawn_coords = pos
    else
        -- if there's no position available within range or a map needs players at 0,0: create an island and place the player there
        surface.set_tiles({
            {name = 'lab-white', position = {-1, -1}},
            {name = 'lab-white', position = {-1, 0}},
            {name = 'lab-white', position = {0, -1}},
            {name = 'lab-white', position = {0, 0}},
        })
        player.teleport({0,0}, surface)
        spawn_coords = {0,0}
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
