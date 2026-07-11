local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'
local Assert = require 'utils.test.assert'
local RedmewQol = require 'features.redmew_qol'

local loader_recipes = { 'loader', 'fast-loader', 'express-loader', 'turbo-loader' }

local function controller_frame(player)
    return player.gui.relative[RedmewQol._loader_frame_name]
end

local function machine_frame(player)
    return player.gui.relative[RedmewQol._loader_machine_frame_name]
end

local function raise_controller_gui_event(event_name, player)
    EventFactory.raise({
        name = event_name,
        tick = game.tick,
        player_index = player.index,
        gui_type = defines.gui_type.controller
    })
end

local function count_loader_buttons(element)
    local count = 0
    for _, child in pairs(element.children) do
        if child.type == 'choose-elem-button' then
            count = count + 1
        else
            count = count + count_loader_buttons(child)
        end
    end
    return count
end

Declare.module({'features', 'redmew qol', 'loaders gui'}, function()
    local old_feature_enabled
    local old_recipe_enabled

    Declare.module_startup(function(context)
        local force = context.player.force
        old_feature_enabled = RedmewQol.get_loaders()
        old_recipe_enabled = force.recipes['loader'].enabled

        force.recipes['loader'].enabled = true
        if not old_feature_enabled then
            RedmewQol.set_loaders(true)
        end
    end)

    Declare.module_teardown(function(context)
        context.player.force.recipes['loader'].enabled = old_recipe_enabled
        if not old_feature_enabled then
            RedmewQol.set_loaders(false)
        else
            -- redraw with the restored recipe state
            raise_controller_gui_event(defines.events.on_gui_opened, context.player)
        end
    end)

    Declare.test('frame is drawn for all players when the feature is enabled', function(context)
        local player = context.player

        RedmewQol.set_loaders(false)
        Assert.is_nil(controller_frame(player), 'frame should be removed when the feature is disabled')

        RedmewQol.set_loaders(true)
        Assert.valid(controller_frame(player), 'frame should be drawn when the feature is enabled')
    end)

    Declare.test('frame persists when the crafting menu is closed', function(context)
        local player = context.player

        raise_controller_gui_event(defines.events.on_gui_opened, player)
        Assert.valid(controller_frame(player), 'frame should exist after opening the crafting menu')

        raise_controller_gui_event(defines.events.on_gui_closed, player)
        Assert.valid(controller_frame(player), 'frame should persist after closing the crafting menu')
    end)

    Declare.test('frame is removed when no loader recipe is enabled', function(context)
        local player = context.player
        local recipes = player.force.recipes

        local old_states = {}
        for _, name in pairs(loader_recipes) do
            local recipe = recipes[name]
            if recipe then
                old_states[name] = recipe.enabled
                recipe.enabled = false
            end
        end

        raise_controller_gui_event(defines.events.on_gui_opened, player)
        local removed = controller_frame(player) == nil

        for name, state in pairs(old_states) do
            recipes[name].enabled = state
        end
        raise_controller_gui_event(defines.events.on_gui_opened, player)

        Assert.is_true(removed, 'frame should be removed when no loader recipe is enabled')
        Assert.valid(controller_frame(player), 'frame should be drawn again when a loader recipe is enabled')
    end)

    Declare.test('frame lists one button per enabled loader recipe', function(context)
        local player = context.player

        raise_controller_gui_event(defines.events.on_gui_opened, player)

        local expected = 0
        for _, name in pairs(loader_recipes) do
            local recipe = player.force.recipes[name]
            if recipe and recipe.enabled then
                expected = expected + 1
            end
        end

        Assert.equal(expected, count_loader_buttons(controller_frame(player)), 'frame should have one button per enabled loader recipe')
    end)

    Declare.test('machine frame is separate and removed when its gui is closed', function(context)
        local player = context.player
        local surface = player.surface
        local position = surface.find_non_colliding_position('assembling-machine-1', player.position, 32, 1)
        local machine = surface.create_entity({ name = 'assembling-machine-1', position = position, force = player.force })

        raise_controller_gui_event(defines.events.on_gui_opened, player)

        EventFactory.raise({
            name = defines.events.on_gui_opened,
            tick = game.tick,
            player_index = player.index,
            gui_type = defines.gui_type.entity,
            entity = machine
        })
        local machine_frame_drawn = machine_frame(player) ~= nil

        EventFactory.raise({
            name = defines.events.on_gui_closed,
            tick = game.tick,
            player_index = player.index,
            gui_type = defines.gui_type.entity,
            entity = machine
        })
        local machine_frame_removed = machine_frame(player) == nil
        local controller_frame_kept = controller_frame(player) ~= nil

        machine.destroy()

        Assert.is_true(machine_frame_drawn, 'machine frame should be drawn when a machine gui is opened')
        Assert.is_true(machine_frame_removed, 'machine frame should be removed when the machine gui is closed')
        Assert.is_true(controller_frame_kept, 'controller frame should not be affected by the machine gui closing')
    end)
end)
