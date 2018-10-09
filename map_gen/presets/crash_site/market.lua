local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Global = require 'utils.global'
local PlayerStats = require 'player_stats'
local Game = require 'utils.game'
local math = require "utils.math"

local Public = {}

local markets = {}

Global.register(
    {markets = markets},
    function(tbl)
        markets = tbl.markets
    end
)

local market_frame_name = Gui.uid_name()
local item_button_name = Gui.uid_name()
local count_slider_name = Gui.uid_name()
local count_text_name = Gui.uid_name()

local function redraw_market_items(data)
    local grid = data.grid

    Gui.clear(grid)

    local count = data.count
    local market_items = data.market_items

    for i, item in ipairs(market_items) do
        local name = item.name
        local price = item.price

        local price_per_item = string.format('%.2f', price)

        local button =
            grid.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = item_button_name,
            sprite = 'item/' .. name,
            number = count,
            tooltip = table.concat {name, '  price: ', price_per_item}
        }
        button.style = 'slot_button'

        Gui.set_data(button, {index = i, data = data})

        local message = math.ceil(price * count)
        if message == 1 then
            message = message .. ' coin'
        else
            message = message .. ' coins'
        end

        local label = grid.add {type = 'label', caption = message}
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

local function draw_market_frame(player, market_items)
    local frame =
        player.gui.center.add {type = 'frame', name = market_frame_name, caption = 'Market', direction = 'vertical'}

    local scroll_pane = frame.add {type = 'scroll-pane'}
    local scroll_style = scroll_pane.style
    scroll_style.maximal_height = 600

    local grid = scroll_pane.add {type = 'table', column_count = 10}

    local data = {
        grid = grid,
        count = 1,
        market_items = market_items
    }

    redraw_market_items(data)

    local coin_label = frame.add {type = 'label'}
    do_coin_label(player, coin_label)
    coin_label.style.font = 'default-bold'
    data.coin_label = coin_label

    local count_flow = frame.add {type = 'flow'}

    local count_slider =
        count_flow.add {type = 'slider', name = count_slider_name, minimum_value = 1, maximum_value = 7, value = 1}
    local count_text = count_flow.add {type = 'text-box', name = count_text_name, text = '1'}

    count_slider.style.width = 100
    count_text.style.width = 60

    local quantity_label = count_flow.add {type = 'label', caption = 'Quantity'}
    quantity_label.style.font = 'default-bold'

    data.slider = count_slider
    data.text = count_text

    Gui.set_data(count_slider, data)
    Gui.set_data(count_text, data)

    return frame
end

local function gui_opened(event)
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

    local pos = entity.position
    local market_data = markets[pos.x .. ',' .. pos.y]
    if not market_data then
        return
    end

    local frame = draw_market_frame(player, market_data)

    player.opened = frame
end

function Public.add_market(position, data)
    markets[position.x .. ',' .. position.y] = data
end

Event.add(defines.events.on_gui_opened, gui_opened)

Gui.on_custom_close(
    market_frame_name,
    function(event)
        local element = event.element
        Gui.destroy(element)
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
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
    end
)

Gui.on_value_changed(
    count_slider_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)

        local value = math.floor(element.slider_value)
        local count
        if value % 2 == 0 then
            count = 10 ^ (value * 0.5) * 0.5
        else
            count = 10 ^ ((value - 1) * 0.5)
        end

        data.count = count
        data.text.text = count

        redraw_market_items(data)
    end
)

Gui.on_text_changed(
    count_text_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)

        local count = tonumber(element.text)

        if count then
            count = math.floor(count)
            count = math.clamp(count, 1, 1000)
            data.count = count
            data.text.text = count
        else
            data.count = 1
        end

        redraw_market_items(data)
    end
)

Gui.on_click(
    item_button_name,
    function(event)
        local player = event.player
        local element = event.element
        local button_data = Gui.get_data(element)
        local data = button_data.data

        local item = data.market_items[button_data.index]

        local name = item.name
        local price = item.price
        local count = data.count

        local cost = math.ceil(price * count)
        local coin_count = player.get_item_count('coin')

        if cost > coin_count then
            player.print('Insufficient coins')
        else
            local inserted = player.insert {name = name, count = count}
            if inserted < count then
                player.print('Insufficient inventory space')
                if inserted > 0 then
                    player.remove_item {name = name, count = inserted}
                end
            else
                player.remove_item {name = 'coin', count = cost}
                do_coin_label(player, data.coin_label)
                PlayerStats.change_coin_spent(player.index, cost)
            end
        end
    end
)

return Public
