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

-- this
local MarketExchange = {}

local config = {}

local stone_tracker = {
    first_time_market_item = nil,
    stone_sent_to_surface = 0,
    previous_stone_sent_to_surface = 0,
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
    stone_tracker = stone_tracker,
    mining_efficiency = mining_efficiency,
    inventory_slots = inventory_slots,
}, function(tbl)
    stone_tracker = tbl.stone_tracker
    mining_efficiency = tbl.mining_efficiency
    inventory_slots = tbl.inventory_slots
end)

local on_market_timeout_finished = Token.register(function(params)
    Template.market(params.surface, params.position, params.player_force, params.currency_item, {})
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

local function update_market_contents(market)
    local should_update_mining_speed = false
    local should_update_inventory_slots = false

    if (nil ~= stone_tracker.first_time_market_item) then
        market.add_market_item(stone_tracker.first_time_market_item)
        stone_tracker.first_time_market_item = nil
    end

    for _, unlockable in pairs(config.unlockables) do
        local is_in_range = unlockable.stone > stone_tracker.previous_stone_sent_to_surface and unlockable.stone <= stone_tracker.stone_sent_to_surface

        -- only add the item to the market if it's between the old and new stone range
        if (is_in_range and unlockable.type == 'market') then
            market.add_market_item({
                price = {{config.currency_item, unlockable.prototype.price}},
                offer = {type = 'give-item', item = unlockable.prototype.name, count = 1}
            })
        elseif (is_in_range and unlockable.type == 'buff' and unlockable.prototype.name == 'mining_speed') then
            should_update_mining_speed = true
            mining_efficiency.market_modifier = mining_efficiency.market_modifier + (unlockable.prototype.value / 100)
        elseif (is_in_range and unlockable.type == 'buff' and unlockable.prototype.name == 'inventory_slot') then
            should_update_inventory_slots = true
            inventory_slots.market_modifier = inventory_slots.market_modifier + unlockable.prototype.value
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
    inventory_slots.research_modifier = (force.mining_drill_productivity_bonus / 2) * 100

    update_inventory_slots(force)
    update_mining_speed(force)
end

local function on_market_item_purchased(event)
    if (1 ~= event.offer_index) then
        return
    end

    stone_tracker.previous_stone_sent_to_surface = stone_tracker.stone_sent_to_surface
    stone_tracker.stone_sent_to_surface = stone_tracker.stone_sent_to_surface + (config.stone_to_surface_amount * event.count)

    update_market_contents(event.market)
end

local function on_placed_entity(event)
    if ('market' ~= event.entity.name) then
        return
    end

    update_market_contents(event.entity)
end

function MarketExchange.get_extra_map_info(config)
    return 'Market Exchange, trade your stone or send it to the surface'
end

local function redraw_title(data)
    data.frame.caption = stone_tracker.stone_sent_to_surface .. ' stone sent to the surface'
end

local function redraw_list(data)
    local market_scroll_pane = data.market_scroll_pane
    Gui.clear(market_scroll_pane)

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
        else
            Debug.print('failed getting a message for: ' .. serpent.line(unlockable))
        end

        message = unlockable.stone .. ' stone: ' .. message

        local label = market_scroll_pane.add({type = 'label', caption = message})
        if (is_unlocked) then
            label.style.font_color = {r = 1, g = 1, b = 1}
        else
            label.style.font_color = {r = 0.5, g = 0.5, b = 0.5}
        end
    end
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
    })

    update_mining_speed(game.forces.player)
end

--[[--
    Registers all event handlers.
]]
function MarketExchange.register(cfg)
    config = cfg

    stone_tracker.first_time_market_item = {
        price = {{config.currency_item, 50}},
        offer = {type = 'nothing', effect_description = 'Send ' .. config.stone_to_surface_amount .. ' stone to the surface'}
    }

    Event.add(defines.events.on_research_finished, on_research_finished)
    Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
    Event.add(Template.events.on_placed_entity, on_placed_entity)
    Event.add(defines.events.on_player_created, on_player_created)
end

return MarketExchange
