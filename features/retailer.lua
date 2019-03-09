--[[
    The Retailer provides a market replacement GUI with additional
    functionality. To register a market, you need the market entity and a name
    for the market group:

    Retailer.add_market(group_name, market_entity)

    If you don't have a group name or don't want to re-use it, you can generate
    a group name with:

    local group_name = Retailer.generate_group_id()

    To change the description displayed in the market GUI, you can call:

    Retailer.set_market_group_label(group_name, 'Name of your market')

    To add, remove, disable and enable items, you can call their respective
    functions. Note that each item can be added only once and will replace the
    previous if set again. Calling any of those functions will trigger a GUI
    redraw for all markets in that group in the next tick.

    When an item is bought from the market, it will raise an event you can
    listen to: Retailer.events.on_market_purchase. Items can be registered
    with different types. By default the type is 'item', which will insert the
    item(s) bought into the player's inventory. Anything else will merely
    remove the coins and trigger the event. You can listen to this event and do
    whatever custom handling you want.

    Items support the following structure:
    {
        name: the (raw) item inserted in inventory, does nothing when type is not item
        name_label: the name shown in the GUI. If omitted and a prototype exists for 'name', it will use that LocalisedString
        sprite: a custom sprite, will use 'item/<name>' if omitted
        price: the price of an item, supports floats (0.95 for example)
        description: an additional description displayed in the tooltip
        disabled: whether or not the item should be disabled by default
        disabled_reason: the reason the item is disabled
    }
]]

require 'utils.table'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.task'
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
    on_market_purchase = Event.generate_event_name('on_market_purchase'),
}

Retailer.item_types = {
    --- expects an array of item prototypes that can be inserted directly via
    --- player.insert() called 'items' in the item prototype.
    item_package = 'item_package',
}

local market_gui_close_distance_squared = 6 * 6 + 6 * 6
local do_update_market_gui -- token

---Global storage
---Markets are indexed by the position "x,y" and contains the group it belongs to
---Items are indexed by the group name and is a list indexed by the item name and contains the prices per item
---players_in_market_view is a list of {position, group_name} data
local memory = {
    id = 0,
    markets = {},
    items = {},
    group_label = {},
    players_in_market_view = {},
    market_gui_refresh_scheduled = {},
    limited_items = {},
}

Global.register(memory, function (tbl)
    memory = tbl
end)

local function schedule_market_gui_refresh(group_name)
    if memory.market_gui_refresh_scheduled[group_name] then
        -- already scheduled
        return
    end

    set_timeout_in_ticks(1, do_update_market_gui, {group_name = group_name})
    memory.market_gui_refresh_scheduled[group_name] = true
end

---Generates a unique identifier for a market group name, as alternative for a custom name.
function Retailer.generate_group_id()
    local id = memory.id + 1
    memory.id = id
    return 'market-' .. id
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
---@param market_group string
function Retailer.get_items(market_group)
    return memory.items[market_group] or {}
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

---Returns the remaining market group item limit or -1 if there is none for a given player.
---@param market_group string
---@param item_name string
---@param player_index number
function Retailer.get_player_item_limit(market_group, item_name, player_index)
    local item = Retailer.get_items(market_group)[item_name]

    if not item then
        Debug.print({message = 'Item not registered in the Retailer', data = {
            market_group = market_group,
            item_name = item_name,
        }})
        return -1
    end

    return memory.limited_items[market_group][item_name][player_index] or item.player_limit
end

---Returns the configured market group item limit or -1 if there is none.
---@param market_group string
---@param item_name string
function Retailer.get_item_limit(market_group, item_name)
    local item = Retailer.get_items(market_group)[item_name]

    if not item then
        Debug.print({message = 'Item not registered in the Retailer', data = {
            market_group = market_group,
            item_name = item_name,
        }})
        return -1
    end

    return item.player_limit
end

---sets the configured market group item limit for a given player
---@param market_group string
---@param item_name string
---@param player_index number
---@param new_limit number
function Retailer.set_player_item_limit(market_group, item_name, player_index, new_limit)
    if new_limit < 0 then
        Debug.print({message = 'Cannot set a negative item limit', data = {
            market_group = market_group,
            item_name = item_name,
            new_limit = new_limit,
        }})
        return
    end
    local item = Retailer.get_items(market_group)[item_name]

    if not item then
        Debug.print({message = 'Item not registered in the Retailer', data = {
            market_group = market_group,
            item_name = item_name,
        }})
        return -1
    end

    if new_limit > item.player_limit then
        Debug.print({message = 'Cannot set an item limit higher than the item prototype defined', data = {
            market_group = market_group,
            item_name = item_name,
            new_limit = new_limit,
        }})
        new_limit = item.player_limit
    end
    memory.limited_items[market_group][item_name][player_index] = new_limit
end

local function redraw_market_items(data)
    local grid = data.grid

    Gui.clear(grid)

    local count = data.count
    local market_items = data.market_items
    local player_index = data.player_index
    local player_coins = Game.get_player_by_index(player_index).get_item_count('coin')

    if size(market_items) == 0 then
        grid.add({type = 'label', caption = 'No items available at this time'})
        return
    end

    local limited_items = memory.limited_items[data.market_group]

    for i, item in pairs(market_items) do
        local has_stack_limit = item.stack_limit ~= -1
        local stack_limit = has_stack_limit and item.stack_limit or count
        local stack_count = has_stack_limit and stack_limit < count and item.stack_limit or count
        local player_limit = item.player_limit
        local has_player_limit = player_limit ~= -1

        if has_player_limit then
            local item_name = item.name
            player_limit = limited_items[item_name][player_index]

            if player_limit == nil then
                -- no limit set yet
                player_limit = item.player_limit
                limited_items[item_name][player_index] = item.player_limit
            end

            if player_limit < stack_count then
                -- ensure the stack count is never higher than the item limit for the player
                stack_count = player_limit
            end
        end

        local player_bought_max_total = has_player_limit and stack_count == 0
        local price = item.price
        local tooltip = {'', item.name_label}
        local description = item.description
        local total_price = ceil(price * stack_count)
        local disabled = item.disabled == true
        local message

        if total_price == 0 and player_limit == 0 then
            message = 'SOLD!'
        elseif total_price == 0 then
            message = 'FREE!'
        elseif total_price == 1 then
            message = '1 coin'
        else
            message = total_price .. ' coins'
        end

        local missing_coins = total_price - player_coins
        local is_missing_coins = missing_coins > 0

        if price ~= 0 then
            insert(tooltip, format('\nprice: %.2f', price))
        end

        if description then
            insert(tooltip, '\n')
            insert(tooltip, item.description)
        end

        if disabled then
            insert(tooltip, '\n\n' .. (item.disabled_reason or 'Not available'))
        elseif is_missing_coins then
            insert(tooltip, '\n\n' .. format('Missing %s coins to buy %s', missing_coins, stack_count))
        end

        if has_player_limit then
            insert(tooltip, '\n\n' .. format('You have bought this item %s out of %s times', item.player_limit - player_limit, item.player_limit))
        end

        local button = grid.add({type = 'flow'}).add({
            type = 'sprite-button',
            name = item_button_name,
            sprite = item.sprite,
            number = stack_count,
            tooltip = tooltip,
        })
        button.style = 'slot_button'

        Gui.set_data(button, {index = i, data = data, stack_count = stack_count})

        local label = grid.add({type = 'label', caption = message})
        local label_style = label.style
        label_style.width = 93
        label_style.height = 32
        label_style.font = 'default-bold'
        label_style.vertical_align = 'center'

        if disabled or player_bought_max_total then
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
        market_group = group_name,
        player_index = player.index,
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
---@param position <table> Position
local function get_market_group_name(position)
    return memory.markets[(position.x or position[1]) .. ',' .. (position.y or position[2])]
end

---Sets the group name for a market at a given position.
---@param position <table> Position
---@param group_name <string>
local function set_market_group_name(position, group_name)
    memory.markets[(position.x or position[1]) .. ',' .. (position.y or position[2])] = group_name
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
    local stack_count = button_data.stack_count

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

    local cost = ceil(price * stack_count)
    local coin_count = player.get_item_count('coin')

    if cost > coin_count then
        player.print('Insufficient coins')
        return
    end

    local market_group = data.market_group
    if item.player_limit ~= -1 then
        local limited_item = memory.limited_items[market_group][name]
        limited_item[player.index] = limited_item[player.index] - stack_count
    end

    if item.type == 'item' then
        local inserted = player.insert({name = name, count = stack_count})
        if inserted < stack_count then
            player.print('Insufficient inventory space')
            if inserted > 0 then
                player.remove_item({name = name, count = inserted})
            end
            return
        end
    end

    if cost > 0 then
        player.remove_item({name = 'coin', count = cost})
    end

    redraw_market_items(data)
    PlayerStats.change_coin_spent(player.index, cost)
    do_coin_label(coin_count - cost, data.coin_label)

    raise_event(Retailer.events.on_market_purchase, {
        item = item,
        count = stack_count,
        player = player,
        group_name = market_group,
    })
end)

---Add a market to the group_name retailer.
---@param group_name string
---@param market_entity LuaEntity
function Retailer.add_market(group_name, market_entity)
    set_market_group_name(market_entity.position, group_name)
end

---Returns the group name of the market, nil if not registered.
---@param market_entity LuaEntity
function Retailer.get_market_group_name(market_entity)
    return get_market_group_name(market_entity.position)
end

---Sets an item for all the group_name markets.
---@param group_name string
---@param prototype table with item name and price
function Retailer.set_item(group_name, prototype)
    if not memory.items[group_name] then
        memory.items[group_name] = {}
    end
    if not memory.limited_items[group_name] then
        memory.limited_items[group_name] = {}
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

    if not prototype.stack_limit then
        prototype.stack_limit = -1
    end

    if not prototype.player_limit then
        prototype.player_limit = -1
    end

    memory.items[group_name][item_name] = prototype
    memory.limited_items[group_name][item_name] = {}

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

Event.add(Retailer.events.on_market_purchase, function (event)
    local package = event.item
    if package.type ~= Retailer.item_types.item_package then
        return
    end

    local player_insert = event.player.insert
    for _, item in pairs(package.items) do
        item.count = item.count * event.count
        player_insert(item)
    end
end)

return Retailer
