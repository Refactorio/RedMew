local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Rank = require 'features.rank_system'
local table = require 'utils.table'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Utils = require 'utils.core'

local config = require 'config'.redmew_qol
local random = math.random
local Public = {}
local enabled = {}

Global.register({ enabled = enabled }, function(tbl)
    enabled = tbl.enabled
end)

-- == Helpers =================================================================

local function safe_get_player(player_index)
    local p = game.get_player(player_index)
    return p and p.valid and p or nil
end

local function pick_name()
    local p = game.get_player(random(#game.players))
    if not p then
        return
    end
    local regs = Rank.get_player_table()
    local reg = table.size(regs) > 0 and { table.get_random_dictionary_entry(regs, true), 1 } or nil
    return table.get_random_weighted({ { false, 8 }, { p.name, 1 }, reg })
end

local loader_frame_name = Gui.uid_name()
local loader_machine_frame_name = Gui.uid_name()
local loader_button_player = Gui.uid_name()
local loader_button_machine = Gui.uid_name()

-- Exposed for tests
Public._loader_frame_name = loader_frame_name
Public._loader_machine_frame_name = loader_machine_frame_name

local loaders = {
    ['loader'] = true,
    ['fast-loader'] = true,
    ['express-loader'] = true,
    ['turbo-loader'] = true,
}

local container_types = {
    'assembling-machine',
    'beacon',
    'boiler',
    'burner-generator',
    'container',
    'curved-rail',
    'furnace',
    'infinity-container',
    'lab',
    'linked-container',
    'logistic-container',
    'mining-drill',
    'proxy-container',
    'rail',
    'reactor',
    'rocket-silo',
    'straight-rail',
}

local loaders_technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader',
    ['turbo-transport-belt'] = 'turbo-loader',
}

local loader_offsets = {
    [defines.direction.north] = { x =  0.0, y = -1.5 },
    [defines.direction.east]  = { x =  1.5, y =  0.0 },
    [defines.direction.south] = { x =  0.0, y =  1.5 },
    [defines.direction.west]  = { x = -1.5, y =  0.0 },
}

local function any_loader_enabled(recipes)
    if prototypes.entity['redmew-loader'] then
        return false
    end
    for name in pairs(loaders) do
        local recipe = recipes[name]
        if recipe and recipe.enabled then
            return true
        end
    end
    return false
end

local function draw_loader_frame(parent, entity)
    local frame_name = entity and loader_machine_frame_name or loader_frame_name
    local frame = parent[frame_name]
    local player = entity or safe_get_player(parent.player_index)
    local recipes = player and player.force.recipes
    if not recipes or not any_loader_enabled(recipes) then
        if frame and frame.valid then
            Gui.destroy(frame)
        end
        return
    end

    if frame and frame.valid then
        Gui.clear(frame)
    else
        frame = parent.add {
            type = 'frame',
            name = frame_name,
            anchor = {
                gui = defines.relative_gui_type[entity and 'assembling_machine_select_recipe_gui' or 'controller_gui'],
                position = defines.relative_gui_position.right
            },
            direction = 'vertical',
        }
    end

    local container = frame
        .add { type = 'frame', style = 'inside_deep_frame' }
        .add { type = 'table', column_count = 1, style = 'filter_slot_table' }
    for recipe in pairs(loaders) do
        if recipes[recipe] and recipes[recipe].enabled then
            local button = container.add({type = 'flow'}).add {
                type = 'choose-elem-button',
                name = entity and loader_button_machine or loader_button_player,
                elem_type = 'recipe',
                recipe = recipe,
            }
            button.locked = true
            if entity then
                Gui.set_data(button, entity)
            end
        end
    end
end

local function opposite_direction(direction)
    return (direction + 8) % 16
end

-- Merge entities and ghost entities
local function find_entities(surface, position, force, types)
    local entities = surface.find_entities_filtered({
        force = force,
        position = position,
        type = types,
    })
    local ghosts = surface.find_entities_filtered({
        force = force,
        ghost_type = types,
        position = position,
    })
    for i = 1, #ghosts do
        entities[#entities + 1] = ghosts[i]
    end
    return entities
end

local function snap_to_container(entity)
    local dir = entity.direction
    if entity.loader_type == 'input' then
        dir = opposite_direction(dir)
    end

    local pos = entity.position
    local offset = loader_offsets[dir]
    local target_pos = { x = pos.x + offset.x, y = pos.y + offset.y }

    local container = find_entities(entity.surface, target_pos, entity.force, container_types)[1]
    if not container then
        return
    end

    -- flip input/output + direction
    entity.direction = opposite_direction(dir)
    entity.loader_type = entity.loader_type == 'output' and 'input' or 'output'
end

local function snap_loader(event)
    local entity = event.entity or event.destination
    if not (entity and entity.valid and loaders[entity.name] and not entity.loader_container) then
        return
    end

    entity.update_connections()
    if not entity.loader_container then
        snap_to_container(entity)
    end
end

local valid_controllers = {
    [defines.controllers.character] = true,
    [defines.controllers.god] = true,
    [defines.controllers.editor] = true,
}

local function preserve_bot(event)
    local player = safe_get_player(event.player_index)
    if not player then
        return
    end
    local entity = player.selected
    if not (entity and entity.valid and entity.name == 'construction-robot') then
        return
    end
    local logistic_network = entity.logistic_network
    if not (logistic_network and logistic_network.valid) then
        entity.minable_flag = true -- prevents an orphan bot from being unremovable
        return
    end

    -- All valid logistic networks should have at least one cell
    local cell = logistic_network.cells[1]
    local owner = cell.owner

    -- checks if construction-robot is part of a mobile logistic network
    if owner.name ~= 'character' then
        entity.minable_flag = true
        return
    end

    -- checks if construction-robot is owned by the player that has selected it
    if owner.player.name == player.name then
        entity.minable_flag = true
        return
    end

    entity.minable_flag = false
end

-- == Features definition =====================================================

local features = {
    {
        name = 'random_train_color',
        events = {
            [defines.events.on_built_entity] = 'on_built'
        },
        handlers = {
            on_built = Token.register(function(e)
                local en = e.entity
                if en and en.valid and en.type == 'locomotive' then
                    en.color = Utils.random_RGB()
                end
            end),
        }
    },
    {
        name = 'restrict_chest',
        events = {
            [defines.events.on_built_entity] = 'on_built',
            [defines.events.on_robot_built_entity] = 'on_built'
        },
        handlers = {
            on_built = Token.register(function(e)
                local en = e.entity
                if en and en.valid and (en.name == 'passive-provider-chest' or en.type == 'container') then
                    local inv = en.get_inventory(defines.inventory.chest)
                    if inv and #inv + 1 == inv.get_bar() then
                        inv.set_bar(2)
                    end
                end
            end),
        }
    },
    {
        name = 'backer_name',
        events = {
            [defines.events.on_built_entity] = 'on_built',
            [defines.events.on_robot_built_entity] = 'on_built'
        },
        handlers = {
            on_built = Token.register(function(e)
                local en = e.entity
                if en and en.valid and en.backer_name then
                    en.backer_name = pick_name() or en.backer_name
                end
            end),
        }
    },
    {
        name = 'set_alt_on_create',
        events = { [defines.events.on_player_created] = 'on_player_created' },
        handlers = {
            on_player_created = Token.register(function(e)
                local p = safe_get_player(e.player_index)
                if not p then
                    return
                end
                p.game_view_settings.show_entity_info = true
            end),
        }
    },
    {
        name = 'inserter_drops_pickup',
        events = { [defines.events.on_player_mined_entity] = 'on_player_mined_entity' },
        handlers = {
            on_player_mined_entity = Token.register(function(e)
                local en = e.entity
                local p = safe_get_player(e.player_index)
                if not (en and en.valid and en.type == 'inserter' and not en.drop_target) then
                    return
                end
                local item = en.surface.find_entity('item-on-ground', en.drop_position)
                if item and p and valid_controllers[p.controller_type] then
                    p.mine_entity(item)
                end
            end),
        }
    },
    {
        name = 'loaders',
        events = {
            [defines.events.on_built_entity] = 'on_built',
            [defines.events.on_entity_cloned] = 'on_built',
            [defines.events.on_robot_built_entity] = 'on_built',
            [defines.events.script_raised_built] = 'on_built',
            [defines.events.script_raised_revive] = 'on_built',
            [defines.events.on_space_platform_built_entity] = 'on_built',
            [defines.events.on_research_finished] = 'on_research_finished',
            [defines.events.on_gui_opened] = 'on_gui_opened',
            [defines.events.on_gui_closed] = 'on_gui_closed',
            [defines.events.on_player_created] = 'on_player_created',
            [defines.events.on_player_joined_game] = 'on_player_created',
            [defines.events.on_player_changed_force] = 'on_player_created',
        },
        handlers = {
            on_built = Token.register(snap_loader),
            on_research_finished = Token.register(function(e)
                local recipe = loaders_technology_map[e.research.name]
                if not recipe then
                    return
                end
                e.research.force.recipes[recipe].enabled = true
                for _, p in pairs(e.research.force.players) do
                    draw_loader_frame(p.gui.relative)
                end
            end),
            -- The frame anchored to the controller GUI is kept in place permanently.
            -- Creating it inside on_gui_opened instead would delay its appearance in
            -- multiplayer by the latency round trip, as script events do not run in
            -- the client's latency-hidden state.
            on_player_created = Token.register(function(e)
                local p = safe_get_player(e.player_index)
                if p then
                    draw_loader_frame(p.gui.relative)
                end
            end),
            on_gui_opened = Token.register(function(e)
                local p = safe_get_player(e.player_index)
                if not p then
                    return
                end
                local parent, en = p.gui.relative, e.entity
                if en and en.valid and en.type == 'assembling-machine' then
                    draw_loader_frame(parent, en)
                elseif e.gui_type == defines.gui_type.controller then
                    draw_loader_frame(parent)
                end
            end),
            on_gui_closed = Token.register(function(e)
                local p = safe_get_player(e.player_index)
                if not p then
                    return
                end
                local frame = p.gui.relative[loader_machine_frame_name]
                if frame and frame.valid then
                    Gui.destroy(frame)
                end
            end)
        },
        on_register = function()
            for _, p in pairs(game.players) do
                draw_loader_frame(p.gui.relative)
            end
        end,
        on_unregister = function()
            for _, p in pairs(game.players) do
                for _, name in pairs({ loader_frame_name, loader_machine_frame_name }) do
                    local frame = p.gui.relative[name]
                    if frame and frame.valid then
                        Gui.destroy(frame)
                    end
                end
            end
        end,
    },
    {
        name = 'save_bots',
        events = {
            [defines.events.on_selected_entity_changed] = 'on_selected_entity_changed',
        },
        handlers = {
            on_selected_entity_changed = Token.register(preserve_bot),
        }
    }
}

local function register_feature(feature)
    if enabled[feature.name] then
        return false
    end
    enabled[feature.name] = true
    for event_id, handler_id in pairs(feature.events) do
        Event.add_removable(event_id, feature.handlers[handler_id])
    end
    if feature.on_register and game then
        feature.on_register()
    end
    return true
end

local function unregister_feature(feature)
    for event_id, handler_id in pairs(feature.events) do
        Event.remove_removable(event_id, feature.handlers[handler_id])
    end
    enabled[feature.name] = false
    if feature.on_unregister and game then
        feature.on_unregister()
    end
    return true
end

-- Module's public setters/getters
for _, f in pairs(features) do
    Public['set_' .. f.name] = function(enable)
        if enable then
            return register_feature(f)
        else
            return unregister_feature(f)
        end
    end
    Public['get_' .. f.name] = function()
        return enabled[f.name] or false
    end
end

-- == Events ==================================================================

Gui.on_click(loader_button_player, function(event)
    local player = event.player
    local recipe = event.element.elem_value
    local force_recipe = recipe and player.force.recipes[recipe]
    if not (force_recipe and force_recipe.enabled) then
        return
    end
    local count = (event.button == defines.mouse_button_type.left) and (event.shift and 4294967295 or 1) or (event.button == defines.mouse_button_type.right) and 5 or nil
    if count then
        player.begin_crafting { count = count, recipe = recipe }
    end
end)

Gui.on_click(loader_button_machine, function(event)
    local recipe = event.element.elem_value
    local force_recipe = recipe and event.player.force.recipes[recipe]
    if not (force_recipe and force_recipe.enabled) then
        return
    end
    local entity = Gui.get_data(event.element)
    if entity and entity.valid then
        entity.set_recipe(recipe)
    end
end)

local loader_check_token = Token.register(function()
    for _, force in pairs(game.forces) do
        local techs = force.technologies
        local recipes = force.recipes
        for t_name, r_name in pairs(loaders_technology_map) do
            if techs[t_name] and techs[t_name].researched then
                recipes[r_name].enabled = true
            end
        end
    end
    if enabled.loaders then
        for _, p in pairs(game.players) do
            draw_loader_frame(p.gui.relative)
        end
    end
end)

Event.on_init(function()
    if config.loaders then
        Task.set_timeout_in_ticks(1, loader_check_token)
    end
end)

Event.on_configuration_changed(function()
    if config.loaders then
        Task.set_timeout_in_ticks(1, loader_check_token)
    end
    for _, p in pairs(game.players) do
        for _, name in pairs({ loader_frame_name, loader_machine_frame_name }) do
            local frame = p.gui.relative[name]
            if frame then
                Gui.destroy(frame)
            end
        end
    end
end)

for _, f in pairs(features) do
    if config[f.name] then
        register_feature(f)
    end
end

return Public
