return {
    -- the default table is included as a reference but also to give the option of overwriting all user settings
    default = {
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
    },
    -- no pollution
    pollution_off = {
        pollution = {
            enabled = false
        }
    },
    -- decreases the spread of pollution and increases the absorption per chunk of land
    pollution_decreased_per_chunk = {
        pollution = {
            diffusion_ratio = 0.01,
            min_to_diffuse = 30,
            ageing = 2
        }
    },
    -- tough to spread pollution, pollution rapidly decayse: for venus
    pollution_hard_to_spread = {
        enabled = true,
        diffusion_ratio = 0.01,
        min_to_diffuse = 200,
        ageing = 5
    },
    -- increases the ability of trees to suck up pollution
    pollution_decreased_per_tree = {
        pollution = {
            pollution_with_max_forest_damage = 20000,
            pollution_per_tree_damage = 4000,
            max_pollution_to_restore_trees = 2000
        }
    },
    -- no enemy evolution
    enemy_evolution_off = {
        enemy_evolution = {
            enabled = false
        }
    },
    -- evolution from all factors x2
    enemy_evolution_x2 = {
        enemy_evolution = {
            enabled = true,
            time_factor = 0.000008,
            destroy_factor = 0.004,
            pollution_factor = 0.000030
        }
    },
    -- 3x cost for pollution, all else 1x
    enemy_evolution_punishes_pollution = {
        enemy_evolution = {
            enabled = true,
            time_factor = 0.000004,
            destroy_factor = 0.002,
            pollution_factor = 0.000045
        }
    },
    -- 3x cost for destroying spawners, all else 1x
    enemy_evolution_punishes_destruction = {
        enemy_evolution = {
            enabled = true,
            time_factor = 0.000004,
            destroy_factor = 0.006,
            pollution_factor = 0.000015
        }
    },
    -- no enemy expansion
    enemy_expansion_off = {
        enemy_expansion = {
            enabled = false
        }
    },
    -- should increase the fequency with which enemies expand
    enemy_expansion_frequency_x4 = {
        enemy_expansion = {
            enabled = true,
            min_expansion_cooldown = 1 * 3600,
            max_expansion_cooldown = 15 * 3600
        }
    },
    -- biters will expand to more chunks and will be more densely packed
    enemy_expansion_aggressive = {
        enemy_expansion = {
            enabled = true,
            max_expansion_distance = 21,
            friendly_base_influence_radius = 1,
            enemy_building_influence_radius = 1,
            settler_group_min_size = 1,
            settler_group_max_size = 10
        }
    }
}
