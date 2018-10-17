--[[-- info
    Provides the ability to purchase items from the market.
]]

-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Task = require 'utils.Task'
local Gui = require 'utils.gui'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local Global = require 'utils.global'
local insert = table.insert

-- this
local MarketExchange = {}

local config = {}

local stone_tracker = {
    stone_sent_to_surface = 0,
    previous_stone_sent_to_surface = 0,
}

local stone_collecting = {
    initial_value = 0,
    active_modifier = 0,
    research_modifier = 0,
    market_modifier = 0,
}

local mining_efficiency = {
    active_modifier = 0,
    research_modifier = 0,
    market_modifier = 0,
}

local inventory_slots = {
    active_modifier = 0,
    research_modifier = 0,
    market_modifier = 0,
}

Global.register({
    stone_collecting = stone_collecting,
    stone_tracker = stone_tracker,
    mining_efficiency = mining_efficiency,
    inventory_slots = inventory_slots,
}, function(tbl)
    stone_collecting = tbl.stone_collecting
    stone_tracker = tbl.stone_tracker
    mining_efficiency = tbl.mining_efficiency
    inventory_slots = tbl.inventory_slots
end)

local function send_stone_to_surface(total)
    stone_tracker.previous_stone_sent_to_surface = stone_tracker.stone_sent_to_surface
    stone_tracker.stone_sent_to_surface = stone_tracker.stone_sent_to_surface + total
end

local on_market_timeout_finished = Token.register(function(params)
    Template.market(params.surface, params.position, params.player_force, params.currency_item, {})

    local tiles = {}
    for _, position in pairs(params.void_chest_tiles) do
        insert(tiles, {name = 'tutorial-grid', position = position})
    end

    params.surface.set_tiles(tiles)
end)

local function update_mining_speed(force)
    -- remove the current buff
    local old_modifier = force.manual_mining_speed_modifier - mining_efficiency.active_modifier

    -- update the active modifier
    mining_efficiency.active_modifier = mining_efficiency.research_modifier + mining_efficiency.market_modifier

    -- add the new active modifier to the non-buffed modifier
    force.manual_mining_speed_modifier = old_modifier + mining_efficiency.active_modifier
end

local function update_inventory_slots(force)
    -- remove the current buff
    local old_modifier = force.character_inventory_slots_bonus - inventory_slots.active_modifier

    -- update the active modifier
    inventory_slots.active_modifier = inventory_slots.research_modifier + inventory_slots.market_modifier

    -- add the new active modifier to the non-buffed modifier
    force.character_inventory_slots_bonus = old_modifier + inventory_slots.active_modifier
end

local function update_stone_collecting()
    -- remove the current buff
    local old_modifier = stone_collecting.initial_value - stone_collecting.active_modifier

    -- update the active modifier
    stone_collecting.active_modifier = stone_collecting.research_modifier + stone_collecting.market_modifier

    -- add the new active modifier to the non-buffed modifier
    stone_collecting.initial_value = old_modifier + stone_collecting.active_modifier
end

local function update_market_contents(market)
    if (stone_tracker.previous_stone_sent_to_surface == stone_tracker.stone_sent_to_surface) then
        return
    end

    local should_update_mining_speed = false
    local should_update_inventory_slots = false
    local should_update_stone_collecting = false
    local add_market_item
    local print = game.print

    for _, unlockable in pairs(config.unlockables) do
        local is_in_range = unlockable.stone > stone_tracker.previous_stone_sent_to_surface and unlockable.stone <= stone_tracker.stone_sent_to_surface

        -- only add the item to the market if it's between the old and new stone range
        if (is_in_range and unlockable.type == 'market') then
            add_market_item = add_market_item or market.add_market_item

            local name = unlockable.prototype.name
            local price = unlockable.prototype.price
            print('Mining Foreman: New wares at the market! Come get your ' .. name .. ' for only ' .. price .. ' ' .. config.currency_item .. '!')

            add_market_item({
                price = {{config.currency_item, price}},
                offer = {type = 'give-item', item = name, count = 1}
            })
        elseif (is_in_range and unlockable.type == 'buff' and unlockable.prototype.name == 'mining_speed') then
            local value = unlockable.prototype.value
            print('Mining Foreman: Increased mining speed by ' .. value .. '%!')
            should_update_mining_speed = true
            mining_efficiency.market_modifier = mining_efficiency.market_modifier + (value / 100)
        elseif (is_in_range and unlockable.type == 'buff' and unlockable.prototype.name == 'inventory_slot') then
            local value = unlockable.prototype.value
            print('Mining Foreman: Increased inventory slots by ' .. value .. '!')
            should_update_inventory_slots = true
            inventory_slots.market_modifier = inventory_slots.market_modifier + value
        elseif (is_in_range and unlockable.type == 'buff' and unlockable.prototype.name == 'stone_automation') then
            local value = unlockable.prototype.value
            print('Mining Foreman: sending stone to the surface automatically is now increased by ' .. value .. '!')
            should_update_stone_collecting = true
            stone_collecting.market_modifier = stone_collecting.market_modifier + value
        end
    end

    local force

    if (should_update_mining_speed) then
        force = force or game.forces.player
        update_mining_speed(force)
    end

    if (should_update_inventory_slots) then
        force = force or game.forces.player
        update_inventory_slots(force)
    end

    if (should_update_stone_collecting) then
        update_stone_collecting()
    end
end

local function on_research_finished(event)
    local force = game.forces.player
    local current_modifier = mining_efficiency.research_modifier
    local new_modifier = force.mining_drill_productivity_bonus * config.mining_speed_productivity_multiplier / 2

    if (current_modifier == new_modifier) then
        -- something else was researched
        return
    end

    mining_efficiency.research_modifier = new_modifier
    inventory_slots.research_modifier = force.mining_drill_productivity_bonus * 50 -- 1 per level
    stone_collecting.research_modifier = force.mining_drill_productivity_bonus * 1250 -- 25 per level

    update_inventory_slots(force)
    update_mining_speed(force)
    update_stone_collecting()
end

local function redraw_title(data)
    data.frame.caption = stone_tracker.stone_sent_to_surface .. ' ' .. config.currency_item .. ' sent to the surface'
end

local function redraw_list(data)
    local market_scroll_pane = data.market_scroll_pane
    Gui.clear(market_scroll_pane)

    local add = market_scroll_pane.add

    for _, unlockable in pairs(config.unlockables) do
        local is_unlocked = unlockable.stone <= stone_tracker.stone_sent_to_surface
        local message
        -- only add the item to the market if it's between the old and new stone range
        if (unlockable.type == 'market') then
            message = 'Market item: ' .. unlockable.prototype.name
        elseif (unlockable.type == 'buff' and unlockable.prototype.name == 'mining_speed') then
            message = 'Manual mining speed: +' .. unlockable.prototype.value .. '%'
        elseif (unlockable.type == 'buff' and unlockable.prototype.name == 'inventory_slot') then
            message = 'Inventory slot: +' .. unlockable.prototype.value
        elseif (unlockable.type == 'buff' and unlockable.prototype.name == 'stone_automation') then
            message = 'Automate stone to surface: +' .. unlockable.prototype.value
        else
            Debug.print('failed getting a message for: ' .. serpent.line(unlockable))
        end

        message = unlockable.stone .. ' stone: ' .. message

        local label = add({type = 'label', caption = message})
        if (is_unlocked) then
            label.style.font_color = {r = 1, g = 1, b = 1}
        else
            label.style.font_color = {r = 0.5, g = 0.5, b = 0.5}
        end
    end
end

local function on_market_item_purchased(event)
    if (1 ~= event.offer_index) then
        return
    end

    send_stone_to_surface(config.stone_to_surface_amount * event.count)
    update_market_contents(event.market)
end

local function on_placed_entity(event)
    local market = event.entity
    if ('market' ~= market.name) then
        return
    end

    market.add_market_item({
        price = {{config.currency_item, 50}},
        offer = {type = 'nothing', effect_description = 'Send ' .. config.stone_to_surface_amount .. ' ' .. config.currency_item .. ' to the surface'}
    })

    update_market_contents(market)
end

function MarketExchange.get_extra_map_info(config)
    return 'Market Exchange, trade your stone or send it to the surface'
end

local function toggle(event)
    local player = event.player
    local center = player.gui.center
    local frame = center['Diggy.MarketExchange.Frame']

    if (frame) then
        Gui.destroy(frame)
        return
    end

    frame = center.add({name = 'Diggy.MarketExchange.Frame', type = 'frame', direction = 'vertical'})

    local market_scroll_pane = frame.add({type = 'scroll-pane'})
    market_scroll_pane.style.maximal_height = 400

    frame.add({ type = 'button', name = 'Diggy.MarketExchange.Button', caption = 'Close'})

    local data = {
        frame = frame,
        market_scroll_pane = market_scroll_pane,
    }

    redraw_title(data)
    redraw_list(data)

    Gui.set_data(frame, data)

    player.opened = frame
end

local function on_player_created(event)
    game.players[event.player_index].gui.top.add({
        name = 'Diggy.MarketExchange.Button',
        type = 'sprite-button',
        sprite = 'item/stone',
    })
end

Gui.on_click('Diggy.MarketExchange.Button', toggle)
Gui.on_custom_close('Diggy.MarketExchange.Frame', function (event)
    event.element.destroy()
end)

function MarketExchange.on_init()
    Task.set_timeout_in_ticks(50, on_market_timeout_finished, {
        surface = game.surfaces.nauvis,
        position = config.market_spawn_position,
        player_force = game.forces.player,
        currency_item = config.currency_item,
        void_chest_tiles = config.void_chest_tiles,
    })

    update_mining_speed(game.forces.player)
end

--[[--
    Registers all event handlers.
]]
function MarketExchange.register(cfg)
    config = cfg

    Event.add(defines.events.on_research_finished, on_research_finished)
    Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
    Event.add(Template.events.on_placed_entity, on_placed_entity)
    Event.add(defines.events.on_player_created, on_player_created)

    local x_min
    local y_min
    local x_max
    local y_max

    for _, position in pairs(config.void_chest_tiles) do
        local x = position.x
        local y = position.y

        if (nil == x_min or x < x_min) then
            x_min = x
        end

        if (nil == x_max or x > x_max) then
            x_max = x
        end

        if (nil == y_min or y < y_min) then
            y_min = y
        end

        if (nil == y_max or y > y_max) then
            y_max = y
        end
    end

    local area = {{x_min, y_min}, {x_max + 1, y_max + 1}}

    Event.on_nth_tick(config.void_chest_frequency, function ()
        local send_to_surface = 0
        local find_entities_filtered = game.surfaces.nauvis.find_entities_filtered
        local chests = find_entities_filtered({area = area, type = {'container', 'logistics-container'}})
        local to_fetch = stone_collecting.active_modifier

        for _, chest in pairs(chests) do
            local chest_contents = chest.get_inventory(defines.inventory.chest)
            local stone_in_chest = chest_contents.get_item_count(config.currency_item)
            local delta = to_fetch

            if (stone_in_chest < delta) then
                delta = stone_in_chest
            end

            if (delta > 0) then
                chest_contents.remove({name = config.currency_item, count = delta})
                send_to_surface = send_to_surface + delta
            end
        end

        if (send_to_surface == 0) then
            return
        end

        local markets = find_entities_filtered({name = 'market', position = config.market_spawn_position, limit = 1})

        if (#markets == 0) then
            Debug.printPosition(config.market_spawn_position, 'Unable to find a market')
            return
        end

        send_stone_to_surface(send_to_surface)
        update_market_contents(markets[1])
    end)
end

return MarketExchange
