--[[
    This is a RedMew-customized version of Nexala's luacheckrc and differs in
    the following ways:
    - RedMew adds its own globals. See: globals, or search for "RedMew-specific globals"
    - Removes entries for certain LuaBootstrap (aka script) functions as they should
    be used through the event module
]]

-------------------------------------------------------------------------------
--[LICENSE]--
-------------------------------------------------------------------------------
-- .luacheckrc
-- This file is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this file, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.
--
-- In jurisdictions that recognize copyright laws, the author or authors
-- of this file dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.
--
-- THE FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
--
-- For more information, please refer to <http://unlicense.org/>
-- ]]

-- Current Factorio Version 2.1.9, luacheck version 1.1.1

-------------------------------------------------------------------------------
--[Set Defaults]--
-------------------------------------------------------------------------------
local LINE_LENGTH = false -- It is 2017 limits on length are a waste
local IGNORE = {'21./%w+_$', '21./^_%w+$', '213/[ijk]', '213/index', '213/key', '58[1-2]'}
local NOT_GLOBALS = {'coroutine', 'io', 'socket', 'dofile', 'loadfile'} -- These globals are not available to the factorio API

local STD_CONTROL = 'lua52c+factorio+factorio_control+stdlib+factorio_defines'
local STD_DATA = 'lua52c+factorio+factorio_data+stdlib+stdlib_data+factorio_defines'

-- In a perfect world these would be STD_DATA and STD_CONTROL (mostly)
local STD_BASE_DATA = 'lua52c+factorio+factorio_data+factorio_defines+factorio_base_data'
local STD_BASE_CONTROL = 'lua52c+factorio+factorio_control+factorio_defines+factorio_base_control'

-------------------------------------------------------------------------------
--[Assume Factorio Control stage as default]--
-------------------------------------------------------------------------------
std = STD_CONTROL
globals = {'print', '_DEBUG', '_CHEATS', '_DUMP_ENV', 'ServerCommands', 'Debug', '_LIFECYCLE', '_STAGE', '_NO_CUTSCENE'} -- RedMew-specific globals
max_line_length = LINE_LENGTH

not_globals = NOT_GLOBALS
ignore = IGNORE
quiet = 1 -- pass -q option
max_cyclomatic_complexity = 75
codes = true

--List of files and directories to exclude
exclude_files = {
    --Ignore special folders
    '**/.*/*', --Ignore if path starts with .
    '**/stdlib/vendor/',
    '**/*WIP/',

    --Ignore development mods
    '**/combat-tester/',
    '**/test-maker/',
    '**/trailer/',

    --Ignore map luas
    '**/map_gen/data/presets/',
}

-------------------------------------------------------------------------------
--[Mod Prototypes]--
-------------------------------------------------------------------------------
--Set default prototype files
files['**/data.lua'].std = STD_DATA
files['**/data-updates.lua'].std = STD_DATA
files['**/data-final-fixes.lua'].std = STD_DATA
files['**/settings.lua'].std = STD_DATA
files['**/settings-updates.lua'].std = STD_DATA
files['**/settings-final-fixes.lua'].std = STD_DATA
files['**/prototypes/'].std = STD_DATA
files['**/settings/'].std = STD_DATA

-------------------------------------------------------------------------------
--[Base]--
-------------------------------------------------------------------------------
--Find and replace ignores *.cfg, migrations, *.txt, control.lua, *.json, trailer, scenarios, campaigns, *.glsl

local base_scenarios = {
    std = STD_BASE_CONTROL .. '+factorio_base_scenarios+factorio_base_story',
    --ignore = {'212/event', '111', '112', '113', '211', '212', '213', '311', '411', '412', '421', '422', '423', '431', '432', '512'}
    ignore = {'...'}
}
files['**/base/scenarios/'] = base_scenarios
files['**/base/tutorials/'] = base_scenarios
files['**/base/campaigns/'] = base_scenarios
files['**/wip-scenario/'] = base_scenarios

files['**/base/migrations/'] = {std = STD_BASE_CONTROL}

files['**/core/lualib/'] = {std = STD_BASE_CONTROL}
files['**/core/lualib/util.lua'] = {globals = {'util', 'table'}, ignore = {'432/object'}}
files['**/core/lualib/silo-script.lua'] = {globals = {'silo_script'}, ignore = {'4../player'}}
files['**/core/lualib/production-score.lua'] = {globals = {'production_score', 'get_price_recursive'}, ignore = {'4../player'}}
files['**/core/lualib/story*'] = {std = '+factorio_base_story', ignore = {'42./k', '42./filter'}}
files['**/core/lualib/mod-gui.lua'] = {globals = {'mod_gui'}}
files['**/core/lualib/camera.lua'] = {globals = {'camera'}}
files['**/core/lualib/builder.lua'] = {globals = {'Builder', 'builder', 'action', 'down', 'right'}}

files['**/core/lualib/bonus-gui-ordering/'] = {std = STD_BASE_DATA}
files['**/core/lualib/dataloader.lua'] = {globals = {'data'}}
files['**/core/lualib/circuit-connector-*'] = {std = STD_BASE_DATA..'+factorio_circuit_connector_generated'}
files['**/core/lualib/bonus-gui-ordering.lua'] = {globals = {'bonus_gui_ordering'}}

files['**/base/prototypes/'] = {std = STD_BASE_DATA}
files['**/core/prototypes/'] = {std = STD_BASE_DATA}
files['**/core/prototypes/noise-programs.lua'] = {ignore = {'212/x', '212/y', '212/tile', '212/map'}}

--(( stdlib ))--
local stdlib_control = {
    std = 'lua52c+factorio+factorio_control+stdlib+factorio_defines',
    max_line_length = LINE_LENGTH
}

local stdlib_data = {
    std = 'lua52c+factorio+factorio_data+stdlib+factorio_defines',
    max_line_length = LINE_LENGTH
}

-- Assume control stage for stdlib
files['**/stdlib/'] = stdlib_control

-- Assume generic content for stdlib utils
files['**/stdlib/utils/**'].std = 'lua52c+stdlib'

-- STDLIB data files
files['**/stdlib/data/'] = stdlib_data

-- STDLIB Busted Spec
files['**/spec/**'] = {
    globals = {'serpent', 'log', 'SLOG', 'RESET'},
    std = 'lua52c+busted+factorio_defines+factorio_control+stdlib'
} --))

--(( Factorio ))--
stds.factorio = {
    --Set the read only variables
    read_globals = {
        -- @log@: Gives writing access to Factorio's logger instance.
        "log",
        -- @serpent@: Lua serializer and pretty printer. (https://github.com/pkulchenko/serpent)
        "serpent",
        -- @table_size@: Returns the number of elements inside an LUA table
        "table_size",
        util = {
            fields = {
                "by_pixel", "distance", "findfirstentity", "positiontostr", "formattime", "moveposition", "oppositedirection",
                "ismoduleavailable", "multiplystripes", "format_number", "increment", "color", "conditional_return",
                "add_shift", "merge", "premul_color", "encode", "decode", "insert_safe", "list_to_map",
                table = {
                    fields = {
                        "compare", "deepcopy", "shallow_copy"
                    },
                },
            },
        },
        table = {
            fields = {
                "compare", "deepcopy", "shallow_copy"
            },
        },
    },
}

stds.factorio_control = {
    read_globals = {

        -- @commands@:
        commands = {
            fields = {
                "commands", "game_commands", "remove_command"
            },
            other_fields = false,
        },

        -- @settings@:
        settings = {
            fields = {
                "get_player_settings",
                startup = {read_only = false, other_fields = true},
                global = {read_only = false, other_fields = true},
                player_default = {read_only = false, other_fields = true},
            },
        },

        -- @script@: Provides an interface for registering event handlers.
        -- (http://lua-api.factorio.com/latest/LuaBootstrap.html)
        script = {
            fields = {
                'active_mods',
                'feature_flags',
                'get_event_handler',
                'get_event_id',
                'get_event_order',
                'level',
                'mod_name',
                'new_notification_queue',
                'on_configuration_changed',
                'raise_biter_base_built',
                'raise_console_chat',
                'raise_event',
                'raise_market_item_purchased',
                'raise_player_crafted_item',
                'raise_player_fast_transferred',
                'raise_script_built',
                'raise_script_destroy',
                'raise_script_revive',
                'raise_script_set_tiles',
                'raise_script_teleported',
                'register_metatable',
                'register_on_object_destroyed',
            },
            other_fields = false,
        },

        -- @remote@: Allows inter-mod communication by providing a repository of interfaces that is shared by all mods.
        -- (http://lua-api.factorio.com/latest/LuaRemote.html)
        remote = {
            fields = {
                interfaces = {read_only = false, other_fields = true},
                "add_interface", "remove_interface", "call"
            },
            read_only = true,
            other_fields = false,
        },

        rcon = {
            fields = {'print'}
        },

        rendering = {
            other_fields = false,
            read_only = true,
            fields = {
                'draw_line',
                'draw_text',
                'draw_circle',
                'draw_rectangle',
                'draw_arc',
                'draw_polygon',
                'draw_sprite',
                'draw_animation',
                'draw_light',
                'destroy',
                'is_font_valid',
                'is_valid',
                'get_all_ids',
                'clear',
                'get_type',
                'get_surface',
                'get_time_to_live',
                'set_time_to_live',
                'get_forces',
                'set_forces',
                'get_players',
                'set_players',
                'get_visible',
                'set_visible',
                'get_draw_on_ground',
                'set_draw_on_ground',
                'get_only_in_alt_mode',
                'set_only_in_alt_mode',
                'get_color',
                'set_color',
                'get_width',
                'set_width',
                'get_from',
                'set_from',
                'get_to',
                'set_to',
                'get_gap_amount',
                'set_gap_amount',
                'get_gap_length',
                'set_gap_length',
                'get_target',
                'set_target',
                'get_orientation',
                'set_orientation',
                'get_scale',
                'set_scale',
                'get_text',
                'set_text',
                'get_font',
                'set_font',
                'get_alignment',
                'set_alignment',
                'get_scale_with_zoom',
                'set_scale_with_zoom',
                'get_filled',
                'set_filled',
                'get_radius',
                'set_radius',
                'get_left_top',
                'set_left_top',
                'get_right_bottom',
                'set_right_bottom',
                'get_max_radius',
                'set_max_radius',
                'get_min_radius',
                'set_min_radius',
                'get_start_angle',
                'set_start_angle',
                'get_angle',
                'set_angle',
                'get_vertices',
                'set_vertices',
                'get_sprite',
                'set_sprite',
                'get_x_scale',
                'set_x_scale',
                'get_y_scale',
                'set_y_scale',
                'get_render_layer',
                'set_render_layer',
                'get_orientation_target',
                'set_orientation_target',
                'get_oriented_offset',
                'set_oriented_offset',
                'get_intensity',
                'set_intensity',
                'get_minimum_darkness',
                'set_minimum_darkness',
                'get_light_mode',
                'set_light_mode'
            }
        },

        helpers = {
            other_fields = false,
            read_only = true,
            fields = {
                "check_prototype_translations",
                "compare_versions",
                "create_profiler",
                "decode_string",
                "direction_to_string",
                "encode_string",
                "evaluate_expression",
                "game_version",
                "is_valid_ambient_sound",
                "is_valid_animation_path",
                "is_valid_sound_path",
                "is_valid_sprite_path",
                "json_to_table",
                "multilingual_to_lower",
                "parse_map_exchange_string",
                "recv_udp",
                "remove_path",
                "send_udp",
                "stage",
                "table_to_json",
                "write_file",
            }
        },

        -- @game@: Main object through which most of the API is accessed.
        -- It is, however, not available inside handlers registered with @script.on_load@.
        -- (http://lua-api.factorio.com/latest/LuaGameScript.html)
        game ={
            other_fields = false,
            read_only = false,
            fields = {
                "allow_debug_settings",
                "auto_save",
                "ban_player",
                "check_consistency",
                "create_force",
                "create_random_generator",
                "create_surface",
                "delete_blueprint_library",
                "delete_surface",
                "desync_players",
                "disable_replay",
                "disable_tips_and_tricks",
                "draw_resource_selection",
                "enable_tip_triggers_in_custom_scenarios",
                "force_crc",
                "get_entity_by_tag",
                "get_entity_by_unit_number",
                "get_filtered_entity_prototypes",
                "get_map_exchange_string",
                "get_player",
                "get_surface",
                "get_vehicles",
                "help",
                "is_demo",
                "is_multiplayer",
                "kick_player",
                "merge_forces",
                "mute_player",
                "planet",
                "planets",
                "play_music",
                "play_sound",
                "print_stack_size",
                "print",
                "purge_player",
                "regenerate_entity",
                "reload_mods",
                "reload_script",
                "remove_offline_players",
                "reset_game_state",
                "reset_time_played",
                "save_atlas",
                "server_save",
                "set_game_state",
                "set_lose_ending_info",
                "set_win_ending_info",
                "show_message_dialog",
                "take_screenshot",
                "take_technology_screenshot",
                "technology_notifications_enabled",
                "train_manager",
                "unban_player",
                "unmute_player",
                
                backer_names = {read_only = true, other_fields = true},
                blueprints = {read_only = true, other_fields = true},
                connected_players = {read_only = true, other_fields = true},
                default_map_gen_settings = {read_only = true, other_fields = true},
                difficulty = {read_only = true, other_fields = true},
                difficulty_settings = {read_only = true, other_fields = true},
                enemy_has_vision_on_land_mines = {read_only = false, other_fields = false},
                finished = {read_only = true, other_fields = true},
                finished_but_continuing = {read_only = true, other_fields = false},
                forces = {read_only = true, other_fields = true},
                map_settings = {read_only = true, other_fields = true},
                permissions = {read_only = true, other_fields = true},
                player = {read_only = true, other_fields = true},
                players = {read_only = true, other_fields = true},
                speed = {read_only = false, other_fields = false},
                styles = {read_only = true, other_fields = true},
                surfaces = {read_only = true, other_fields = true},
                tick = {read_only = true, other_fields = true},
                tick_paused = {read_only = false, other_fields = false},
                ticks_played = {read_only = true, other_fields = true},
                ticks_to_run = {read_only = false, other_fields = false},
            },
        },

        prototypes = {
            other_fields = false,
            read_only = true,
            fields = {
                "get_achievement_filtered",
                "get_decorative_filtered",
                "get_entity_filtered",
                "get_equipment_filtered",
                "get_fluid_filtered",
                "get_history",
                "get_item_filtered",
                "get_mod_setting_filtered",
                "get_recipe_filtered",
                "get_technology_filtered",
                "get_tile_filtered",
                achievement = {read_only = true, other_fields = true},
                active_trigger = {read_only = true, other_fields = true},
                airborne_pollutant = {read_only = true, other_fields = true},
                ammo_category = {read_only = true, other_fields = true},
                asteroid_chunk = {read_only = true, other_fields = true},
                autoplace_control = {read_only = true, other_fields = true},
                burner_usage = {read_only = true, other_fields = true},
                collision_layer = {read_only = true, other_fields = true},
                custom_event = {read_only = true, other_fields = true},
                custom_input = {read_only = true, other_fields = true},
                damage = {read_only = true, other_fields = true},
                decorative = {read_only = true, other_fields = true},
                entity = {read_only = true, other_fields = true},
                equipment = {read_only = true, other_fields = true},
                equipment_category = {read_only = true, other_fields = true},
                equipment_grid = {read_only = true, other_fields = true},
                fluid = {read_only = true, other_fields = true},
                font = {read_only = true, other_fields = true},
                fuel_category = {read_only = true, other_fields = true},
                item = {read_only = true, other_fields = true},
                item_group = {read_only = true, other_fields = true},
                item_subgroup = {read_only = true, other_fields = true},
                map_gen_preset = {read_only = true, other_fields = true},
                mod_setting = {read_only = true, other_fields = true},
                module_category = {read_only = true, other_fields = true},
                named_noise_expression = {read_only = true, other_fields = true},
                named_noise_function = {read_only = true, other_fields = true},
                particle = {read_only = true, other_fields = true},
                procession = {read_only = true, other_fields = true},
                procession_layer_inheritance_group = {read_only = true, other_fields = true},
                quality = {read_only = true, other_fields = true},
                recipe_category = {read_only = true, other_fields = true},
                resource_category = {read_only = true, other_fields = true},
                shortcut = {read_only = true, other_fields = true},
                space_connection = {read_only = true, other_fields = true},	
                space_location = {read_only = true, other_fields = true},
                style = {read_only = true, other_fields = true},
                surface = {read_only = true, other_fields = true},
                surface_property = {read_only = true, other_fields = true},	
                technology = {read_only = true, other_fields = true},
                tile = {read_only = true, other_fields = true},
                trivial_smoke = {read_only = true, other_fields = true},
                utility_constants = {read_only = true, other_fields = true},
                virtual_signal = {read_only = true, other_fields = true},
                "max_beacon_supply_area_distance",
                "max_electric_pole_connection_distance",
                "max_electric_pole_supply_area_distance",
                "max_force_distraction_chunk_distance",
                "max_force_distraction_distance",
                "max_gate_activation_distance",
                "max_inserter_reach_distance",
                "max_pipe_to_ground_distance",
                "max_underground_belt_distance",
            }
        },
    },

    globals = {
        -- @global@: The global dictionary, useful for storing data persistent across a save-load cycle.
        -- Writing access is given to the mod-id field (for mod-wise saved data).
        -- (http://lua-api.factorio.com/latest/Global.html)
        "storage",

        -- @MOD@: Keep it organized, use this variable for anything that "NEEDS" to be global for some reason.
        "MOD"
    },
}

stds.factorio_data = {

    read_globals = {
        data = {
            fields = {
                raw = {
                    other_fields = true,
                    read_only = false
                },
                "extend", "is_demo"
            },
        },

        settings = {
            fields = {
                "startup", "global", "player",
            },
        },

        --Popular mods
        angelsmods = {
            other_fields = true
        },

        bobmods = {
            other_fields = true
        },

        mods = {
            other_fields = true
        }
    }
} --))

--(( Factorio Globals are bad mkay ))--
stds.factorio_base_control = {
    read_globals = {"silo_script", "mod_gui", "camera"}
}

stds.factorio_base_scenarios = {
    globals = {
        "check_automate_science_packs_advice", "check_research_hints", "check_supplies", "manage_attacks", "all_dead",
        "on_win", "difficulty_number", "init_attack_data", "handle_attacks", "count_items_in_container", "progress", "scanned",
        "check_light", "check_machine_gun", "level", "story_table",

        "tightspot_prices", "tightspot_make_offer", "tightspot_init", "tightspot_get_required_balance",
        "tightspot_init_level", "tightspot_init_spending_frame", "tightspot_init_progress_frame", "tightspot_update_progress", "tightspot_update_spending",
        "tightspot_get_missing_to_win", "tightspot_sell_back", "tightspot_start_level", "tightspot_show_level_description", "tightspot_update_speed_label",
        "map_ignore", "tightspot_check_level", "land_price",

        "transport_belt_madness_init", "transport_belt_madness_init_level", "transport_belt_madness_create_chests", "transport_belt_madness_fill_chests",
        "transport_belt_madness_start_level", "map_ignore", "map_clear", "map_load", "map_save", "transport_belt_madness_show_level_description",
        "transport_belt_madness_check_level", "transport_belt_madness_next_level", "transport_belt_madness_clear_level", "transport_belt_madness_contains_next_level",

        "restricted", "check_built_items", "result", "disable_combat_technologies", "apply_character_modifiers", "apply_combat_modifiers", "apply_balance",
        "load_config", "starting_area_constant", "create_next_surface", "end_round", "prepare_next_round", "silo_died","choose_joining_gui",
        "destroy_joining_guis", "create_random_join_gui", "create_auto_assign_gui", "create_pick_join_gui", "create_config_gui", "make_config_table", "default",
        "make_team_gui", "make_team_gui_config", "add_team_button_press", "trash_team_button_press", "remove_team_from_team_table", "add_team_to_team_table",
        "set_teams_from_gui", "on_team_button_press", "make_color_dropdown", "create_balance_option", "create_disable_frame", "disable_frame", "parse_disabled_items",
        "set_balance_settings", "config_confirm", "parse_config_from_gui", "get_color", "roll_starting_area", "delete_roll_surfaces", "auto_assign",
        "destroy_config_for_all", "prepare_map", "set_evolution_factor", "update_players_on_team_count", "random_join", "init_player_gui",
        "destroy_player_gui", "objective_button_press", "admin_button_press", "admin_frame_button_press", "diplomacy_button_press", "update_diplomacy_frame",
        "diplomacy_frame_button_press", "team_changed_diplomacy", "diplomacy_check_press", "get_stance", "give_inventory", "setup_teams", "disable_items_for_all",
        "set_random_team", "set_diplomacy", "create_spawn_positions", "set_spawn_position", "set_team_together_spawns", "chart_starting_area_for_force_spawns",
        "check_starting_area_chunks_are_generated", "check_player_color", "check_round_start", "clear_starting_area_enemies", "check_no_rush_end", "check_no_rush_players",
        "finish_setup", "chart_area_for_force", "setup_start_area_copy", "update_copy_progress", "update_progress_bar", "copy_paste_starting_area_tiles",
        "copy_paste_starting_area_entities", "create_silo_for_force", "setup_research", "on_chunk_generated", "get_distance_to_nearest_spawn",
        "create_wall_for_force", "fpn", "give_items", "create_item_frame", "create_technologies_frame", "create_cheat_frame", "create_day_frame",
        "time_modifier", "points_per_second_start", "points_per_second_level_subtract", "levels", "update_info", "get_time_left", "update_time_left",
        "on_joined", "make_frame", "update_frame", "update_table", "calculate_task_item_multiplayer", "setup_config", "select_from_probability_table",
        "select_inventory", "select_equipment", "select_challange_type", "save_round_statistics", "start_challenge", "create_teams", "set_areas",
        "decide_player_team", "set_teams", "refresh_leaderboard", "set_player", "generate_technology_list", "generate_research_task","setup_unlocks",
        "check_technology_progress", "generate_production_task", "generate_shopping_list_task", "set_gui_flow_table", "create_visibility_button",
        "check_item_lists", "update_task_gui", "check_end_of_round", "end_round_gui_update", "try_to_check_victory", "update_gui", "check_start_round",
        "check_start_set_areas", "check_start_setting_entities", "check_set_areas", "check_clear_areas", "check_chests", "check_chests_shopping_list",
        "check_chests_production", "check_input_chests", "fill_input_chests", "check_victory", "shopping_task_finished", "calculate_force_points",
        "update_research_task_table", "update_production_task_table", "update_shopping_list_task_table", "create_joined_game_gui", "pre_ending_round",
        "player_ending_prompt", "update_end_timer", "update_begin_timer", "team_finished", "save_points_list", "give_force_players_points",
        "update_winners_list", "set_spectator", "set_character", "give_starting_inventory", "give_equipment", "shuffle_table", "format_time",
        "spairs", "fill_leaderboard", "create_grid", "simple_entities", "save_map_data", "clear_map", "create_tiles", "recreate_entities",
        "map_sets", "give_points", "init_forces", "init_globals", "init_unit_settings", "check_next_wave", "next_wave", "calculate_wave_power",
        "wave_end", "make_next_spawn_tick", "check_spawn_units", "get_wave_units", "spawn_units", "randomize_ore", "set_command", "command_straglers",
        "unit_config", "make_next_wave_tick", "time_to_next_wave", "time_to_wave_end", "rocket_died", "unit_died", "get_bounty_price", "setup_waypoints",
        "insert_items", "give_starting_equipment", "give_spawn_equipment", "next_round_button_visible", "gui_init", "create_wave_frame", "create_money_frame",
        "create_upgrade_gui", "update_upgrade_listing", "upgrade_research", "get_upgrades", "get_money", "update_connected_players", "update_round_number",
        "set_research", "set_recipes", "check_deconstruction", "check_blueprint_placement", "loop_entities", "experiment_items",
        "setup", "story_gui_click", "clear_surface", "add_run_trains_button", "puzzle_condition", "basic_signals",
        "loop_trains", "Y_offset", "ghosts_1", "ghosts_2", "required_path", "through_wall_path", "count", "check_built_real_rail",
        "current_ghosts_count", "other", "rails", "set_rails", "straight_section", "late_entities", "entities", "stop",
        "get_spawn_coordinate",

        --tutorials
        "intermission", "create_entities_on_tick", "on_player_created", "required_count", "non_player_entities", "clear_rails",
        "chest", "damage", "furnace", "init_prototypes", "build_infi_table", "junk", "update_player_tags", "time_left", "team_production",
        "create_task_frame", "create_visibilty_buttons", "update_leaderboard", "in_in_area"
    }
}

stds.factorio_base_data = {
    globals = {
        --Style
        "make_cursor_box", "make_full_cursor_box",
        "default_container_padding", "default_orange_color", "default_light_orange_color", "warning_red_color",
        "achievement_green_color", "achievement_tan_color", "orangebuttongraphcialset", "bluebuttongraphcialset",
        "bonus_gui_ordering", "trivial_smoke", "technology_slot_base_width", "technology_slot_base_height", "default_frame_font_vertical_compensation",

        --Belts
        "transport_belt_connector_frame_sprites", "transport_belt_circuit_wire_connection_point", "transport_belt_circuit_wire_max_distance",
        "transport_belt_circuit_connector_sprites", "ending_patch_prototype", "basic_belt_horizontal", "basic_belt_vertical",
        "basic_belt_ending_top", "basic_belt_ending_bottom", "basic_belt_ending_side", "basic_belt_starting_top", "basic_belt_starting_bottom",
        "basic_belt_starting_side", "fast_belt_horizontal", "fast_belt_vertical", "fast_belt_ending_top", "fast_belt_ending_bottom",
        "fast_belt_ending_side", "fast_belt_starting_top", "fast_belt_starting_bottom", "fast_belt_starting_side", "express_belt_horizontal",
        "express_belt_vertical", "express_belt_ending_top", "express_belt_ending_bottom", "express_belt_ending_side", "express_belt_starting_top",
        "express_belt_starting_bottom", "express_belt_starting_side",

        --Circuit Connectors
        "circuit_connector_definitions", "default_circuit_wire_max_distance", "inserter_circuit_wire_max_distance",
        "universal_connector_template", "belt_connector_template", "belt_frame_connector_template", "inserter_connector_template",

        --Inserter Circuit Connectors
        "inserter_circuit_wire_max_distance", "inserter_default_stack_control_input_signal",

        --Sounds/beams
        "make_heavy_gunshot_sounds", "make_light_gunshot_sounds", "make_laser_sounds",

        --Gun/Laser
        "gun_turret_extension", "gun_turret_extension_shadow", "gun_turret_extension_mask", "gun_turret_attack",
        "laser_turret_extension", "laser_turret_extension_shadow", "laser_turret_extension_mask",

        --Pipes
        "pipecoverspictures", "pipepictures", "assembler2pipepictures", "assembler3pipepictures", "make_heat_pipe_pictures",

        --Combinators
        "generate_arithmetic_combinator", "generate_decider_combinator", "generate_constant_combinator",

        --Rail
        "destroyed_rail_pictures", "rail_pictures", "rail_pictures_internal", "standard_train_wheels", "drive_over_tie",
        "rolling_stock_back_light", "rolling_stock_stand_by_light",

        --Enemies
        "make_enemy_autoplace", "make_enemy_spawner_autoplace", "make_enemy_worm_autoplace",
        "make_spitter_attack_animation", "make_spitter_run_animation", "make_spitter_dying_animation",
        "make_spitter_attack_parameters", "make_spitter_roars", "make_spitter_dying_sounds",
        "make_spawner_idle_animation", "make_spawner_die_animation",
        "make_biter_run_animation", "make_biter_attack_animation", "make_biter_die_animation",
        "make_biter_roars", "make_biter_dying_sounds", "make_biter_calls",
        "make_worm_roars", "make_worm_dying_sounds", "make_worm_folded_animation", "make_worm_preparing_animation",
        "make_worm_prepared_animation", "make_worm_attack_animation", "make_worm_die_animation",

        --Other
        "tile_variations_template", "make_water_autoplace_settings",
        "make_unit_melee_ammo_type",  "make_trivial_smoke", "make_4way_animation_from_spritesheet", "flying_robot_sounds",
        "productivitymodulelimitation", "crash_trigger", "capsule_smoke", "make_beam", "playeranimations",
        "make_blood_tint", "make_shadow_tint",

        --tiles
        "water_transition_template", "make_water_transition_template", "water_autoplace_settings", "water_tile_type_names",
        "patch_for_inner_corner_of_transition_between_transition",
    }
}

stds.factorio_base_story = {
    globals = {
        "story_init_helpers", "story_update_table", "story_init", "story_update", "story_on_tick", "story_add_update",
        "story_remove_update", "story_jump_to", "story_elapsed", "story_elapsed_check", "story_show_message_dialog",
        "set_goal", "player_set_goal", "on_player_joined", "flash_goal", "set_info", "player_set_info", "export_entities",
        "list", "recreate_entities", "entity_to_connect", "limit_camera", "find_gui_recursive", "enable_entity_export",
        "add_button", "on_gui_click", "set_continue_button_style", "add_message_log", "story_add_message_log",
        "player_add_message_log", "message_log_frame", "message_log_scrollpane", "message_log_close_button",
        "message_log_table", "toggle_message_log_button", "toggle_objective_button", "message_log_init",
        "add_gui_recursive", "add_toggle_message_log_button", "add_toggle_objective_button", "mod_gui",
        "flash_message_log_button", "flash_message_log_on_tick", "story_gui_click", "story_points_by_name", "story_branches",
        "player", "surface", "deconstruct_on_tick", "recreate_entities_on_tick", "flying_congrats", "story_table"
    }
}

stds.factorio_circuit_connector_generated = {
    globals = {
        'default_circuit_wire_max_distance', 'circuit_connector_definitions', 'universal_connector_template',
        'belt_connector_template', 'belt_frame_connector_template', 'inserter_connector_template', 'inserter_connector_template',
        'inserter_circuit_wire_max_distance', 'inserter_default_stack_control_input_signal', 'transport_belt_connector_frame_sprites',
        'transport_belt_circuit_wire_max_distance',
    }
} --))

--(( STDLIB ))--
stds.stdlib = {
    read_globals = {
        table = {
            fields = {
                "map", "avg", "count_keys", "sum", "max", "remove", "insert", "invert", "first", "sort", "compare", "maxn", "any", "array_to_dictionary",
                "each", "flatten", "keys", "filter", "remove_keys", "flexcopy", "find", "fullcopy", "values", "pack", "deepcopy", "concat", "clear", "min",
                "is_empty", "merge", "size", "dictionary_merge", "unpack", "last"
            },
        },
        string = {
            fields = {
                "is_space", "is_empty", "match", "title", "upper", "gmatch", "trim", "split", "len", "ordinal_suffix", "dump", "shorten", "reverse",
                "ends_with", "byte", "starts_with", "join", "is_alpha", "lower", "is_upper", "is_digit", "is_alnum", "rjust", "center", "ljust", "format",
                "char", "is_lower", "contains", "gsub", "find", "rep", "sub"
            },
        },
        math = {
            fields = {
                "asin", "max", "modf", "midrange_mean", "pow", "ldexp", "maxuint16", "fmod", "round_to", "randomseed", "huge", "harmonic_mean", "tan",
                "maxint32", "quadratic_mean", "pi", "energetic_mean", "minint8", "frexp", "generalized_mean", "rad", "sin", "sinh", "min", "geometric_mean",
                "atan", "avg", "cosh", "maxint8", "arithmetic_mean", "exp", "sum", "round", "maxuint64", "minint64", "ceil", "maxint64", "atan2", "floor_to",
                "floor", "log", "maxint16", "minint16", "tanh", "acos", "deg", "cos", "log10", "maxuint8", "abs", "weighted_mean", "random", "maxuint32",
                "sqrt", "minint32"
            }
        },
    },
    globals = {
        "prequire", "rawtostring", "traceback", "inspect", "serpent", "inline_if", "install",
        "GAME", "AREA", "POSITION", "TILE", "SURFACE", "CHUNK", "COLOR", "ENTITY", "INVENTORY", "RESOURCE", "CONFIG", "LOGGER", "QUEUE",
        "EVENT", "GUI", "PLAYER", "FORCE", "log"
    }
}

stds.stdlib_control = {
}

stds.stdlib_data = {
    globals = {
        'DATA', 'RECIPE', 'ITEM', 'FLUID', 'ENTITY', 'TECHNOLOGY', 'CATEGORY'
    }
} --))

--(( FACTORIO DEFINES ))--
-- Every define in Factorio 2.1.24, from the runtime API (https://lua-api.factorio.com/latest/runtime-api.json)
stds.factorio_defines = {
    read_globals = {
        defines = {
            fields = {
                alert_type = {
                    fields = {
                        'collector_path_blocked',
                        'custom',
                        'entity_destroyed',
                        'entity_under_attack',
                        'expansion_base_built',
                        'fluid_mixing',
                        'no_material_for_construction',
                        'no_platform_storage',
                        'no_roboport_storage',
                        'no_storage',
                        'not_enough_construction_robots',
                        'not_enough_repair_packs',
                        'pipeline_overextended',
                        'platform_tile_building_blocked',
                        'train_no_path',
                        'train_out_of_fuel',
                        'turret_fire',
                        'turret_out_of_ammo',
                        'unclaimed_cargo'
                    }
                },
                behavior_result = {
                    fields = {
                        'deleted',
                        'fail',
                        'in_progress',
                        'success'
                    }
                },
                build_check_type = {
                    fields = {
                        'blueprint_ghost',
                        'ghost_revive',
                        'manual',
                        'manual_ghost',
                        'script',
                        'script_ghost'
                    }
                },
                build_mode = {
                    fields = {
                        'forced',
                        'normal',
                        'superforced'
                    }
                },
                cargo_destination = {
                    fields = {
                        'invalid',
                        'orbit',
                        'space_platform',
                        'station',
                        'surface'
                    }
                },
                chain_signal_state = {
                    fields = {
                        'all_open',
                        'none',
                        'none_open',
                        'partially_open'
                    }
                },
                chunk_generated_status = {
                    fields = {
                        'basic_tiles',
                        'corrected_tiles',
                        'custom_tiles',
                        'entities',
                        'nothing',
                        'tiles'
                    }
                },
                command = {
                    fields = {
                        'attack',
                        'attack_area',
                        'build_base',
                        'compound',
                        'flee',
                        'go_to_location',
                        'group',
                        'stop',
                        'wander'
                    }
                },
                compound_command = {
                    fields = {
                        'logical_and',
                        'logical_or',
                        'return_last'
                    }
                },
                constant = {
                    fields = {
                        'default_icon_size'
                    }
                },
                control_behavior = {
                    fields = {
                        inserter = {
                            fields = {
                                hand_read_mode = {
                                    fields = {
                                        'hold',
                                        'pulse'
                                    }
                                }
                            }
                        },
                        lamp = {
                            fields = {
                                color_mode = {
                                    fields = {
                                        'color_mapping',
                                        'components',
                                        'packed_rgb'
                                    }
                                }
                            }
                        },
                        mining_drill = {
                            fields = {
                                resource_read_mode = {
                                    fields = {
                                        'entire_patch',
                                        'this_miner'
                                    }
                                }
                            }
                        },
                        radar = {
                            fields = {
                                mode = {
                                    fields = {
                                        'surface',
                                        'universe'
                                    }
                                }
                            }
                        },
                        roboport = {
                            fields = {
                                read_items_mode = {
                                    fields = {
                                        'logistics',
                                        'missing_requests',
                                        'none'
                                    }
                                }
                            }
                        },
                        rocket_silo = {
                            fields = {
                                read_mode = {
                                    fields = {
                                        'logistic_inventory',
                                        'none',
                                        'orbital_requests'
                                    }
                                }
                            }
                        },
                        single_fluid_box = {
                            fields = {
                                exclusive_mode = {
                                    fields = {
                                        'none',
                                        'send_contents',
                                        'send_segment_contents'
                                    }
                                }
                            }
                        },
                        transport_belt = {
                            fields = {
                                content_read_mode = {
                                    fields = {
                                        'entire_belt_hold',
                                        'hold',
                                        'pulse'
                                    }
                                }
                            }
                        },
                        type = {
                            fields = {
                                'accumulator',
                                'agricultural_tower',
                                'arithmetic_combinator',
                                'artillery_turret',
                                'assembling_machine',
                                'asteroid_collector',
                                'boiler',
                                'cargo_landing_pad',
                                'constant_combinator',
                                'container',
                                'decider_combinator',
                                'display_panel',
                                'furnace',
                                'generic_on_off',
                                'heat_pipe',
                                'inserter',
                                'lab',
                                'lamp',
                                'land_mine',
                                'loader',
                                'logistic_container',
                                'mining_drill',
                                'programmable_speaker',
                                'proxy_container',
                                'pump',
                                'radar',
                                'rail_chain_signal',
                                'rail_signal',
                                'reactor',
                                'roboport',
                                'rocket_silo',
                                'selector_combinator',
                                'single_fluid_box',
                                'space_platform_hub',
                                'splitter',
                                'train_stop',
                                'transport_belt',
                                'turret',
                                'wall'
                            }
                        }
                    }
                },
                controllers = {
                    fields = {
                        'character',
                        'cutscene',
                        'editor',
                        'ghost',
                        'god',
                        'remote',
                        'spectator'
                    }
                },
                deconstruction_item = {
                    fields = {
                        entity_filter_mode = {
                            fields = {
                                'blacklist',
                                'whitelist'
                            }
                        },
                        tile_filter_mode = {
                            fields = {
                                'blacklist',
                                'whitelist'
                            }
                        },
                        tile_selection_mode = {
                            fields = {
                                'always',
                                'never',
                                'normal',
                                'only'
                            }
                        }
                    }
                },
                difficulty = {
                    fields = {
                        'easy',
                        'hard',
                        'normal'
                    }
                },
                direction = {
                    fields = {
                        'east',
                        'eastnortheast',
                        'eastsoutheast',
                        'north',
                        'northeast',
                        'northnortheast',
                        'northnorthwest',
                        'northwest',
                        'south',
                        'southeast',
                        'southsoutheast',
                        'southsouthwest',
                        'southwest',
                        'west',
                        'westnorthwest',
                        'westsouthwest'
                    }
                },
                disconnect_reason = {
                    fields = {
                        'afk',
                        'banned',
                        'cannot_keep_up',
                        'desync_limit_reached',
                        'dropped',
                        'kicked',
                        'kicked_and_deleted',
                        'quit',
                        'reconnect',
                        'switching_servers',
                        'wrong_input'
                    }
                },
                distraction = {
                    fields = {
                        'by_anything',
                        'by_damage',
                        'by_enemy',
                        'none'
                    }
                },
                electric_interface_mode = {
                    fields = {
                        'accumulator',
                        'primary_input',
                        'primary_output',
                        'secondary_input',
                        'secondary_output',
                        'solar_output',
                        'tertiary_input',
                        'tertiary_input_output',
                        'tertiary_output'
                    }
                },
                entity_status = {
                    fields = {
                        'armed',
                        'broken',
                        'cant_divide_segments',
                        'charging',
                        'closed_by_circuit_network',
                        'computing_navigation',
                        'destination_stop_full',
                        'disabled',
                        'disabled_by_control_behavior',
                        'disabled_by_script',
                        'discharging',
                        'fluid_ingredient_shortage',
                        'frozen',
                        'full_burnt_result_output',
                        'full_output',
                        'fully_charged',
                        'ghost',
                        'hatches_blocked_by_elevated_rail',
                        'input_fluid_too_cold',
                        'input_fluid_too_hot',
                        'item_ingredient_shortage',
                        'launching_rocket',
                        'low_input_fluid',
                        'low_power',
                        'low_temperature',
                        'marked_for_deconstruction',
                        'missing_required_fluid',
                        'missing_science_packs',
                        'networks_connected',
                        'networks_disconnected',
                        'no_ammo',
                        'no_filter',
                        'no_fuel',
                        'no_ingredients',
                        'no_input_fluid',
                        'no_minable_resources',
                        'no_modules_to_transmit',
                        'no_path',
                        'no_power',
                        'no_recipe',
                        'no_research_in_progress',
                        'no_spot_seedable_by_inputs',
                        'normal',
                        'not_connected_to_hub_or_pad',
                        'not_connected_to_rail',
                        'not_enough_space_in_output',
                        'not_enough_thrust',
                        'not_plugged_in_electric_network',
                        'on_the_way',
                        'opened_by_circuit_network',
                        'out_of_logistic_network',
                        'paused',
                        'pipeline_overextended',
                        'preparing_rocket_for_launch',
                        'recharging_after_power_outage',
                        'recipe_is_parameter',
                        'recipe_not_researched',
                        'thrust_not_required',
                        'too_far_from_pad_to_unload',
                        'turned_off_during_daytime',
                        'waiting_at_stop',
                        'waiting_for_more_items',
                        'waiting_for_plants_to_grow',
                        'waiting_for_rockets_to_arrive',
                        'waiting_for_source_items',
                        'waiting_for_space_in_destination',
                        'waiting_for_space_in_platform_hub',
                        'waiting_for_target_to_be_built',
                        'waiting_for_train',
                        'waiting_for_upgrade',
                        'waiting_in_orbit',
                        'waiting_to_clear_drop_slots',
                        'waiting_to_launch_rocket',
                        'working'
                    }
                },
                entity_status_diode = {
                    fields = {
                        'green',
                        'red',
                        'yellow'
                    }
                },
                events = {
                    fields = {
                        'on_achievement_gained',
                        'on_ai_command_completed',
                        'on_area_cloned',
                        'on_biter_base_built',
                        'on_blueprint_settings_pasted',
                        'on_brush_cloned',
                        'on_build_base_arrived',
                        'on_built_entity',
                        'on_cancelled_deconstruction',
                        'on_cancelled_upgrade',
                        'on_cargo_pod_delivered_cargo',
                        'on_cargo_pod_finished_ascending',
                        'on_cargo_pod_finished_descending',
                        'on_cargo_pod_started_ascending',
                        'on_character_corpse_expired',
                        'on_chart_tag_added',
                        'on_chart_tag_modified',
                        'on_chart_tag_removed',
                        'on_chunk_charted',
                        'on_chunk_deleted',
                        'on_chunk_generated',
                        'on_combat_robot_expired',
                        'on_console_chat',
                        'on_console_command',
                        'on_cutscene_cancelled',
                        'on_cutscene_finished',
                        'on_cutscene_started',
                        'on_cutscene_waypoint_reached',
                        'on_entity_cloned',
                        'on_entity_color_changed',
                        'on_entity_damaged',
                        'on_entity_died',
                        'on_entity_logistic_slot_changed',
                        'on_entity_renamed',
                        'on_entity_settings_pasted',
                        'on_entity_spawned',
                        'on_equipment_inserted',
                        'on_equipment_removed',
                        'on_force_cease_fire_changed',
                        'on_force_created',
                        'on_force_friends_changed',
                        'on_force_reset',
                        'on_forces_merged',
                        'on_forces_merging',
                        'on_game_created_from_scenario',
                        'on_gui_checked_state_changed',
                        'on_gui_click',
                        'on_gui_closed',
                        'on_gui_confirmed',
                        'on_gui_elem_changed',
                        'on_gui_hover',
                        'on_gui_inventory_action',
                        'on_gui_leave',
                        'on_gui_location_changed',
                        'on_gui_opened',
                        'on_gui_selected_tab_changed',
                        'on_gui_selection_state_changed',
                        'on_gui_switch_state_changed',
                        'on_gui_text_changed',
                        'on_gui_value_changed',
                        'on_land_mine_armed',
                        'on_lua_shortcut',
                        'on_marked_for_deconstruction',
                        'on_marked_for_upgrade',
                        'on_market_item_purchased',
                        'on_mod_item_opened',
                        'on_multiplayer_init',
                        'on_next_day_started',
                        'on_object_destroyed',
                        'on_permission_group_added',
                        'on_permission_group_deleted',
                        'on_permission_group_edited',
                        'on_permission_string_imported',
                        'on_picked_up_item',
                        'on_player_alt_reverse_selected_area',
                        'on_player_alt_selected_area',
                        'on_player_ammo_inventory_changed',
                        'on_player_armor_inventory_changed',
                        'on_player_banned',
                        'on_player_built_tile',
                        'on_player_cancel_selected_area',
                        'on_player_cancelled_crafting',
                        'on_player_change_selected_area',
                        'on_player_changed_force',
                        'on_player_changed_position',
                        'on_player_changed_surface',
                        'on_player_cheat_mode_disabled',
                        'on_player_cheat_mode_enabled',
                        'on_player_clicked_gps_tag',
                        'on_player_color_changed',
                        'on_player_configured_blueprint',
                        'on_player_controller_changed',
                        'on_player_crafted_item',
                        'on_player_created',
                        'on_player_cursor_stack_changed',
                        'on_player_deconstructed_area',
                        'on_player_demoted',
                        'on_player_died',
                        'on_player_display_density_scale_changed',
                        'on_player_display_resolution_changed',
                        'on_player_display_scale_changed',
                        'on_player_driving_changed_state',
                        'on_player_dropped_item',
                        'on_player_dropped_item_into_entity',
                        'on_player_fast_transferred',
                        'on_player_flipped_entity',
                        'on_player_flushed_fluid',
                        'on_player_gun_inventory_changed',
                        'on_player_input_method_changed',
                        'on_player_joined_game',
                        'on_player_kicked',
                        'on_player_left_game',
                        'on_player_locale_changed',
                        'on_player_main_inventory_changed',
                        'on_player_mined_entity',
                        'on_player_mined_item',
                        'on_player_mined_tile',
                        'on_player_music_changed',
                        'on_player_muted',
                        'on_player_pipette',
                        'on_player_placed_equipment',
                        'on_player_promoted',
                        'on_player_removed',
                        'on_player_removed_equipment',
                        'on_player_repaired_entity',
                        'on_player_respawned',
                        'on_player_reverse_selected_area',
                        'on_player_rotated_entity',
                        'on_player_selected_area',
                        'on_player_set_quick_bar_slot',
                        'on_player_setup_blueprint',
                        'on_player_start_selected_area',
                        'on_player_super_forced_selected_area',
                        'on_player_toggled_alt_mode',
                        'on_player_toggled_map_editor',
                        'on_player_trash_inventory_changed',
                        'on_player_unbanned',
                        'on_player_unmuted',
                        'on_player_used_capsule',
                        'on_player_used_spidertron_remote',
                        'on_post_entity_died',
                        'on_post_segmented_unit_died',
                        'on_pre_build',
                        'on_pre_chunk_deleted',
                        'on_pre_entity_settings_pasted',
                        'on_pre_ghost_deconstructed',
                        'on_pre_ghost_upgraded',
                        'on_pre_permission_group_deleted',
                        'on_pre_permission_string_imported',
                        'on_pre_player_crafted_item',
                        'on_pre_player_died',
                        'on_pre_player_left_game',
                        'on_pre_player_mined_item',
                        'on_pre_player_removed',
                        'on_pre_player_toggled_map_editor',
                        'on_pre_robot_exploded_cliff',
                        'on_pre_scenario_finished',
                        'on_pre_script_inventory_resized',
                        'on_pre_surface_cleared',
                        'on_pre_surface_deleted',
                        'on_redo_applied',
                        'on_research_cancelled',
                        'on_research_finished',
                        'on_research_moved',
                        'on_research_queued',
                        'on_research_reversed',
                        'on_research_started',
                        'on_resource_depleted',
                        'on_robot_built_entity',
                        'on_robot_built_tile',
                        'on_robot_exploded_cliff',
                        'on_robot_mined',
                        'on_robot_mined_entity',
                        'on_robot_mined_tile',
                        'on_robot_pre_mined',
                        'on_rocket_launch_ordered',
                        'on_rocket_launched',
                        'on_runtime_mod_setting_changed',
                        'on_script_inventory_resized',
                        'on_script_path_request_finished',
                        'on_script_trigger_effect',
                        'on_sector_scanned',
                        'on_segment_entity_created',
                        'on_segmented_unit_created',
                        'on_segmented_unit_damaged',
                        'on_segmented_unit_died',
                        'on_selected_entity_changed',
                        'on_singleplayer_init',
                        'on_space_platform_built_entity',
                        'on_space_platform_built_tile',
                        'on_space_platform_changed_state',
                        'on_space_platform_mined_entity',
                        'on_space_platform_mined_item',
                        'on_space_platform_mined_tile',
                        'on_space_platform_pre_mined',
                        'on_spider_command_completed',
                        'on_string_translated',
                        'on_surface_cleared',
                        'on_surface_created',
                        'on_surface_deleted',
                        'on_surface_imported',
                        'on_surface_renamed',
                        'on_technology_effects_reset',
                        'on_territory_created',
                        'on_territory_destroyed',
                        'on_tick',
                        'on_tower_mined_plant',
                        'on_tower_planted_seed',
                        'on_tower_pre_mined_plant',
                        'on_train_changed_state',
                        'on_train_created',
                        'on_train_schedule_changed',
                        'on_trigger_created_entity',
                        'on_trigger_fired_artillery',
                        'on_udp_packet_received',
                        'on_undo_applied',
                        'on_unit_added_to_group',
                        'on_unit_group_created',
                        'on_unit_group_finished_gathering',
                        'on_unit_removed_from_group',
                        'on_worker_robot_expired',
                        'script_raised_built',
                        'script_raised_destroy',
                        'script_raised_destroy_segmented_unit',
                        'script_raised_revive',
                        'script_raised_set_tiles',
                        'script_raised_teleported'
                    }
                },
                flow_precision_index = {
                    fields = {
                        'fifty_hours',
                        'five_seconds',
                        'one_hour',
                        'one_minute',
                        'one_thousand_hours',
                        'ten_hours',
                        'ten_minutes',
                        'two_hundred_fifty_hours'
                    }
                },
                game_controller_interaction = {
                    fields = {
                        'always',
                        'never',
                        'normal'
                    }
                },
                group_state = {
                    fields = {
                        'attacking_distraction',
                        'attacking_target',
                        'finished',
                        'gathering',
                        'moving',
                        'pathfinding',
                        'wander_in_group'
                    }
                },
                gui_type = {
                    fields = {
                        'achievement',
                        'alerts_config',
                        'blueprint_library',
                        'bonus',
                        'controller',
                        'custom',
                        'entity',
                        'equipment',
                        'global_electric_network',
                        'item',
                        'logistic',
                        'none',
                        'opened_entity_grid',
                        'other_player',
                        'permissions',
                        'player_management',
                        'production',
                        'script_inventory',
                        'server_management',
                        'tile',
                        'trains'
                    }
                },
                input_action = {
                    fields = {
                        'activate_interrupt',
                        'activate_paste',
                        'add_decider_combinator_condition',
                        'add_decider_combinator_else_output',
                        'add_decider_combinator_output',
                        'add_logistic_section',
                        'add_permission_group',
                        'add_pin',
                        'add_train_interrupt',
                        'add_train_station',
                        'adjust_blueprint_snapping',
                        'admin_action',
                        'alt_select_blueprint_entities',
                        'alternative_copy',
                        'begin_mining',
                        'begin_mining_terrain',
                        'build',
                        'build_rail',
                        'build_terrain',
                        'cancel_craft',
                        'cancel_deconstruct',
                        'cancel_delete_space_platform',
                        'cancel_new_blueprint',
                        'cancel_research',
                        'cancel_select_area',
                        'cancel_upgrade',
                        'change_active_character_tab',
                        'change_active_item_group_for_crafting',
                        'change_active_item_group_for_filters',
                        'change_active_quick_bar',
                        'change_arithmetic_combinator_parameters',
                        'change_entity_label',
                        'change_heading_riding_state',
                        'change_item_label',
                        'change_logistic_point_group',
                        'change_multiplayer_config',
                        'change_picking_state',
                        'change_programmable_speaker_alert_parameters',
                        'change_programmable_speaker_circuit_parameters',
                        'change_programmable_speaker_parameters',
                        'change_research_condition',
                        'change_riding_state',
                        'change_select_area',
                        'change_selector_combinator_parameters',
                        'change_shooting_state',
                        'change_train_name',
                        'change_train_station',
                        'change_train_stop_station',
                        'change_train_wait_condition',
                        'change_train_wait_condition_data',
                        'cheat',
                        'clear_cursor',
                        'connect_rolling_stock',
                        'copy',
                        'copy_entity_settings',
                        'copy_large_opened_blueprint',
                        'copy_large_opened_item',
                        'copy_opened_blueprint',
                        'copy_opened_item',
                        'craft',
                        'create_space_platform',
                        'cursor_split',
                        'cursor_transfer',
                        'custom_input',
                        'cycle_blueprint_book_backwards',
                        'cycle_blueprint_book_forwards',
                        'cycle_quality_down',
                        'cycle_quality_up',
                        'deconstruct',
                        'delete_blueprint_library',
                        'delete_blueprint_record',
                        'delete_custom_tag',
                        'delete_logistic_group',
                        'delete_permission_group',
                        'delete_space_platform',
                        'destroy_item',
                        'destroy_opened_item',
                        'disconnect_rolling_stock',
                        'drag_decider_combinator_condition',
                        'drag_decider_combinator_else_output',
                        'drag_decider_combinator_output',
                        'drag_research_condition',
                        'drag_train_schedule',
                        'drag_train_schedule_interrupt',
                        'drag_train_wait_condition',
                        'drop_blueprint_record',
                        'drop_item',
                        'edit_blueprint_tool_preview',
                        'edit_custom_tag',
                        'edit_display_panel',
                        'edit_display_panel_always_show',
                        'edit_display_panel_icon',
                        'edit_display_panel_parameters',
                        'edit_display_panel_show_in_chart',
                        'edit_display_panel_single_entry',
                        'edit_interrupt',
                        'edit_permission_group',
                        'edit_pin',
                        'export_blueprint',
                        'fast_entity_split',
                        'fast_entity_transfer',
                        'flip_entity',
                        'flush_opened_entity_fluid',
                        'flush_opened_entity_specific_fluid',
                        'go_to_train_station',
                        'grab_blueprint_record',
                        'gui_checked_state_changed',
                        'gui_click',
                        'gui_confirmed',
                        'gui_elem_changed',
                        'gui_hover',
                        'gui_inventory_action',
                        'gui_inventory_bar_changed',
                        'gui_inventory_filter_changed',
                        'gui_leave',
                        'gui_location_changed',
                        'gui_selected_tab_changed',
                        'gui_selection_state_changed',
                        'gui_switch_state_changed',
                        'gui_text_changed',
                        'gui_value_changed',
                        'import_blueprint',
                        'import_blueprint_string',
                        'import_blueprints_filtered',
                        'import_permissions_string',
                        'instantly_create_space_platform',
                        'inventory_split',
                        'inventory_transfer',
                        'land_at_planet',
                        'launch_rocket',
                        'lua_shortcut',
                        'map_editor_action',
                        'market_offer',
                        'mod_settings_changed',
                        'modify_decider_combinator_condition',
                        'modify_decider_combinator_else_output',
                        'modify_decider_combinator_output',
                        'move_pin',
                        'move_research',
                        'open_achievements_gui',
                        'open_alerts_config_gui',
                        'open_blueprint_library_gui',
                        'open_blueprint_record',
                        'open_bonus_gui',
                        'open_character_gui',
                        'open_current_vehicle_gui',
                        'open_equipment',
                        'open_global_electric_network_gui',
                        'open_gui',
                        'open_item',
                        'open_logistics_gui',
                        'open_mod_item',
                        'open_new_platform_button_from_rocket_silo',
                        'open_opened_entity_grid',
                        'open_parent_of_opened_item',
                        'open_production_gui',
                        'open_train_gui',
                        'open_train_station_gui',
                        'open_trains_gui',
                        'parametrise_blueprint',
                        'paste_entity_settings',
                        'pin_alert_group',
                        'pin_custom_alert',
                        'pin_search_result',
                        'pipette',
                        'place_equipment',
                        'providing_to_other_platforms',
                        'quick_bar_pick_slot',
                        'quick_bar_set_selected_page',
                        'quick_bar_set_slot',
                        'reassign_blueprint',
                        'redo',
                        'remote_view_entity',
                        'remote_view_surface',
                        'remove_cables',
                        'remove_decider_combinator_condition',
                        'remove_decider_combinator_else_output',
                        'remove_decider_combinator_output',
                        'remove_logistic_section',
                        'remove_pin',
                        'remove_train_interrupt',
                        'remove_train_station',
                        'rename_interrupt',
                        'rename_space_platform',
                        'reorder_logistic_section',
                        'request_missing_construction_materials',
                        'reset_assembling_machine',
                        'rotate_entity',
                        'select_area',
                        'select_asteroid_chunk_slot',
                        'select_blueprint_entities',
                        'select_entity_filter_slot',
                        'select_entity_slot',
                        'select_item_filter',
                        'select_mapper_slot_from',
                        'select_mapper_slot_to',
                        'select_next_valid_gun',
                        'select_tile_slot',
                        'send_spidertron',
                        'send_stack_to_trash',
                        'send_stacks_to_trash',
                        'send_train_to_pin_target',
                        'set_behavior_mode',
                        'set_car_weapons_control',
                        'set_cheat_mode_quality',
                        'set_circuit_condition',
                        'set_circuit_mode_of_operation',
                        'set_combinator_description',
                        'set_control_behavior_input_networks',
                        'set_control_behavior_output_networks',
                        'set_copy_color_from_train_stop',
                        'set_deconstruction_item_tile_selection_mode',
                        'set_deconstruction_item_trees_and_rocks_only',
                        'set_entity_color',
                        'set_entity_energy_property',
                        'set_equipment_energy_property',
                        'set_filter',
                        'set_ghost_cursor',
                        'set_heat_interface_mode',
                        'set_heat_interface_temperature',
                        'set_infinity_container_filter_item',
                        'set_infinity_container_logistic_mode',
                        'set_infinity_container_remove_unfiltered_items',
                        'set_infinity_pipe_filter',
                        'set_inserter_max_stack_size',
                        'set_inventory_bar',
                        'set_lamp_always_on',
                        'set_linked_container_link_i_d',
                        'set_loader_belt_stack_size_override',
                        'set_logistic_filter_item',
                        'set_logistic_network_name',
                        'set_logistic_section_active',
                        'set_player_color',
                        'set_pump_fluid_filter',
                        'set_request_from_buffers',
                        'set_research_finished_stops_game',
                        'set_rocket_silo_send_to_orbit_automated_mode',
                        'set_schedule_record_allow_unloading',
                        'set_signal',
                        'set_splitter_priority',
                        'set_spoil_priority',
                        'set_train_stop_priority',
                        'set_train_stopped',
                        'set_trains_limit',
                        'set_turret_ignore_unlisted',
                        'set_use_inserter_filters',
                        'set_vehicle_automatic_targeting_parameters',
                        'setup_assembling_machine',
                        'setup_blueprint',
                        'setup_single_blueprint_record',
                        'spawn_item',
                        'spectator_change_surface',
                        'stack_split',
                        'stack_transfer',
                        'start_repair',
                        'start_research',
                        'start_select_area',
                        'start_walking',
                        'stop_drag_build',
                        'swap_asteroid_chunk_slots',
                        'swap_entity_filter_slots',
                        'swap_entity_slots',
                        'swap_infinity_container_filter_items',
                        'swap_item_filters',
                        'swap_logistic_filter_items',
                        'swap_mappers',
                        'swap_tile_slots',
                        'switch_connect_to_logistic_network',
                        'switch_constant_combinator_state',
                        'switch_inserter_filter_mode_state',
                        'switch_loader_filter_mode',
                        'switch_mining_drill_filter_mode_state',
                        'switch_power_switch_state',
                        'take_equipment',
                        'toggle_artillery_auto_targeting',
                        'toggle_blueprint_snap_to_grid',
                        'toggle_deconstruction_item_entity_filter_mode',
                        'toggle_deconstruction_item_tile_filter_mode',
                        'toggle_driving',
                        'toggle_enable_vehicle_logistics_while_moving',
                        'toggle_entity_logistic_requests',
                        'toggle_equipment_movement_bonus',
                        'toggle_map_editor',
                        'toggle_personal_logistic_requests',
                        'toggle_personal_roboport',
                        'toggle_selected_entity',
                        'toggle_show_entity_info',
                        'toggle_tall_entity_visibility',
                        'trash_not_requested_items',
                        'undo',
                        'upgrade',
                        'upgrade_opened_blueprint_by_item',
                        'upgrade_opened_blueprint_by_record',
                        'use_item',
                        'wire_dragging',
                        'write_to_console'
                    }
                },
                input_method = {
                    fields = {
                        'game_controller',
                        'keyboard_and_mouse'
                    }
                },
                inventory = {
                    fields = {
                        'agricultural_tower_input',
                        'agricultural_tower_modules',
                        'agricultural_tower_output',
                        'artillery_turret_ammo',
                        'artillery_wagon_ammo',
                        'assembling_machine_dump',
                        'asteroid_collector_arm',
                        'asteroid_collector_output',
                        'beacon_modules',
                        'burnt_result',
                        'car_ammo',
                        'car_trash',
                        'car_trunk',
                        'cargo_landing_pad_main',
                        'cargo_landing_pad_trash',
                        'cargo_unit',
                        'cargo_wagon',
                        'character_ammo',
                        'character_armor',
                        'character_corpse',
                        'character_guns',
                        'character_main',
                        'character_trash',
                        'character_vehicle',
                        'chest',
                        'crafter_input',
                        'crafter_modules',
                        'crafter_output',
                        'crafter_trash',
                        'editor_ammo',
                        'editor_armor',
                        'editor_guns',
                        'editor_main',
                        'fuel',
                        'god_main',
                        'hub_main',
                        'hub_trash',
                        'item_main',
                        'lab_input',
                        'lab_modules',
                        'lab_trash',
                        'linked_container_main',
                        'logistic_container_trash',
                        'mining_drill_modules',
                        'proxy_main',
                        'roboport_material',
                        'roboport_robot',
                        'robot_cargo',
                        'robot_repair',
                        'rocket_silo_attached_cargo_unit',
                        'rocket_silo_rocket',
                        'rocket_silo_trash',
                        'spider_ammo',
                        'spider_trash',
                        'spider_trunk',
                        'turret_ammo'
                    }
                },
                inventory_actions = {
                    fields = {
                        'cursor_split',
                        'cursor_transfer',
                        'inventory_split',
                        'inventory_transfer',
                        'open_item',
                        'open_mod_item',
                        'send_stack_to_trash',
                        'send_stacks_to_trash',
                        'stack_split',
                        'stack_transfer'
                    }
                },
                logistic_group_type = {
                    fields = {
                        'roboport',
                        'with_trash'
                    }
                },
                logistic_member_index = {
                    fields = {
                        'car_provider',
                        'car_requester',
                        'cargo_landing_pad_provider',
                        'cargo_landing_pad_requester',
                        'cargo_landing_pad_trash_provider',
                        'character_provider',
                        'character_requester',
                        'character_storage',
                        'generic_on_off_behavior',
                        'logistic_container',
                        'logistic_container_trash_provider',
                        'roboport_provider',
                        'roboport_requester',
                        'rocket_silo_provider',
                        'rocket_silo_requester',
                        'rocket_silo_trash_provider',
                        'space_platform_hub_provider',
                        'space_platform_hub_requester',
                        'spidertron_provider',
                        'spidertron_requester',
                        'vehicle_storage'
                    }
                },
                logistic_mode = {
                    fields = {
                        'active_provider',
                        'buffer',
                        'none',
                        'passive_provider',
                        'requester',
                        'storage'
                    }
                },
                logistic_section_type = {
                    fields = {
                        'circuit_controlled',
                        'manual',
                        'request_missing_materials_controlled',
                        'transitional_request_controlled'
                    }
                },
                mouse_button_type = {
                    fields = {
                        'left',
                        'middle',
                        'none',
                        'right'
                    }
                },
                moving_state = {
                    fields = {
                        'adaptive',
                        'moving',
                        'stale',
                        'stuck'
                    }
                },
                print_skip = {
                    fields = {
                        'if_redundant',
                        'if_visible',
                        'never'
                    }
                },
                print_sound = {
                    fields = {
                        'always',
                        'never',
                        'use_player_settings'
                    }
                },
                prototypes = {
                    fields = {
                        achievement = {
                            fields = {
                                'achievement',
                                'build-entity-achievement',
                                'change-surface-achievement',
                                'combat-robot-count-achievement',
                                'complete-objective-achievement',
                                'construct-with-robots-achievement',
                                'create-platform-achievement',
                                'deconstruct-with-robots-achievement',
                                'deliver-by-robots-achievement',
                                'deplete-resource-achievement',
                                'destroy-cliff-achievement',
                                'dont-build-entity-achievement',
                                'dont-craft-manually-achievement',
                                'dont-kill-manually-achievement',
                                'dont-research-before-researching-achievement',
                                'dont-use-entity-in-energy-production-achievement',
                                'equip-armor-achievement',
                                'group-attack-achievement',
                                'kill-achievement',
                                'module-transfer-achievement',
                                'place-equipment-achievement',
                                'player-damaged-achievement',
                                'produce-achievement',
                                'produce-per-hour-achievement',
                                'research-achievement',
                                'research-with-science-pack-achievement',
                                'shoot-achievement',
                                'space-connection-distance-traveled-achievement',
                                'train-path-achievement',
                                'use-entity-in-energy-production-achievement',
                                'use-item-achievement'
                            }
                        },
                        ['active-trigger'] = {
                            fields = {
                                'chain-active-trigger',
                                'delayed-active-trigger'
                            }
                        },
                        ['airborne-pollutant'] = {
                            fields = {
                                'airborne-pollutant'
                            }
                        },
                        ['ambient-sound'] = {
                            fields = {
                                'ambient-sound'
                            }
                        },
                        ['ammo-category'] = {
                            fields = {
                                'ammo-category'
                            }
                        },
                        animation = {
                            fields = {
                                'animation'
                            }
                        },
                        ['asteroid-chunk'] = {
                            fields = {
                                'asteroid-chunk'
                            }
                        },
                        ['autoplace-control'] = {
                            fields = {
                                'autoplace-control'
                            }
                        },
                        ['burner-usage'] = {
                            fields = {
                                'burner-usage'
                            }
                        },
                        ['collision-layer'] = {
                            fields = {
                                'collision-layer'
                            }
                        },
                        ['custom-event'] = {
                            fields = {
                                'custom-event'
                            }
                        },
                        ['custom-input'] = {
                            fields = {
                                'custom-input'
                            }
                        },
                        ['damage-type'] = {
                            fields = {
                                'damage-type'
                            }
                        },
                        decorative = {
                            fields = {
                                'optimized-decorative'
                            }
                        },
                        ['deliver-category'] = {
                            fields = {
                                'deliver-category'
                            }
                        },
                        ['deliver-impact-combination'] = {
                            fields = {
                                'deliver-impact-combination'
                            }
                        },
                        ['editor-controller'] = {
                            fields = {
                                'editor-controller'
                            }
                        },
                        entity = {
                            fields = {
                                'accumulator',
                                'agricultural-tower',
                                'ammo-turret',
                                'arithmetic-combinator',
                                'arrow',
                                'artillery-flare',
                                'artillery-projectile',
                                'artillery-turret',
                                'artillery-wagon',
                                'assembling-machine',
                                'asteroid',
                                'asteroid-collector',
                                'beacon',
                                'beam',
                                'boiler',
                                'burner-generator',
                                'capture-robot',
                                'car',
                                'cargo-bay',
                                'cargo-landing-pad',
                                'cargo-pod',
                                'cargo-wagon',
                                'character',
                                'character-corpse',
                                'cliff',
                                'combat-robot',
                                'constant-combinator',
                                'construction-robot',
                                'container',
                                'corpse',
                                'curved-rail-a',
                                'curved-rail-b',
                                'decider-combinator',
                                'deconstructible-tile-proxy',
                                'display-panel',
                                'electric-energy-interface',
                                'electric-pole',
                                'electric-turret',
                                'elevated-curved-rail-a',
                                'elevated-curved-rail-b',
                                'elevated-half-diagonal-rail',
                                'elevated-straight-rail',
                                'entity-ghost',
                                'explosion',
                                'fire',
                                'fish',
                                'fluid-turret',
                                'fluid-wagon',
                                'furnace',
                                'fusion-generator',
                                'fusion-reactor',
                                'gate',
                                'generator',
                                'half-diagonal-rail',
                                'heat-interface',
                                'heat-pipe',
                                'highlight-box',
                                'infinity-cargo-wagon',
                                'infinity-container',
                                'infinity-pipe',
                                'inserter',
                                'item-entity',
                                'item-request-proxy',
                                'lab',
                                'lamp',
                                'land-mine',
                                'lane-splitter',
                                'legacy-curved-rail',
                                'legacy-straight-rail',
                                'lightning',
                                'lightning-attractor',
                                'linked-belt',
                                'linked-container',
                                'loader',
                                'loader-1x1',
                                'locomotive',
                                'logistic-container',
                                'logistic-robot',
                                'market',
                                'mining-drill',
                                'offshore-pump',
                                'particle-source',
                                'pipe',
                                'pipe-to-ground',
                                'plant',
                                'player-port',
                                'power-switch',
                                'programmable-speaker',
                                'projectile',
                                'proxy-container',
                                'pump',
                                'radar',
                                'rail-chain-signal',
                                'rail-ramp',
                                'rail-remnants',
                                'rail-signal',
                                'rail-support',
                                'reactor',
                                'resource',
                                'roboport',
                                'rocket-silo',
                                'rocket-silo-rocket',
                                'rocket-silo-rocket-shadow',
                                'segment',
                                'segmented-unit',
                                'selector-combinator',
                                'simple-entity',
                                'simple-entity-with-force',
                                'simple-entity-with-owner',
                                'smoke-with-trigger',
                                'solar-panel',
                                'space-platform-hub',
                                'speech-bubble',
                                'spider-leg',
                                'spider-unit',
                                'spider-vehicle',
                                'splitter',
                                'sticker',
                                'storage-tank',
                                'straight-rail',
                                'stream',
                                'temporary-container',
                                'thruster',
                                'tile-ghost',
                                'train-stop',
                                'transport-belt',
                                'tree',
                                'turret',
                                'underground-belt',
                                'unit',
                                'unit-spawner',
                                'valve',
                                'wall'
                            }
                        },
                        equipment = {
                            fields = {
                                'active-defense-equipment',
                                'battery-equipment',
                                'belt-immunity-equipment',
                                'electric-energy-interface-equipment',
                                'energy-shield-equipment',
                                'equipment-ghost',
                                'generator-equipment',
                                'inventory-bonus-equipment',
                                'movement-bonus-equipment',
                                'night-vision-equipment',
                                'roboport-equipment',
                                'solar-panel-equipment'
                            }
                        },
                        ['equipment-category'] = {
                            fields = {
                                'equipment-category'
                            }
                        },
                        ['equipment-grid'] = {
                            fields = {
                                'equipment-grid'
                            }
                        },
                        fluid = {
                            fields = {
                                'fluid'
                            }
                        },
                        font = {
                            fields = {
                                'font'
                            }
                        },
                        ['fuel-category'] = {
                            fields = {
                                'fuel-category'
                            }
                        },
                        ['god-controller'] = {
                            fields = {
                                'god-controller'
                            }
                        },
                        ['gui-style'] = {
                            fields = {
                                'gui-style'
                            }
                        },
                        ['impact-category'] = {
                            fields = {
                                'impact-category'
                            }
                        },
                        item = {
                            fields = {
                                'ammo',
                                'armor',
                                'blueprint',
                                'blueprint-book',
                                'capsule',
                                'copy-paste-tool',
                                'deconstruction-item',
                                'gun',
                                'item',
                                'item-with-entity-data',
                                'item-with-inventory',
                                'item-with-label',
                                'item-with-tags',
                                'module',
                                'rail-planner',
                                'repair-tool',
                                'selection-tool',
                                'space-platform-starter-pack',
                                'spidertron-remote',
                                'tool',
                                'upgrade-item'
                            }
                        },
                        ['item-group'] = {
                            fields = {
                                'item-group'
                            }
                        },
                        ['item-subgroup'] = {
                            fields = {
                                'item-subgroup'
                            }
                        },
                        ['map-gen-presets'] = {
                            fields = {
                                'map-gen-presets'
                            }
                        },
                        ['map-settings'] = {
                            fields = {
                                'map-settings'
                            }
                        },
                        ['mod-data'] = {
                            fields = {
                                'mod-data'
                            }
                        },
                        ['module-category'] = {
                            fields = {
                                'module-category'
                            }
                        },
                        ['mouse-cursor'] = {
                            fields = {
                                'mouse-cursor'
                            }
                        },
                        ['noise-expression'] = {
                            fields = {
                                'noise-expression'
                            }
                        },
                        ['noise-function'] = {
                            fields = {
                                'noise-function'
                            }
                        },
                        particle = {
                            fields = {
                                'optimized-particle'
                            }
                        },
                        procession = {
                            fields = {
                                'procession'
                            }
                        },
                        ['procession-layer-inheritance-group'] = {
                            fields = {
                                'procession-layer-inheritance-group'
                            }
                        },
                        quality = {
                            fields = {
                                'quality'
                            }
                        },
                        recipe = {
                            fields = {
                                'recipe'
                            }
                        },
                        ['recipe-category'] = {
                            fields = {
                                'recipe-category'
                            }
                        },
                        ['remote-controller'] = {
                            fields = {
                                'remote-controller'
                            }
                        },
                        ['resource-category'] = {
                            fields = {
                                'resource-category'
                            }
                        },
                        shortcut = {
                            fields = {
                                'shortcut'
                            }
                        },
                        sound = {
                            fields = {
                                'sound'
                            }
                        },
                        ['space-connection'] = {
                            fields = {
                                'space-connection'
                            }
                        },
                        ['space-location'] = {
                            fields = {
                                'planet',
                                'space-location'
                            }
                        },
                        ['spectator-controller'] = {
                            fields = {
                                'spectator-controller'
                            }
                        },
                        sprite = {
                            fields = {
                                'sprite'
                            }
                        },
                        surface = {
                            fields = {
                                'surface'
                            }
                        },
                        ['surface-property'] = {
                            fields = {
                                'surface-property'
                            }
                        },
                        technology = {
                            fields = {
                                'technology'
                            }
                        },
                        tile = {
                            fields = {
                                'tile'
                            }
                        },
                        ['tile-effect'] = {
                            fields = {
                                'tile-effect'
                            }
                        },
                        ['tips-and-tricks-item'] = {
                            fields = {
                                'tips-and-tricks-item'
                            }
                        },
                        ['tips-and-tricks-item-category'] = {
                            fields = {
                                'tips-and-tricks-item-category'
                            }
                        },
                        ['trigger-target-type'] = {
                            fields = {
                                'trigger-target-type'
                            }
                        },
                        ['trivial-smoke'] = {
                            fields = {
                                'trivial-smoke'
                            }
                        },
                        tutorial = {
                            fields = {
                                'tutorial'
                            }
                        },
                        ['utility-constants'] = {
                            fields = {
                                'utility-constants'
                            }
                        },
                        ['utility-sounds'] = {
                            fields = {
                                'utility-sounds'
                            }
                        },
                        ['utility-sprites'] = {
                            fields = {
                                'utility-sprites'
                            }
                        },
                        ['virtual-signal'] = {
                            fields = {
                                'virtual-signal'
                            }
                        }
                    }
                },
                rail_connection_direction = {
                    fields = {
                        'left',
                        'none',
                        'right',
                        'straight'
                    }
                },
                rail_direction = {
                    fields = {
                        'back',
                        'front'
                    }
                },
                rail_layer = {
                    fields = {
                        'elevated',
                        'ground'
                    }
                },
                relative_gui_position = {
                    fields = {
                        'bottom',
                        'left',
                        'right',
                        'top'
                    }
                },
                relative_gui_type = {
                    fields = {
                        'accumulator_gui',
                        'achievement_gui',
                        'additional_entity_info_gui',
                        'admin_gui',
                        'agriculture_tower_gui',
                        'alerts_config_gui',
                        'arithmetic_combinator_gui',
                        'armor_gui',
                        'assembling_machine_gui',
                        'assembling_machine_select_recipe_gui',
                        'asteroid_collector_gui',
                        'beacon_gui',
                        'blueprint_book_gui',
                        'blueprint_library_gui',
                        'blueprint_setup_gui',
                        'boiler_gui',
                        'bonus_gui',
                        'burner_equipment_gui',
                        'car_gui',
                        'cargo_landing_pad_gui',
                        'constant_combinator_gui',
                        'container_gui',
                        'controller_gui',
                        'decider_combinator_gui',
                        'deconstruction_item_gui',
                        'display_panel_gui',
                        'electric_energy_interface_equipment_gui',
                        'electric_energy_interface_gui',
                        'electric_network_gui',
                        'entity_variations_gui',
                        'entity_with_energy_source_gui',
                        'equipment_grid_gui',
                        'furnace_gui',
                        'generic_on_off_entity_gui',
                        'ghost_picker_gui',
                        'global_electric_network_gui',
                        'heat_interface_gui',
                        'heat_pipe_gui',
                        'infinity_pipe_gui',
                        'inserter_gui',
                        'item_with_inventory_gui',
                        'lab_gui',
                        'lamp_gui',
                        'linked_container_gui',
                        'loader_gui',
                        'logistic_gui',
                        'market_gui',
                        'mining_drill_gui',
                        'other_player_gui',
                        'permissions_gui',
                        'pick_stop_gui',
                        'pipe_gui',
                        'power_switch_gui',
                        'production_gui',
                        'programmable_speaker_gui',
                        'proxy_container_gui',
                        'pump_gui',
                        'radar_gui',
                        'rail_signal_base_gui',
                        'reactor_gui',
                        'resource_entity_gui',
                        'roboport_gui',
                        'rocket_silo_gui',
                        'script_inventory_gui',
                        'selector_combinator_gui',
                        'server_config_gui',
                        'space_platform_hub_gui',
                        'spider_vehicle_gui',
                        'splitter_gui',
                        'standalone_character_gui',
                        'tile_variations_gui',
                        'tips_and_tricks_gui',
                        'train_gui',
                        'train_stop_gui',
                        'trains_gui',
                        'transport_belt_gui',
                        'turret_gui',
                        'upgrade_item_gui',
                        'wall_gui'
                    }
                },
                render_mode = {
                    fields = {
                        'chart',
                        'chart_zoomed_in',
                        'game'
                    }
                },
                rich_text_setting = {
                    fields = {
                        'disabled',
                        'enabled',
                        'highlight'
                    }
                },
                riding = {
                    fields = {
                        acceleration = {
                            fields = {
                                'accelerating',
                                'braking',
                                'nothing',
                                'reversing'
                            }
                        },
                        direction = {
                            fields = {
                                'left',
                                'right',
                                'straight'
                            }
                        }
                    }
                },
                robot_order_type = {
                    fields = {
                        'construct',
                        'deconstruct',
                        'deliver',
                        'deliver_items',
                        'explode_cliff',
                        'pickup',
                        'pickup_items',
                        'repair',
                        'upgrade'
                    }
                },
                rocket_silo_status = {
                    fields = {
                        'arms_advance',
                        'arms_retract',
                        'building_rocket',
                        'create_rocket',
                        'doors_closing',
                        'doors_opened',
                        'doors_opening',
                        'engine_starting',
                        'launch_started',
                        'launch_starting',
                        'lights_blinking_close',
                        'lights_blinking_open',
                        'rocket_flying',
                        'rocket_ready',
                        'rocket_rising'
                    }
                },
                segmented_unit_activity_mode = {
                    fields = {
                        'asleep',
                        'full',
                        'minimal'
                    }
                },
                segmented_unit_ai_state = {
                    fields = {
                        'attacking',
                        'enraged_at_nothing',
                        'enraged_at_target',
                        'investigating',
                        'patrolling'
                    }
                },
                segmented_unit_created_cause = {
                    fields = {
                        'map_generated',
                        'script_cloned',
                        'script_created'
                    }
                },
                selection_mode = {
                    fields = {
                        'alt_reverse_select',
                        'alt_select',
                        'reverse_select',
                        'select',
                        'super_forced_select'
                    }
                },
                shooting = {
                    fields = {
                        'not_shooting',
                        'shooting_enemies',
                        'shooting_selected'
                    }
                },
                signal_state = {
                    fields = {
                        'closed',
                        'open',
                        'reserved',
                        'reserved_by_circuit_network'
                    }
                },
                space_platform_state = {
                    fields = {
                        'no_path',
                        'no_schedule',
                        'on_the_path',
                        'paused',
                        'starter_pack_on_the_way',
                        'starter_pack_requested',
                        'waiting_at_station',
                        'waiting_for_departure',
                        'waiting_for_starter_pack'
                    }
                },
                target_type = {
                    fields = {
                        'cargo_hatch',
                        'commandable',
                        'custom_chart_tag',
                        'electric_network',
                        'electric_sub_network',
                        'entity',
                        'equipment',
                        'equipment_grid',
                        'force',
                        'gui_element',
                        'item',
                        'logistic_cell',
                        'logistic_network',
                        'logistic_section',
                        'permission_group',
                        'planet',
                        'player',
                        'rail_path',
                        'render_object',
                        'schedule',
                        'segmented_unit',
                        'space_platform',
                        'surface',
                        'territory',
                        'train'
                    }
                },
                territory_created_cause = {
                    fields = {
                        'map_generated',
                        'script_created'
                    }
                },
                train_state = {
                    fields = {
                        'arrive_signal',
                        'arrive_station',
                        'destination_full',
                        'manual_control',
                        'manual_control_stop',
                        'no_path',
                        'no_schedule',
                        'on_the_path',
                        'wait_signal',
                        'wait_station'
                    }
                },
                transport_line = {
                    fields = {
                        'left_line',
                        'left_split_line',
                        'left_underground_line',
                        'right_line',
                        'right_split_line',
                        'right_underground_line',
                        'secondary_left_line',
                        'secondary_left_split_line',
                        'secondary_right_line',
                        'secondary_right_split_line'
                    }
                },
                wire_connector_id = {
                    fields = {
                        'circuit_green',
                        'circuit_red',
                        'combinator_input_green',
                        'combinator_input_red',
                        'combinator_output_green',
                        'combinator_output_red',
                        'pole_copper',
                        'power_switch_left_copper',
                        'power_switch_right_copper'
                    }
                },
                wire_origin = {
                    fields = {
                        'player',
                        'radars',
                        'script'
                    }
                },
                wire_type = {
                    fields = {
                        'copper',
                        'green',
                        'red'
                    }
                }
            }
        }
    }
}--))

--[[ Options
    "ignore", "std", "globals", "unused_args", "self", "compat", "global", "unused", "redefined",
    "unused_secondaries", "allow_defined", "allow_defined_top", "module",
    "read_globals", "new_globals", "new_read_globals", "enable", "only", "not_globals",
    "max_line_length", "max_code_line_length", "max_string_line_length", "max_comment_line_length",
    "max_cyclomatic_complexity"
--]]

--[[ Warnings list
    -- 011 A syntax error.
    -- 021 An invalid inline option.
    -- 022 An unpaired inline push directive.
    -- 023 An unpaired inline pop directive.
    -- 111 Setting an undefined global variable.
    -- 112 Mutating an undefined global variable.
    -- 113 Accessing an undefined global variable.
    -- 121 Setting a read-only global variable.
    -- 122 Setting a read-only field of a global variable.
    -- 131 Unused implicitly defined global variable.
    -- 142 Setting an undefined field of a global variable.
    -- 143 Accessing an undefined field of a global variable.
    -- 211 Unused local variable.
    -- 212 Unused argument.
    -- 213 Unused loop variable.
    -- 221 Local variable is accessed but never set.
    -- 231 Local variable is set but never accessed.
    -- 232 An argument is set but never accessed.
    -- 233 Loop variable is set but never accessed.
    -- 241 Local variable is mutated but never accessed.
    -- 311 Value assigned to a local variable is unused.
    -- 312 Value of an argument is unused.
    -- 313 Value of a loop variable is unused.
    -- 314 Value of a field in a table literal is unused.
    -- 321 Accessing uninitialized local variable.
    -- 331 Value assigned to a local variable is mutated but never accessed.
    -- 341 Mutating uninitialized local variable.
    -- 411 Redefining a local variable.
    -- 412 Redefining an argument.
    -- 413 Redefining a loop variable.
    -- 421 Shadowing a local variable.
    -- 422 Shadowing an argument.
    -- 423 Shadowing a loop variable.
    -- 431 Shadowing an upvalue.
    -- 432 Shadowing an upvalue argument.
    -- 433 Shadowing an upvalue loop variable.
    -- 511 Unreachable code.
    -- 512 Loop can be executed at most once.
    -- 521 Unused label.
    -- 531 Left-hand side of an assignment is too short.
    -- 532 Left-hand side of an assignment is too long.
    -- 541 An empty do end block.
    -- 542 An empty if branch.
    -- 551 An empty statement.
    -- 611 A line consists of nothing but whitespace.
    -- 612 A line contains trailing whitespace.
    -- 613 Trailing whitespace in a string.
    -- 614 Trailing whitespace in a comment.
    -- 621 Inconsistent indentation (SPACE followed by TAB).
    -- 631 Line is too long.
--]]
