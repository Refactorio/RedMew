-- Danger Ores' intro cutscene, played to each new player (unless they turned off auto play) and
-- again with /replay. It has three parts:
--
-- 1. Welcome, on the map itself: a title card with the map's name and twist, then spawn.
-- 2. The rule, on a small staged surface: the ore field, what may be built on ore, what may not,
--    and cleared ground with a factory on it. The buildings on the ore are the map's own allowed
--    ones: each is placed on ore and kept only if the building restriction allows it, so the
--    scene can't show something the map refuses. The ore is shown here rather than on the map:
--    near spawn the map's ore is thin, and drawn so small it looks like bare ground.
-- 3. Back on the map, a card with the goal.
--
-- Player creation leaves the start-up messages and map info to the end of the cutscene.
local Event = require 'utils.event'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Cutscene = require 'features.cutscene.cutscene_controller'
local CS_Rendering = require 'features.cutscene.rendering'
local Color = require 'resources.color_presets'
local PC = require 'features.player_create'
local RS = require 'map_gen.shared.redmew_surface'
local Settings = require 'utils.redmew_settings'
local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'

local register_rendering = Cutscene.register_rendering
local play_sound = Cutscene.play_sound
local draw_text = CS_Rendering.draw_text
local draw_multi_line = CS_Rendering.draw_multi_line_text

local Public = {}

Public.surface_name = 'danger_ores_cutscene'
-- The stage's own force: what its line mines and smelts mustn't count toward the players' research
-- triggers (Steam power wants 50 iron plates) or their production statistics.
Public.force_name = 'danger_ores_cutscene'
Public.auto_play_setting_name = 'danger_ores.auto_play_cutscene'

local welcome_name = 'DangerOres_Welcome'
local rule_name = 'DangerOres_Rule'
local map_name = 'DangerOres_Map'

-- the rule scene's ore field and the cleared ground beside it, in tiles
Public.ore_area = {left_top = {x = -32, y = -14}, right_bottom = {x = 14, y = 14}}
Public.cleared_area = {left_top = {x = 14, y = -14}, right_bottom = {x = 44, y = 14}}

-- What the rule scene builds on the ore, one of each kind the map allows. Each is placed and kept
-- only if Danger Ores' building restriction lets it stay on ore.
Public.on_ore = {
    {name = 'electric-mining-drill', position = {-21.5, -2.5}, direction = defines.direction.south},
    {name = 'electric-mining-drill', position = {-17.5, -2.5}, direction = defines.direction.south},
    {name = 'electric-mining-drill', position = {-13.5, -2.5}, direction = defines.direction.south},
    {name = 'small-electric-pole', position = {-19.5, -5.5}},
    {name = 'small-electric-pole', position = {-15.5, -5.5}},
    {name = 'pipe', position = {-24.5, -8.5}},
    {name = 'pipe', position = {-23.5, -8.5}},
    {name = 'pipe', position = {-22.5, -8.5}},
    {name = 'pipe', position = {-21.5, -8.5}},
    {name = 'pipe', position = {-20.5, -8.5}},
    {name = 'straight-rail', position = {-23, 5}, direction = defines.direction.east},
    {name = 'straight-rail', position = {-21, 5}, direction = defines.direction.east},
    {name = 'straight-rail', position = {-19, 5}, direction = defines.direction.east},
    {name = 'straight-rail', position = {-17, 5}, direction = defines.direction.east},
    {name = 'straight-rail', position = {-15, 5}, direction = defines.direction.east},
    {name = 'straight-rail', position = {-13, 5}, direction = defines.direction.east},
    {name = 'car', position = {-8, -2}},
}
-- the belt the drills put their ore on, running east off the ore past the furnaces
for x = -24, 27 do
    Public.on_ore[#Public.on_ore + 1] = {name = 'transport-belt', position = {x + 0.5, -0.5}, direction = defines.direction.east}
end

-- What the rule scene shows refused on the ore: drawn, not built, since it couldn't stay there.
local refused = {sprite = 'item/assembling-machine-2', position = {4.5, -2.5}}

-- A working line on the cleared ground, fed by the drills' belt: inserters put the ore in
-- furnaces, the plates go by belt to assemblers, and what's left at the end of each belt and what
-- the assemblers make goes into infinity chests that delete it, so the line never backs up on a
-- server that runs for days. Power comes from an electric energy interface, through substations.
local north, east, south = defines.direction.north, defines.direction.east, defines.direction.south
Public.on_cleared_ground = {
    {name = 'electric-furnace', position = {17.5, 2.5}},
    {name = 'electric-furnace', position = {21.5, 2.5}},
    {name = 'electric-furnace', position = {25.5, 2.5}},
    {name = 'inserter', position = {17.5, 0.5}, drop = south},
    {name = 'inserter', position = {21.5, 0.5}, drop = south},
    {name = 'inserter', position = {25.5, 0.5}, drop = south},
    {name = 'inserter', position = {17.5, 4.5}, drop = south},
    {name = 'inserter', position = {21.5, 4.5}, drop = south},
    {name = 'inserter', position = {25.5, 4.5}, drop = south},
    {name = 'inserter', position = {28.5, -0.5}, drop = east},
    {name = 'infinity-chest', position = {29.5, -0.5}, sink = true},
    {name = 'assembling-machine-2', position = {31.5, 8.5}, assembler = true},
    {name = 'assembling-machine-2', position = {35.5, 8.5}, assembler = true},
    {name = 'assembling-machine-2', position = {39.5, 8.5}, assembler = true},
    {name = 'inserter', position = {31.5, 6.5}, drop = south},
    {name = 'inserter', position = {35.5, 6.5}, drop = south},
    {name = 'inserter', position = {39.5, 6.5}, drop = south},
    {name = 'inserter', position = {31.5, 10.5}, drop = south},
    {name = 'inserter', position = {35.5, 10.5}, drop = south},
    {name = 'inserter', position = {39.5, 10.5}, drop = south},
    {name = 'infinity-chest', position = {31.5, 11.5}, sink = true},
    {name = 'infinity-chest', position = {35.5, 11.5}, sink = true},
    {name = 'infinity-chest', position = {39.5, 11.5}, sink = true},
    {name = 'inserter', position = {42.5, 5.5}, drop = east},
    {name = 'infinity-chest', position = {43.5, 5.5}, sink = true},
    {name = 'substation', position = {19, -7}},
    {name = 'substation', position = {21, 7}},
    {name = 'substation', position = {36, 3}},
    -- out of the cameras' view, in reach of the first substation on the cleared ground
    {name = 'electric-energy-interface', position = {15, -13}, power = true},
}
-- the plates' belt, from the furnaces past the assemblers
for x = 16, 41 do
    Public.on_cleared_ground[#Public.on_cleared_ground + 1] = {name = 'transport-belt', position = {x + 0.5, 5.5}, direction = east}
end
-- the substations that carry the power to the drills, on the ore like any pole
Public.on_ore[#Public.on_ore + 1] = {name = 'substation', position = {-17, -7}}
Public.on_ore[#Public.on_ore + 1] = {name = 'substation', position = {1, -7}}

-- what the furnaces make of each ore, and the assemblers of that
local products = {
    ['iron-ore'] = {plate = 'iron-plate', product = 'iron-gear-wheel'},
    ['copper-ore'] = {plate = 'copper-plate', product = 'copper-cable'},
    ['stone'] = {plate = 'stone-brick', product = 'stone-wall'},
}

local data = {
    -- where to put a player back after the rule scene, by player index
    return_to = {},
    -- what the cards say: the map's name and twist, how many satellites win it, and whether
    -- there's a poll for the next map
    card = {},
}

Global.register(data, function(tbl)
    data = tbl
end)

local function valid(entity)
    return entity and entity.valid
end

-- A map poll display name is '<Name> (<twist>)': the name for the title, the twist for a line
-- under it. Without a twist in brackets, the whole name is the title.
function Public.split_display_name(display_name)
    local name, twist = display_name:match('^(.-)%s*%((.*)%)%s*$')
    if not name then
        return display_name, nil
    end
    return name, twist
end

local function capitalize(text)
    return text:sub(1, 1):upper() .. text:sub(2)
end

--- The title card's lines under 'Danger Ores': the map's name, its twist and who made it.
---@param card table {name, twist}
function Public.welcome_lines(card)
    local lines = {{'danger_ores.cutscene_welcome', card.name or 'Danger Ores'}}
    if card.twist then
        -- the poll's twists start in lower case, as they follow the name in brackets there
        lines[#lines + 1] = capitalize(card.twist)
    end
    lines[#lines + 1] = '---------------------'
    lines[#lines + 1] = {'danger_ores.cutscene_redmew', 'Redmew'}
    lines[#lines + 1] = {'danger_ores.cutscene_discord', 'redmew.com/discord'}
    return lines
end

--- The last card: its title and the lines under it. The goal is there only when the map is won by
--- launching satellites (some presets have their own goal), and the poll only when there is one.
---@param card table {win_satellite_count, poll}
function Public.goal_card(card)
    local lines = {}
    local title
    if card.win_satellite_count then
        title = {'danger_ores.cutscene_goal_title'}
        lines[#lines + 1] = {'danger_ores.cutscene_goal', card.win_satellite_count}
        lines[#lines + 1] = {'danger_ores.cutscene_biters'}
        lines[#lines + 1] = '---------------------'
    else
        title = {'danger_ores.cutscene_good_luck'}
    end
    if card.poll then
        lines[#lines + 1] = {'danger_ores.cutscene_poll'}
    end
    if card.win_satellite_count then
        lines[#lines + 1] = {'danger_ores.cutscene_good_luck'}
    end
    return title, lines
end

function Public.get_card()
    return data.card
end

local function main_ore(main_ores)
    local first
    for _, ore in pairs(main_ores or {}) do
        if ore.name and prototypes.entity[ore.name] then
            if ore.name == 'iron-ore' then
                return ore
            end
            first = first or ore
        end
    end
    return first
end

local function fill_area(surface, area, tiles, resource_name)
    local tile_list = {}
    local left_top, right_bottom = area.left_top, area.right_bottom
    for x = left_top.x, right_bottom.x - 1 do
        for y = left_top.y, right_bottom.y - 1 do
            local tile = tiles[(x * 7 + y * 13) % #tiles + 1]
            tile_list[#tile_list + 1] = {name = tile, position = {x, y}}
        end
    end
    surface.set_tiles(tile_list)

    if not resource_name then
        return
    end
    for x = left_top.x, right_bottom.x - 1 do
        for y = left_top.y, right_bottom.y - 1 do
            -- enough for the drills to run for weeks
            surface.create_entity {name = resource_name, position = {x + 0.5, y + 0.5}, amount = 1000000}
        end
    end
end

-- An inserter that drops on the side `drop` (a direction): which way an inserter faces relative
-- to where it drops is the game's business, so this tries each and keeps the one that fits.
local function create_inserter(surface, spec, force)
    local vector = ({[north] = {0, -1}, [east] = {1, 0}, [south] = {0, 1}, [defines.direction.west] = {-1, 0}})[spec.drop]
    for _, direction in pairs {north, east, south, defines.direction.west} do
        local entity = surface.create_entity {name = spec.name, position = spec.position, direction = direction, force = force}
        if entity then
            local drop, position = entity.drop_position, entity.position
            if (drop.x - position.x) * vector[1] + (drop.y - position.y) * vector[2] > 0.5 then
                return entity
            end
            entity.destroy()
        end
    end
end

-- `line`: the ore and what's made of it, to start the furnaces and assemblers with
local function build(surface, list, force, keep, line)
    local built = {}
    for _, spec in pairs(list) do
        if prototypes.entity[spec.name] then
            local entity
            if spec.drop then
                entity = create_inserter(surface, spec, force)
            else
                entity = surface.create_entity {name = spec.name, position = spec.position, direction = spec.direction, force = force}
            end
            if entity then
                if keep(entity) then
                    entity.minable_flag = false
                    entity.destructible = false
                    if spec.sink then
                        entity.remove_unfiltered_items = true
                    elseif spec.power then
                        entity.electric_buffer_size = 100000000
                        entity.power_production = 1000000
                    elseif spec.assembler and line and force.recipes[line.product] then
                        force.recipes[line.product].enabled = true
                        entity.set_recipe(line.product)
                        entity.insert {name = line.plate, count = 100}
                    elseif entity.type == 'furnace' and line then
                        entity.insert {name = line.ore, count = 50}
                    end
                    if entity.type == 'car' then
                        -- parked, with no fuel to warn about
                        entity.disabled_by_script = true
                    end
                    built[#built + 1] = entity
                else
                    entity.destroy()
                end
            end
        end
    end
    return built
end

local function always()
    return true
end

--- Builds the rule scene on a surface: an ore field of the map's main ore with the allowed
--- buildings on it, and cleared ground with a small factory. Returns what it built on the ore.
---@param surface LuaSurface
---@param main_ores table the preset's map_config.main_ores
function Public.build_stage(surface, main_ores)
    local ore = main_ore(main_ores)
    local resource_name = ore and ore.name
    local tiles = ore and ore.tiles
    if not tiles or #tiles == 0 or type(tiles[1]) ~= 'string' then
        tiles = {'grass-1'}
    end

    fill_area(surface, Public.ore_area, tiles, resource_name)
    fill_area(surface, Public.cleared_area, tiles, nil)

    local force = game.forces[Public.force_name] or game.create_force(Public.force_name)
    local on_ore = build(surface, Public.on_ore, force, AllowedEntities.is_allowed)
    local line = resource_name and products[resource_name]
    if line then
        line = {ore = resource_name, plate = line.plate, product = line.product}
    end
    build(surface, Public.on_cleared_ground, force, always, line)
    return on_ore
end

local function create_stage(main_ores)
    local surface = game.create_surface(Public.surface_name, {
        width = 2 * 64,
        height = 2 * 32,
        default_enable_all_autoplace_controls = false,
        autoplace_settings = {
            entity = {treat_missing_as_default = false, settings = {}},
            decorative = {treat_missing_as_default = false, settings = {}},
            tile = {treat_missing_as_default = false, settings = {['grass-1'] = {}}},
        },
        peaceful_mode = true,
    })
    surface.always_day = true
    surface.request_to_generate_chunks({0, 0}, 2)
    surface.force_generate_chunk_requests()
    Public.build_stage(surface, main_ores)
    -- after the stage, which makes its own force
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, true)
    end
end

Public.products = products
Public.main_ore = main_ore

-- Text sizes and positions are set for this screen and zoom, and scaled to the player's.
local original_resolution = {height = 1440, width = 2560}
local original_zoom = 1

local function text_settings(zoom)
    return {original_resolution = original_resolution, original_zoom = original_zoom, player_zoom = zoom}
end

-- A caption along the bottom of the screen for the whole waypoint.
local function caption(player, params, text, surface)
    local tick, zoom = params.tick, params.zoom
    register_rendering(player.index, tick, draw_text(text_settings(zoom), {x = 0, y = 18}, text, player, {scale = 2.5, time_to_live = params.time_to_wait, surface = surface}, true, false))
end

local function blackout(player, params, surface)
    local settings = {original_resolution = original_resolution, original_zoom = 1, player_zoom = params.zoom}
    local left_top = {x = -40, y = -22.5}
    local right_bottom = {x = 40, y = 22.5}
    register_rendering(player.index, params.tick, CS_Rendering.draw_rectangle(settings, {x = 0, y = 0}, left_top, right_bottom, player, {time_to_live = params.time_to_wait + 10, surface = surface}))
end

local function welcome_function(player_index, waypoint_index, params)
    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end
    local tick, zoom, ttw = params.tick, params.zoom, params.time_to_wait
    local settings = text_settings(zoom)
    player.game_view_settings.show_entity_info = true
    if waypoint_index ~= -1 then
        play_sound(tick, player, 'utility/list_box_click', 1)
    end

    if waypoint_index == -1 then
        blackout(player, params)
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -12}, 'Danger Ores', player, {scale = 10, time_to_live = ttw, color = Color.red}, false, false))
        register_rendering(player_index, tick, draw_multi_line(settings, {x = 0, y = -5}, Public.welcome_lines(data.card), player, {scale = 4.5, time_to_live = ttw}, false))
    elseif waypoint_index == 0 then
        caption(player, params, {'danger_ores.cutscene_spawn'})
    end
end

local welcome_waypoints = {
    {position = {x = 0, y = 0}, transition_time = 60, time_to_wait = 420, zoom = 0.5}, -- title card
    -- far enough out to see where spawn ends and the ore begins
    {position = {x = 0, y = 0}, transition_time = 180, time_to_wait = 420, zoom = 0.35}, -- spawn
}

local function rule_function(player_index, waypoint_index, params)
    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end
    local tick, ttw = params.tick, params.time_to_wait
    local surface = Public.surface_name
    player.game_view_settings.show_entity_info = true
    if waypoint_index ~= -1 then
        play_sound(tick, player, 'utility/list_box_click', 1)
    end

    if waypoint_index == -1 then
        caption(player, params, {'danger_ores.cutscene_buried'}, surface)
    elseif waypoint_index == 0 then
        caption(player, params, {'danger_ores.cutscene_rule'}, surface)
    elseif waypoint_index == 1 then
        caption(player, params, {'danger_ores.cutscene_allowed'}, surface)
    elseif waypoint_index == 2 then
        local x, y = refused.position[1], refused.position[2]
        local function draw(object)
            register_rendering(player_index, tick, object)
        end
        draw(rendering.draw_sprite {sprite = refused.sprite, target = refused.position, surface = surface, players = {player}, x_scale = 3, y_scale = 3, time_to_live = ttw})
        draw(rendering.draw_line {from = {x - 1.6, y - 1.6}, to = {x + 1.6, y + 1.6}, color = Color.red, width = 8, surface = surface, players = {player}, time_to_live = ttw})
        draw(rendering.draw_line {from = {x - 1.6, y + 1.6}, to = {x + 1.6, y - 1.6}, color = Color.red, width = 8, surface = surface, players = {player}, time_to_live = ttw})
        caption(player, params, {'danger_ores.cutscene_refused'}, surface)
    elseif waypoint_index == 3 then
        caption(player, params, {'danger_ores.cutscene_cleared'}, surface)
    end
end

local rule_waypoints = {
    {position = {x = -6, y = 0}, transition_time = 60, time_to_wait = 360, zoom = 0.7}, -- the ore field
    {position = {x = -6, y = 0}, transition_time = 30, time_to_wait = 420, zoom = 0.7}, -- the rule
    {position = {x = -17, y = -1}, transition_time = 120, time_to_wait = 480, zoom = 1.4}, -- what may stay on ore
    {position = {x = 4, y = -2}, transition_time = 120, time_to_wait = 420, zoom = 1.6}, -- what may not
    {position = {x = 30, y = 3}, transition_time = 150, time_to_wait = 480, zoom = 1.2}, -- cleared ground
}

local function map_function(player_index, waypoint_index, params)
    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end
    local tick, zoom, ttw = params.tick, params.zoom, params.time_to_wait
    local settings = text_settings(zoom)
    play_sound(tick, player, 'utility/list_box_click', 1)

    if waypoint_index == -1 then
        local title, lines = Public.goal_card(data.card)
        blackout(player, params)
        register_rendering(player_index, tick, draw_text(settings, {x = 0, y = -12}, title, player, {scale = 8, time_to_live = ttw, color = Color.red}, false, false))
        register_rendering(player_index, tick, draw_multi_line(settings, {x = 0, y = -5}, lines, player, {scale = 4, time_to_live = ttw}, false))
    end
end

local map_waypoints = {
    {position = {x = 0, y = 0}, transition_time = 60, time_to_wait = 600, zoom = 0.5}, -- the goal
}

local function show_start_up(player)
    PC.show_start_up(player)
    player.print({'danger_ores.replay_cutscene', '/replay'}, {color = Color.yellow})
end

local start_rule =
    Token.register(
    function(player_index)
        local player = game.get_player(player_index)
        if not valid(player) or not game.get_surface(Public.surface_name) then
            return
        end
        data.return_to[player_index] = {surface = player.surface.name, position = player.position}
        local position = game.get_surface(Public.surface_name).find_non_colliding_position('character', {x = 0, y = 16}, 0, 1)
        player.teleport(position, Public.surface_name)
        Cutscene.register_running_cutscene(player_index, rule_name, 60)
    end
)

local function welcome_terminate(player_index, skip_btn_flag)
    if skip_btn_flag then
        local player = game.get_player(player_index)
        if valid(player) then
            show_start_up(player)
        end
        return
    end
    Task.set_timeout_in_ticks(1, start_rule, player_index)
end

local start_map =
    Token.register(
    function(player_index)
        Cutscene.register_running_cutscene(player_index, map_name, 120)
    end
)

local function rule_terminate(player_index, skip_btn_flag)
    local player = game.get_player(player_index)
    if not valid(player) then
        return
    end
    local back = data.return_to[player_index]
    data.return_to[player_index] = nil
    local surface = back and game.get_surface(back.surface) or RS.get_surface()
    local position = surface.find_non_colliding_position('character', back and back.position or {x = 0, y = 0}, 0, 1)
    player.teleport(position, surface)
    if skip_btn_flag then
        show_start_up(player)
        return
    end
    Task.set_timeout_in_ticks(1, start_map, player_index)
end

local function map_terminate(player_index)
    local player = game.get_player(player_index)
    if valid(player) then
        show_start_up(player)
    end
end

Cutscene.register_cutscene_function(welcome_name, welcome_waypoints, Token.register(welcome_function), Token.register(welcome_terminate))
Cutscene.register_cutscene_function(rule_name, rule_waypoints, Token.register(rule_function), Token.register(rule_terminate))
Cutscene.register_cutscene_function(map_name, map_waypoints, Token.register(map_function), Token.register(map_terminate))

-- Player creation leaves the start-up messages and map info to the cutscene's end, so a player
-- who doesn't auto play it gets them straight away instead.
function Public.start_for_new_player(player_index)
    if Settings.get(player_index, Public.auto_play_setting_name) then
        Cutscene.register_running_cutscene(player_index, welcome_name, 120)
        return
    end

    local player = game.get_player(player_index)
    if valid(player) then
        show_start_up(player)
    end
end

local start_for_new_player =
    Token.register(
    function(player_index)
        Public.start_for_new_player(player_index)
    end
)

--- Turns the cutscene on: new players see it, and /replay plays it again.
---@param config table the Danger Ores configuration
---@param card table {name, twist}: the map's name and twist for the title card
function Public.register(config, card)
    Settings.register(Public.auto_play_setting_name, Settings.types.boolean, true, Public.auto_play_setting_name)
    Cutscene.set_auto_play_cutscene_setting_name(Public.auto_play_setting_name)
    Cutscene.register_replay(welcome_name, 120)

    local main_ores = config.map_config.main_ores
    local win_satellite_count = config.rocket_launched.enabled and config.rocket_launched.win_satellite_count or nil
    local poll = config.map_poll.enabled

    Event.on_init(function()
        storage.config.player_create.cutscene = true
        data.card = {name = card.name, twist = card.twist, win_satellite_count = win_satellite_count, poll = poll}
        create_stage(main_ores)
    end)

    Event.add(defines.events.on_player_created, function(event)
        Task.set_timeout_in_ticks(60, start_for_new_player, event.player_index)
    end)
end

return Public
