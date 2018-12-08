local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local PlayerStats = require 'features.player_stats'
local Game = require 'utils.game'
local math = require 'utils.math'
local format = string.format
local concat = table.concat
local clamp = math.clamp
local floor = math.floor
local ceil = math.ceil
local market_frame_name = Gui.uid_name()
local item_button_name = Gui.uid_name()
local count_slider_name = Gui.uid_name()
local count_text_name = Gui.uid_name()

local Retailer = {}

---Global storage
---Markets are indexed by the position "x,y" and contains the group it belongs to
---Items are indexed by the group name and is a list indexed by the item name and contains the prices per item
local memory = {
    markets = {},
    items = {},
}

Global.register({
    memory = memory,
}, function (tbl)
    memory = tbl.memory
end)

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
end

local function redraw_market_items(data)
    local grid = data.grid

    Gui.clear(grid)

    local count = data.count
    local market_items = data.market_items

    for i, item in pairs(market_items) do
        local name = item.name
        local price = item.price

        local price_per_item = format('%.2f', price)

        local button = grid.add({type = 'flow'}).add({
            type = 'sprite-button',
            name = item_button_name,
            sprite = 'item/' .. name,
            number = count,
            tooltip = concat({name, '  price: ', price_per_item})
        })
        button.style = 'slot_button'

        Gui.set_data(button, {index = i, data = data})

        local message = ceil(price * count)
        if message == 1 then
            message = message .. ' coin'
        else
            message = message .. ' coins'
        end

        local label = grid.add({type = 'label', caption = message})
        local label_style = label.style
        label_style.width = 80
        label_style.font = 'default-bold'
    end
end

local function do_coin_label(player, label)
    local coin_count = player.get_item_count('coin')

    if coin_count == 1 then
        label.caption = coin_count .. ' coin available'
    else
        label.caption = coin_count .. ' coins available'
    end
end

local function draw_market_frame(player, group_name)
    local frame = player.gui.center.add({
        type = 'frame',
        name = market_frame_name,
        caption = 'Market',
        direction = 'vertical',
    })

    local scroll_pane = frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.maximal_height = 600

    local grid = scroll_pane.add({type = 'table', column_count = 10})

    local data = {
        grid = grid,
        count = 1,
        market_items = Retailer.get_items(group_name),
    }

    redraw_market_items(data)

    local coin_label = frame.add({type = 'label'})
    do_coin_label(player, coin_label)
    coin_label.style.font = 'default-bold'
    data.coin_label = coin_label

    local count_flow = frame.add({type = 'flow'})

    local count_slider = count_flow.add({
        type = 'slider',
        name = count_slider_name,
        minimum_value = 1,
        maximum_value = 7,
        value = 1,
    })
    local count_text = count_flow.add({
        type = 'text-box',
        name = count_text_name,
        text = '1',
    })

    count_slider.style.width = 100
    count_text.style.width = 60

    count_flow.add({type = 'label', caption = 'Quantity'}).style.font = 'default-bold'

    data.slider = count_slider
    data.text = count_text

    Gui.set_data(count_slider, data)
    Gui.set_data(count_text, data)

    return frame
end

Event.add(defines.events.on_gui_opened, function (event)
    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local position = entity.position
    local group_name = memory.markets[position.x .. ',' .. position.y]
    if not group_name then
        return
    end

    local frame = draw_market_frame(player, group_name)

    player.opened = frame
end)

Gui.on_custom_close(market_frame_name, function(event)
    local element = event.element
    Gui.destroy(element)
end)

Event.add(defines.events.on_player_died, function(event)
    local player = Game.get_player_by_index(event.player_index or 0)

    if not player or not player.valid then
        return
    end

    local element = player.gui.center

    if element and element.valid then
        element = element[market_frame_name]
        if element and element.valid then
            Gui.destroy(element)
        end
    end
end)

Gui.on_value_changed(count_slider_name, function(event)
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

Gui.on_text_changed(count_text_name, function(event)
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

Gui.on_click(item_button_name, function(event)
    local player = event.player
    local element = event.element
    local button_data = Gui.get_data(element)
    local data = button_data.data

    local item = data.market_items[button_data.index]

    local name = item.name
    local price = item.price
    local count = data.count

    local cost = ceil(price * count)
    local coin_count = player.get_item_count('coin')

    if cost > coin_count then
        player.print('Insufficient coins')
        return
    end

    local inserted = player.insert({name = name, count = count})
    if inserted < count then
        player.print('Insufficient inventory space')
        if inserted > 0 then
            player.remove_item({name = name, count = inserted})
        end
        return
    end

    player.remove_item({name = 'coin', count = cost})
    do_coin_label(player, data.coin_label)
    PlayerStats.change_coin_spent(player.index, cost)
end)

---Add a market to the group_name retailer.
---@param group_name string
---@param market_entity LuaEntity
function Retailer.add_market(group_name, market_entity)
    local position = market_entity.position
    memory.markets[position.x .. ',' .. position.y] = group_name
end

---Sets an item for all the group_name markets.
---@param group_name string
---@param prototype table with item name and price
function Retailer.set_item(group_name, prototype)
    if not memory.items[group_name] then
        memory.items[group_name] = {}
    end

    memory.items[group_name][prototype.name] = prototype
end

return Retailer
