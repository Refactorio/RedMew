--[[-- info
    Provides the ability to collect coins and send them to space.
]]

-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local ScoreTable = require 'map_gen.Diggy.ScoreTable'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local random = math.random
local ceil = math.ceil
local Gui = require 'utils.gui'
local utils = require 'utils.core'

-- this
local ArtefactHunting = {}

local coin_color = {r = 255, g = 215, b = 0}

-- some GUI stuff
local function redraw_table(data)
    local list = data.list
    Gui.clear(list)

    data.frame.caption = 'Scoretable'

    for name, value in pairs(ScoreTable.all()) do
        local table = list.add({type = 'table', column_count = 2})

        local key = table.add({type = 'label', name = 'Diggy.ArtefactHunting.Frame.List.Key', caption = name})
        key.style.minimal_width = 175

        local val = table.add({type = 'label', name = 'Diggy.ArtefactHunting.Frame.List.Val', caption = utils.comma_value(value)})
        val.style.minimal_width = 225
    end
end


local function toggle(event)
    local player = event.player
    local center = player.gui.left
    local frame = center['Diggy.ArtefactHunting.Frame']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_table(data)
        return
    end

    frame = center.add({name = 'Diggy.ArtefactHunting.Frame', type = 'frame', direction = 'vertical'})

    local scroll_pane = frame.add({type = 'scroll-pane'})
    scroll_pane.style.maximal_height = 400

    frame.add({ type = 'button', name = 'Diggy.ArtefactHunting.Button', caption = 'Close'})

    local data = {
        frame = frame,
        list = scroll_pane
    }

    redraw_table(data)

    Gui.set_data(frame, data)
end

local function on_player_created(event)
    Game.get_player_by_index(event.player_index).gui.top.add({
        name = 'Diggy.ArtefactHunting.Button',
        type = 'sprite-button',
        sprite = 'item/steel-axe',
    })
end

Gui.on_click('Diggy.ArtefactHunting.Button', toggle)
Gui.on_custom_close('Diggy.ArtefactHunting.Frame', function (event)
    event.element.destroy()
end)

function ArtefactHunting.update_gui()
    for _, p in pairs(game.connected_players) do
        local frame = p.gui.left['Diggy.ArtefactHunting.Frame']

        if frame and frame.valid then
            local data = {player = p, trigger = 'update_gui'}
            toggle(data)
        end
    end
end

--[[--
    Registers all event handlers.
]]
function ArtefactHunting.register(config)
    Event.add(defines.events.on_player_created, on_player_created)
    Event.on_nth_tick(61, ArtefactHunting.update_gui)

    ScoreTable.reset('Coins sent to space')

    local seed
    local function get_noise(surface, x, y)
        seed = seed or surface.map_gen_settings.seed + surface.index + 300
        return Perlin.noise(x * config.noise_variance * 0.9, y * config.noise_variance * 1.1, seed)
    end

    local distance_required = config.minimal_treasure_chest_distance * config.minimal_treasure_chest_distance

    Event.add(defines.events.on_rocket_launched, function (event)
        local coins = event.rocket.get_inventory(defines.inventory.rocket).get_item_count('coin')
        if coins > 0 then
            local sum = ScoreTable.add('Coins sent to space', coins)
            game.print('sent ' .. coins .. ' coins into space! The space station is now holding ' .. sum .. ' coins.')
        end
    end)

    Event.add(Template.events.on_void_removed, function (event)
        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y <= distance_required) then
            return
        end

        local surface = event.surface

        if get_noise(surface, x, y) < config.treasure_chest_noise_threshold then
            return
        end

        local chest = surface.create_entity({name = 'steel-chest', position = position, force = game.forces.player})

        if not chest then
            return
        end

        local insert = chest.insert
        for name, prototype in pairs(config.treasure_chest_raffle) do
            if random() <= prototype.chance then
                insert({name = name, count = random(prototype.min, prototype.max)})
            end
        end
    end)

    local modifiers = config.alien_coin_modifiers

    local function picked_up_coins(player_index, count)
        local text
        if count == 1 then
            text = '+1 coin'
            ScoreTable.increment('Collected coins')
        else
            text = '+' .. count ..' coins'
            ScoreTable.add('Collected coins', count)
        end

        Game.print_player_floating_text(player_index, text, coin_color)
    end

    ScoreTable.reset('Collected coins')

    local alien_coin_drop_chance = config.alien_coin_drop_chance

    Event.add(defines.events.on_entity_died, function (event)
        local entity = event.entity
        local force = entity.force
        if force.name ~= 'enemy' or random() > alien_coin_drop_chance then
            return
        end

        local modifier = modifiers[entity.name] or 1
        local evolution_multiplier = force.evolution_factor
        local count = random(
            ceil(2 * evolution_multiplier * modifier),
            ceil(5 * evolution_multiplier * modifier)
        )

        entity.surface.create_entity({
            name = 'item-on-ground',
            position = entity.position,
            stack = {name = 'coin', count = count}
        })
    end)

    Event.add(defines.events.on_picked_up_item, function (event)
        local stack = event.item_stack
        if stack.name ~= 'coin' then
            return
        end

        picked_up_coins(event.player_index, stack.count)
    end)

    Event.add(defines.events.on_pre_player_mined_item, function (event)
        if event.entity.type ~= 'simple-entity' then
            return
        end

        if random() > config.mining_coin_chance then
            return
        end

        local count = random(config.mining_coin_amount.min, config.mining_coin_amount.max)
        local player_index = event.player_index

        Game.get_player_by_index(player_index).insert({name = 'coin', count = count})
        picked_up_coins(player_index, count)
    end)

    if (config.display_chest_locations) then
        Event.add(defines.events.on_chunk_generated, function (event)
            local surface = event.surface
            local area = event.area

            for x = area.left_top.x, area.left_top.x + 31 do
                local sq_x = x * x
                for y = area.left_top.y, area.left_top.y + 31 do
                    if sq_x + y * y >= distance_required and get_noise(surface, x, y) >= config.treasure_chest_noise_threshold then
                        Debug.print_grid_value('chest', surface, {x = x, y = y}, nil, nil, true)
                    end
                end
            end
        end)
    end
end

function ArtefactHunting.get_extra_map_info(config)
    return 'Artefact Hunting, find precious coins while mining and launch them to the surface!'
end

return ArtefactHunting
