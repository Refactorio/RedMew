require 'utils.table'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.schedule'
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local math = require 'utils.math'
local Color = require 'resources.color_presets'
local format = string.format
local size = table.size
local insert = table.insert
local pairs = pairs
local tonumber = tonumber
local set_timeout_in_ticks = Schedule.set_timeout_in_ticks
local clamp = math.clamp
local floor = math.floor
local ceil = math.ceil
local raise_event = script.raise_event
local market_frame_name = Gui.uid_name()
local market_frame_close_button_name = Gui.uid_name()
local item_button_name = Gui.uid_name()
local count_slider_name = Gui.uid_name()
local count_text_name = Gui.uid_name()

local Retailer = {}

Retailer.events = {
    --- Triggered when a purchase is made
    -- Event {
    --        item = item,
    --        count = count,
    --        player = player,
    --        group_name = group_name,
    --    }
    on_market_purchase = script.generate_event_name(),
}

local market_gui_close_distance_squared = 6 * 6 + 6 * 6
local do_update_market_gui -- token

---Global storage
---Markets are indexed by the position "x,y" and contains the group it belongs to
---Items are indexed by the group name and is a list indexed by the item name and contains the prices per item
---players_in_market_view is a list of {position, group_name} data
local memory = {
    markets = {},
    items = {},
    group_label = {},
    players_in_market_view = {},
    market_gui_refresh_scheduled = {},
}

Global.register({
    memory = memory,
}, function (tbl)
    memory = tbl.memory
end)

local function schedule_market_gui_refresh(group_name)
    if memory.market_gui_refresh_scheduled[group_name] then
        -- already scheduled
        return
    end

    set_timeout_in_ticks(1, do_update_market_gui, {group_name = group_name})
    memory.market_gui_refresh_scheduled[group_name] = true
end

---Sets the name of the market group, provides a user friendly label in the GUI.
---@param group_name string
---@param label string
function Retailer.set_market_group_label(group_name, label)
    memory.group_label[group_name] = label

    schedule_market_gui_refresh(group_name)
end

---Gets the name of the market group.
---@param group_name string
function Retailer.get_market_group_label(group_name)
    return memory.group_label[group_name] or 'Market'
end

---Returns all item for the group_name retailer.
---@param group_name string
function Retailer.get_items(group_name)
    return memory.items[group_name] or {}
end

---Removes an item from the markets for the group_name retailer.
---@param group_name string
---@param item_name string
function Retailer.remove_item(group_name, item_name)
    if not memory.items[group_name] then
        return
    end

    memory.items[group_name][item_name] = nil

    schedule_market_gui_refresh(group_name)
end

local function redraw_market_items(data)
    local grid = data.grid

    Gui.clear(grid)

    local count = data.count
    local market_items = data.market_items
    local player_coins = data.player_coins

    if size(market_items) == 0 then
        grid.add({type = 'label', caption = 'No items available at this time'})
        return
    end

    for i, item in pairs(market_items) do
        local price = item.price
        local tooltip = {'', item.name_label, format('\nprice: %d', price)}
        local description = item.description
        local total_price = ceil(price * count)
        local disabled = item.disabled == true
        local message
        if total_price == 1 then
            message = '1 coin'
        else
            message = total_price .. ' coins'
        end

        local missing_coins = total_price - player_coins
        local is_missing_coins = missing_coins > 0

        if description then
            insert(tooltip, '\n' .. item.description)
        end

        if disabled then
            insert(tooltip, '\n\n' .. (item.disabled_reason or 'Not available'))
        elseif is_missing_coins then
            insert(tooltip, '\n\n' .. format('Missing %d coins to buy %d', missing_coins, count))
        end

        local button = grid.add({type = 'flow'}).add({
            type = 'sprite-button',
            name = item_button_name,
            sprite = item.sprite,
            number = count,
            tooltip = tooltip,
        })
        button.style = 'slot_button'

        Gui.set_data(button, {index = i, data = data})

        local label = grid.add({type = 'label', caption = message})
        local label_style = label.style
        label_style.width = 93
        label_style.height = 32
        label_style.font = 'default-bold'
        label_style.vertical_align = 'center'

        if disabled then
            label_style.font_color = Color.dark_grey
            button.enabled = false
        elseif is_missing_coins then
            label_style.font_color = Color.red
            button.enabled = false
        end
    end
end

local function do_coin_label(coin_count, label)
    if coin_count == 1 then
        label.caption = '1 coin available'
    else
        label.caption = coin_count .. ' coins available'
    end
    label.style.font = 'default-bold'
end

local function draw_market_frame(player, group_name)
    local frame = player.gui.center.add({
        type = 'frame',
        name = market_frame_name,
        caption = Retailer.get_market_group_label(group_name),
        direction = 'vertical',
    })

    local scroll_pane = frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.maximal_height = 600

    local grid = scroll_pane.add({type = 'table', column_count = 10})

    local market_items = Retailer.get_items(group_name)
    local player_coins = player.get_item_count('coin')
    local data = {
        grid = grid,
        count = 1,
        market_items = market_items,
        player_coins = player_coins,
        market_group = group_name,
    }

    local coin_label = frame.add({type = 'label'})
    do_coin_label(player_coins, coin_label)
    data.coin_label = coin_label

    redraw_market_items(data)

    local bottom_grid = frame.add({type = 'table', column_count = 2})

    bottom_grid.add({type = 'label', caption = 'Quantity: '}).style.font = 'default-bold'

    local count_text = bottom_grid.add({
        type = 'text-box',
        name = count_text_name,
        text = '1',
    })

    local count_slider = frame.add({
        type = 'slider',
        name = count_slider_name,
        minimum_value = 1,
        maximum_value = 7,
        value = 1,
    })

    frame.add({name = market_frame_close_button_name, type = 'button', caption = 'Close'})

    count_slider.style.width = 115
    count_text.style.width = 45

    data.slider = count_slider
    data.text = count_text

    Gui.set_data(count_slider, data)
    Gui.set_data(count_text, data)
    Gui.set_data(frame, data)

    return frame
end

---Returns the group name of the market at the given position, nil if not registered.
---@param position Position
local function get_market_group_name(position)
    return memory.markets[position.x .. ',' .. position.y]
end

---Sets the group name for a market at a given position.
---@param position Position
---@param group_name string
local function set_market_group_name(position, group_name)
    memory.markets[position.x .. ',' .. position.y] = group_name
end

Event.add(defines.events.on_gui_opened, function (event)
    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local position = entity.position
    local group_name = get_market_group_name(position)
    if not group_name then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    memory.players_in_market_view[player.index] = {
        position = position,
        group_name = group_name,
    }
    local frame = draw_market_frame(player, group_name)

    player.opened = frame
end)

Gui.on_custom_close(market_frame_name, function (event)
    local element = event.element
    memory.players_in_market_view[event.player.index] = nil
    Gui.destroy(element)
end)

local function close_market_gui(player)
    local element = player.gui.center
    memory.players_in_market_view[player.index] = nil

    if element and element.valid then
        element = element[market_frame_name]
        if element and element.valid then
            Gui.destroy(element)
        end
    end
end

Gui.on_click(market_frame_close_button_name, function (event)
    close_market_gui(event.player)
end)

Event.add(defines.events.on_player_died, function (event)
    local player = Game.get_player_by_index(event.player_index or 0)

    if not player or not player.valid then
        return
    end

    close_market_gui(player)
end)

Gui.on_value_changed(count_slider_name, function (event)
    local element = event.element
    local data = Gui.get_data(element)

    local value = floor(element.slider_value)
    local count
    if value % 2 == 0 then
        count = 10 ^ (value * 0.5) * 0.5
    else
        count = 10 ^ ((value - 1) * 0.5)
    end

    data.count = count
    data.text.text = count

    redraw_market_items(data)
end)

Gui.on_text_changed(count_text_name, function (event)
    local element = event.element
    local data = Gui.get_data(element)

    local count = tonumber(element.text)

    if count then
        count = floor(count)
        count = clamp(count, 1, 1000)
        data.count = count
        data.text.text = count
    else
        data.count = 1
    end

    redraw_market_items(data)
end)

Gui.on_click(item_button_name, function (event)
    local player = event.player
    local element = event.element
    local button_data = Gui.get_data(element)
    local data = button_data.data

    local item = data.market_items[button_data.index]

    if not item then
        player.print('This item is no longer available in the market')
        return
    end

    if item.disabled then
        player.print({'', item.name_label, ' is disabled. ', item.disabled_reason or ''})
        return
    end

    local name = item.name
    local price = item.price
    local count = data.count

    local cost = ceil(price * count)
    local coin_count = player.get_item_count('coin')

    if cost > coin_count then
        player.print('Insufficient coins')
        return
    end

    if item.type == 'item' then
        local inserted = player.insert({name = name, count = count})
        if inserted < count then
            player.print('Insufficient inventory space')
            if inserted > 0 then
                player.remove_item({name = name, count = inserted})
            end
            return
        end
    end

    player.remove_item({name = 'coin', count = cost})
    local player_coins = data.player_coins - cost
    data.player_coins = player_coins
    do_coin_label(player_coins, data.coin_label)
    redraw_market_items(data)
    PlayerStats.change_coin_spent(player.index, cost)

    raise_event(Retailer.events.on_market_purchase, {
        item = item,
        count = count,
        player = player,
    })
end)

---Add a market to the group_name retailer.
---@param group_name string
---@param market_entity LuaEntity
function Retailer.add_market(group_name, market_entity)
    set_market_group_name(market_entity.position, group_name)
end

---Sets an item for all the group_name markets.
---@param group_name string
---@param prototype table with item name and price
function Retailer.set_item(group_name, prototype)
    if not memory.items[group_name] then
        memory.items[group_name] = {}
    end

    local item_name = prototype.name
    local name_label = prototype.name_label

    if not name_label then
        local item_prototype = game.item_prototypes[item_name]
        name_label = item_prototype and item_prototype.localised_name
    end

    prototype.name_label = name_label or item_name
    prototype.sprite = prototype.sprite or 'item/' .. item_name
    prototype.type = prototype.type or 'item'

    memory.items[group_name][item_name] = prototype

    schedule_market_gui_refresh(group_name)
end

---Enables a market item by group name and item name if it's registered.
---@param group_name string
---@param item_name string
function Retailer.enable_item(group_name, item_name)
    if not memory.items[group_name] then
        return
    end

    local prototype = memory.items[group_name][item_name]

    if not prototype then
        return
    end

    prototype.disabled = false
    prototype.disabled_reason = false

    schedule_market_gui_refresh(group_name)
end

---Disables a market item by group name and item name if it's registered.
---@param group_name string
---@param item_name string
---@param disabled_reason string
function Retailer.disable_item(group_name, item_name, disabled_reason)
    if not memory.items[group_name] then
        return
    end

    local prototype = memory.items[group_name][item_name]

    if not prototype then
        return
    end

    prototype.disabled = true
    prototype.disabled_reason = disabled_reason

    schedule_market_gui_refresh(group_name)
end

do_update_market_gui = Token.register(function(params)
    local group_name = params.group_name

    for player_index, view_data in pairs(memory.players_in_market_view) do
        if group_name == view_data.group_name then
            local player = Game.get_player_by_index(player_index)
            if player and player.valid then
                local frame = player.gui.center[market_frame_name]
                if not frame or not frame.valid then
                    -- player already closed the market GUI and somehow this was not reported
                    memory.players_in_market_view[player_index] = nil
                else
                    redraw_market_items(Gui.get_data(frame))
                end
            else
                -- player is no longer in the game, remove it from the market view
                memory.players_in_market_view[player_index] = nil
            end
        end
    end

    -- mark it as updated
    memory.market_gui_refresh_scheduled[group_name] = nil
end)

Event.on_nth_tick(37, function()
    for player_index, view_data in pairs(memory.players_in_market_view) do
        local player = Game.get_player_by_index(player_index)
        if player and player.valid then
            local player_position = player.position
            local market_position = view_data.position
            local delta_x = player_position.x - market_position.x
            local delta_y = player_position.y - market_position.y

            if delta_x * delta_x + delta_y * delta_y > market_gui_close_distance_squared then
                close_market_gui(player)
            end
        else
            -- player is no longer in the game, remove it from the market view
            memory.players_in_market_view[player_index] = nil
        end
    end
end)

return Retailer
