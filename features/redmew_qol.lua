-- Assorted quality of life improvements that are restricted in scope. Similar to redmew_commands but event-based rather than command-based.
-- Dependencies
local Token = require 'utils.token'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local Global = require 'utils.global'
local table = require 'utils.table'
local Task = require 'utils.task'
local Rank = require 'features.rank_system'
local Gui = require 'utils.gui'

local config = global.config.redmew_qol

-- Localized functions
local random = math.random

-- Local vars
local Public = {}

-- Global registers
local enabled = {random_train_color = nil, restrict_chest = nil, change_backer_name = nil, set_alt_on_create = nil}

Global.register({enabled = enabled}, function(tbl)
    enabled = tbl.enabled
end)

-- Local functions

--- When placed, locomotives will get a random color
local random_train_color = Token.register(function(event)
    local entity = event.created_entity
    if entity and entity.valid and entity.name == 'locomotive' then
        entity.color = Utils.random_RGB()
    end
end)

--- If a newly placed entity is a provider or non-logi chest, set it to only have 1 slot available.
-- If placed from a bp and the bp has restrictions on the chest, it takes priority.
local restrict_chest = Token.register(function(event)
    local entity = event.created_entity
    if entity and entity.valid and (entity.name == 'logistic-chest-passive-provider' or entity.type == 'container') then
        local chest_inventory = entity.get_inventory(defines.inventory.chest)
        if #chest_inventory + 1 == chest_inventory.getbar() then
            chest_inventory.setbar(2)
        end
    end
end)

--- Selects a name from the entity backer name, game.players, and regulars
local function pick_name()
    -- Create a weight table comprised of the backer name, a player's name, and a regular's name
    local random_player = game.players[random(#game.players)]
    if not random_player then
        return
    end

    local regulars = Rank.get_player_table()
    local reg
    if table.size(regulars) == 0 then
        reg = nil
    else
        reg = {table.get_random_dictionary_entry(regulars, true), 1}
    end
    local name_table = {{false, 8}, {random_player.name, 1}, reg}
    return table.get_random_weighted(name_table)
end

--- Changes the backer name on an entity that supports having a backer name.
local change_backer_name = Token.register(function(event)
    local entity = event.created_entity
    if entity and entity.valid and entity.backer_name then
        entity.backer_name = pick_name() or entity.backer_name
    end
end)

--- Changes the backer name on an entity that supports having a backer name.
local set_alt_on_create = Token.register(function(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    player.game_view_settings.show_entity_info = true
end)

local loaders_technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

--- After init, checks if any of the loader techs have been researched
-- and enables loaders if appropriate.
local loader_check_token = Token.register(function()
    for _, force in pairs(game.forces) do
        for key, recipe in pairs(loaders_technology_map) do
            if force.technologies[key].researched then
                force.recipes[recipe].enabled = true
            end
        end
    end
end)

--- Sets construction robots that are not part of a roboport to unminabe
-- if the player selecting them are not the owner of them.
local function preserve_bot(event)
    local player = game.get_player(event.player_index)
    local entity = player.selected

    if entity == nil or not entity.valid then
        return
    end

    if entity.name ~= 'construction-robot' then
        return
    end
    local logistic_network = entity.logistic_network

    if logistic_network == nil or not logistic_network.valid then
        -- prevents an orphan bot from being unremovable
        entity.minable = true
        return
    end

    -- All valid logistic networks should have at least one cell
    local cell = logistic_network.cells[1]
    local owner = cell.owner

    -- checks if construction-robot is part of a mobile logistic network
    if owner.name ~= 'character' then
        entity.minable = true
        return
    end

    -- checks if construction-robot is owned by the player that has selected it
    if owner.player.name == player.name then
        entity.minable = true
        return
    end

    entity.minable = false
end

-- Event registers

local function register_random_train_color()
    if enabled.random_train_color then
        return false -- already registered
    end
    enabled.random_train_color = true
    Event.add_removable(defines.events.on_built_entity, random_train_color)
    return true
end

local function register_restrict_chest()
    if enabled.restrict_chest then
        return false -- already registered
    end
    enabled.restrict_chest = true
    Event.add_removable(defines.events.on_built_entity, restrict_chest)
    Event.add_removable(defines.events.on_robot_built_entity, restrict_chest)
    return true
end

local function register_change_backer_name()
    if enabled.change_backer_name then
        return false -- already registered
    end
    enabled.change_backer_name = true
    Event.add_removable(defines.events.on_built_entity, change_backer_name)
    Event.add_removable(defines.events.on_robot_built_entity, change_backer_name)
    return true
end

local function register_set_alt_on_create()
    if enabled.set_alt_on_create then
        return false -- already registered
    end
    enabled.set_alt_on_create = true
    Event.add_removable(defines.events.on_player_created, set_alt_on_create)
    return true
end

local function on_init()
    -- Set player force's ghost_time_to_live to an hour. Giving the players ghosts before the research of robots is a nice QOL improvement.
    if config.ghosts_before_research then
        Public.set_ghost_ttl()
    end
    if config.loaders then
        Task.set_timeout_in_ticks(1, loader_check_token, nil)
    end
end

Event.on_init(on_init)

-- Public functions

--- Sets a ghost_time_to_live as a quality of life feature: now ghosts
-- are created on death of entities before robot research
-- @param force_name string with name of force
-- @param time number of ticks for ghosts to live
function Public.set_ghost_ttl(force_name, time)
    force_name = force_name or 'player'
    time = time or (30 * 60 * 60)
    game.forces[force_name].ghost_time_to_live = time
end

--- Sets random_train_color on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_random_train_color(enable)
    if enable then
        return register_random_train_color()
    end
    Event.remove_removable(defines.events.on_built_entity, random_train_color)
    enabled.random_train_color = false
    return true
end

--- Return status of restrict_chest
function Public.get_random_train_color()
    return enabled.random_train_color or false
end

--- Sets restrict_chest on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_restrict_chest(enable)
    if enable then
        return register_restrict_chest()
    else
        Event.remove_removable(defines.events.on_built_entity, restrict_chest)
        Event.remove_removable(defines.events.on_robot_built_entity, restrict_chest)
        enabled.restrict_chest = false
        return true
    end
end

--- Return status of restrict_chest
function Public.get_restrict_chest()
    return enabled.restrict_chest or false
end

--- Sets backer_name on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_backer_name(enable)
    if enable then
        return register_change_backer_name()
    else
        Event.remove_removable(defines.events.on_built_entity, change_backer_name)
        Event.remove_removable(defines.events.on_robot_built_entity, change_backer_name)
        enabled.change_backer_name = false
        return true
    end
end

--- Return status of backer_name
function Public.get_backer_name()
    return enabled.change_backer_name or false
end

--- Sets set_alt_on_create on or off.
-- @param enable <boolean> true to toggle on, false for off
-- @return <boolean> Success/failure of command
function Public.set_set_alt_on_create(enable)
    if enable then
        return register_set_alt_on_create()
    else
        Event.remove_removable(defines.events.on_player_created, set_alt_on_create)
        enabled.set_alt_on_create = false
        return true
    end
end

--- Return status of set_alt_on_create
function Public.set_alt_on_create()
    return enabled.set_alt_on_create or false
end

-- Initial event setup

if config.random_train_color then
    register_random_train_color()
end
if config.restrict_chest then
    register_restrict_chest()
end
if config.backer_name then
    register_change_backer_name()
end
if config.set_alt_on_create then
    register_set_alt_on_create()
end

if config.save_bots then
    Event.add(defines.events.on_selected_entity_changed, preserve_bot)
end

if config.research_queue then
    Event.on_init(function()
        game.forces.player.research_queue_enabled = true
    end)
end

local loader_crafter_frame_for_player_name = Gui.uid_name()
local loader_crafter_frame_for_assembly_machine_name = Gui.uid_name()
local player_craft_loader_1 = Gui.uid_name()
local player_craft_loader_2 = Gui.uid_name()
local player_craft_loader_3 = Gui.uid_name()
local machine_craft_loader_1 = Gui.uid_name()
local machine_craft_loader_2 = Gui.uid_name()
local machine_craft_loader_3 = Gui.uid_name()

local open_gui_token = Token.register(function(data)
    local player = data.player
    local entity = data.entity
    player.opened = entity
end)

local close_gui_token = Token.register(function(data)
    local player = data.player
    player.opened = nil
end)

local function any_loader_enabled(recipes)
    return recipes['loader'].enabled or recipes['fast-loader'].enabled or recipes['express-loader'].enabled
end

local function draw_loader_frame_for_player(parent, player)
    local frame = parent[loader_crafter_frame_for_player_name]

    local recipes = player.force.recipes
    if not any_loader_enabled(recipes) then
        if frame and frame.valid then
            Gui.destroy(frame)
        end
        return
    end

    if frame and frame.valid then
        Gui.clear(frame)
    else
        local anchor = {gui = defines.relative_gui_type.controller_gui, position = defines.relative_gui_position.right}
        frame = parent.add {
            type = 'frame',
            name = loader_crafter_frame_for_player_name,
            anchor = anchor,
            direction = 'vertical'
        }
    end

    if recipes['loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = player_craft_loader_1,
            elem_type = 'recipe',
            recipe = 'loader'
        }
        button.locked = true
    end

    if recipes['fast-loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = player_craft_loader_2,
            elem_type = 'recipe',
            recipe = 'fast-loader'
        }
        button.locked = true
    end

    if recipes['express-loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = player_craft_loader_3,
            elem_type = 'recipe',
            recipe = 'express-loader'
        }
        button.locked = true
    end
end

local function draw_loader_frame_for_assembly_machine(parent, entity, player)
    local frame = parent[loader_crafter_frame_for_assembly_machine_name]

    local recipes = player.force.recipes
    if not any_loader_enabled(recipes) then
        if frame and frame.valid then
            Gui.destroy(frame)
        end
        return
    end

    if frame and frame.valid then
        Gui.clear(frame)
    else
        local anchor = {
            gui = defines.relative_gui_type.assembling_machine_select_recipe_gui,
            position = defines.relative_gui_position.right
        }
        frame = parent.add {
            type = 'frame',
            name = loader_crafter_frame_for_assembly_machine_name,
            anchor = anchor,
            direction = 'vertical'
        }
    end

    if recipes['loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = machine_craft_loader_1,
            elem_type = 'recipe',
            recipe = 'loader'
        }
        button.locked = true
        Gui.set_data(button, entity)
    end

    if recipes['fast-loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = machine_craft_loader_2,
            elem_type = 'recipe',
            recipe = 'fast-loader'
        }
        button.locked = true
        Gui.set_data(button, entity)
    end

    if recipes['express-loader'].enabled then
        local button = frame.add {
            type = 'choose-elem-button',
            name = machine_craft_loader_3,
            elem_type = 'recipe',
            recipe = 'express-loader'
        }
        button.locked = true
        Gui.set_data(button, entity)
    end
end

local function player_craft_loaders(event, loader_name)
    local player = event.player
    if not player.force.recipes[loader_name].enabled then
        return
    end

    local button = event.button -- int
    local shift = event.shift -- bool

    local count
    if button == defines.mouse_button_type.left then
        if shift then
            count = 4294967295 -- uint highest value. Factorio crafts as many as able
        else
            count = 1
        end
    elseif button == defines.mouse_button_type.right then
        count = 5
    else
        return
    end
    player.begin_crafting {count = count, recipe = loader_name}
end

Gui.on_click(player_craft_loader_1, function(event)
    player_craft_loaders(event, "loader")
end)

Gui.on_click(player_craft_loader_2, function(event)
    player_craft_loaders(event, "fast-loader")
end)

Gui.on_click(player_craft_loader_3, function(event)
    player_craft_loaders(event, "express-loader")
end)

local function set_assembly_machine_recipe(event, loader_name)
    if not event.player.force.recipes[loader_name].enabled then
        return
    end

    local entity = Gui.get_data(event.element)
    entity.set_recipe(loader_name)
    Task.set_timeout_in_ticks(1, close_gui_token, {player = event.player})
    Task.set_timeout_in_ticks(2, open_gui_token, {player = event.player, entity = entity})
end

Gui.on_click(machine_craft_loader_1, function(event)
    set_assembly_machine_recipe(event, 'loader')
end)

Gui.on_click(machine_craft_loader_2, function(event)
    set_assembly_machine_recipe(event, 'fast-loader')
end)

Gui.on_click(machine_craft_loader_3, function(event)
    set_assembly_machine_recipe(event, 'express-loader')
end)

if config.loaders then
    Event.add(defines.events.on_research_finished, function(event)
        local research = event.research
        local recipe = loaders_technology_map[research.name]
        if not recipe then
            return
        end

        research.force.recipes[recipe].enabled = true
        for _, player in pairs(game.players) do
            if player.opened_gui_type == defines.gui_type.controller then
                local panel = player.gui.relative
                draw_loader_frame_for_player(panel, player)
            end
        end
    end)

    Event.add(defines.events.on_gui_opened, function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local panel = player.gui.relative
        local entity = event.entity
        if entity and entity.valid and entity.type == 'assembling-machine' then
            draw_loader_frame_for_assembly_machine(panel, entity, player)
        elseif event.gui_type == defines.gui_type.controller then
            draw_loader_frame_for_player(panel, player)
        end
    end)

    Event.add(defines.events.on_gui_closed, function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local relative = player.gui.relative
        local panel = relative[loader_crafter_frame_for_assembly_machine_name]
        if panel and panel.valid then
            Gui.remove_data_recursively(panel)
        end
    end)

    local direction_to_offset = {
        [0] = {x = 0, y = 1.5},
        [2] = {x = -1.5, y = 0},
        [4] = {x = 0, y = -1.5},
        [6] = {x = 1.5, y = 0}
    }

    local loaders = {['loader'] = true, ['fast-loader'] = true, ['express-loader'] = true}

    local container_types = {'container', 'logistic-container'}

    Event.add(defines.events.on_player_rotated_entity, function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name
        if not loaders[entity.name] then
            return
        end

        if entity.loader_container then
            -- loader is already connected.
            return
        end

        local direction = entity.direction
        local offset = direction_to_offset[direction]

        local pos = entity.position
        local target_pos = {pos.x + offset.x, pos.y + offset.y}

        local surface = entity.surface
        local target = surface.find_entities_filtered({position = target_pos, type = container_types})[1]
        if not target then
            return
        end

        local force = entity.force

        local get_filter = entity.get_filter
        local filters = {}
        local filter_count = entity.filter_slot_count
        for i = 1, filter_count do
            filters[i] = get_filter(i)
        end

        entity.destroy({raise_destroy = true})
        local new_entity = surface.create_entity {
            name = name,
            position = pos,
            direction = direction,
            type = 'output',
            force = force
        }

        local set_filter = new_entity.set_filter
        for i = 1, filter_count do
            set_filter(i, filters[i])
        end

        script.raise_script_built({entity = new_entity})
    end)
end

return Public
