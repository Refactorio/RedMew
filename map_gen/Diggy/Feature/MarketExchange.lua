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
local Game = require 'utils.game'
local insert = table.insert
local force_control = require 'features.force_control'
local max = math.max
local utils = require 'utils.utils'
local prefix = '## - '

-- this
local MarketExchange = {}

local config = {}
local diggy_market

--Unused?
local on_market_timeout_finished = Token.register(function(params)
    Template.market(params.surface, params.position, params.player_force, {})
end)

--NEEDS CONVERTING
--Handles the updating of market items when unlocked
function MarketExchange.update_market_contents(market, force)
    local add_market_item
    local item_unlocked = false
            
    for _, unlockable in pairs(config.unlockables) do
        local is_in_range = force_control.get_force_data(force).current_level == unlockable.level

        -- only add the item to the market if it's between the old and new stone range
        if (is_in_range and unlockable.type == 'market') then
            add_market_item = add_market_item or market.add_market_item

            local name = unlockable.prototype.name
            local price = unlockable.prototype.price
            if type(price) == 'number' then
                add_market_item({
                    price = {{config.currency_item, price}},
                    offer = {type = 'give-item', item = name, count = 1}
                })
            elseif type(price) == 'table' then
                add_market_item({
                    price = price,
                    offer = {type = 'give-item', item = name, count = 1}
                })
            end
            item_unlocked = true

        end
    end

    --MarketExchange.update_gui()
end

local function redraw_title(data)
    local force_data = force_control.get_force_data('player')
    data.frame.caption = utils.comma_value(force_data.total_experience) .. ' total experience earned!'
end

--Unused?
local function get_data(unlocks, stone, type)
    local result = {}

    for _, data in pairs(unlocks) do
        if data.level == stone and data.type == type then
            insert(result, data)
        end
    end

    return result
end

local tag_label_stone = Gui.uid_name()
local tag_label_buff = Gui.uid_name()
local tag_label_item = Gui.uid_name()

local function apply_heading_style(style, width)
    style.font = 'default-bold'
    style.width = width
end

local function redraw_heading(data, header)
    local head_condition = (header == 1)
    local frame = (head_condition) and data.market_list_heading or data.buff_list_heading
    local header_caption = (head_condition) and 'Reward Item' or 'Reward Buff'
    Gui.clear(frame)

    local heading_table = frame.add({type = 'table', column_count = 2})
    apply_heading_style(heading_table.add({type = 'label', name = tag_label_stone, caption = 'Requirement'}).style, 100)
    apply_heading_style(heading_table.add({type = 'label', name = tag_label_buff, caption = header_caption}).style, 220)
end

local function redraw_progressbar(data)
    local force_data = force_control.get_force_data('player')
    local flow = data.market_progressbars
    Gui.clear(flow)

    apply_heading_style(flow.add({type = 'label', tooltip = 'Currently at level: ' .. force_data.current_level .. '\nNext level at: ' .. utils.comma_value(force_data.experience_level_up_cap) ..'\nRemaining stone: ' .. utils.comma_value(force_data.experience_level_up_cap - force_data.current_experience), name = 'Diggy.MarketExchange.Frame.Progress.Level', caption = 'Progress to next level:'}).style)
    local level_progressbar = flow.add({type = 'progressbar', tooltip = force_data.experience_percentage .. '% stone to next level'})
    level_progressbar.style.width = 350
    level_progressbar.value = force_data.experience_percentage/100
end

local function redraw_table(data)
    local market_scroll_pane = data.market_scroll_pane
    Gui.clear(market_scroll_pane)

    local buffs = {}
    local items = {}
    local last_stone = 0
    local number_of_rows = 0
    local row = {}

    -- create the progress bars in the window
    redraw_progressbar(data)

    -- create table headings
    redraw_heading(data, 1)

    -- create table
    for i = 1, #config.unlockables do
        if config.unlockables[i].level ~= last_stone then

            -- get items and buffs for each stone value
            items = get_data(config.unlockables, config.unlockables[i].level, 'market')

            -- get number of rows
            number_of_rows = max(#buffs, #items)

            -- loop through buffs and items for number of rows
            for j = 1, number_of_rows do
                local result = {}
                local item = items[j]
                local level = item.level

                -- 1st column
                result[1] = level
                -- 3rd column
                if items[j] ~= nil then
                    result[3] = '+ ' .. item.prototype.name
                else
                    result[3] = ''
                end
                -- indicator to stop print stone number
                if j > 1 then
                    result[4] = true
                else
                    result[4] = false
                end
                -- indicator to draw horizontal line
                if j == number_of_rows then
                    result[5] = true
                else
                    result[5] = false
                end

                insert(row, result)
            end
        end

        -- save lastStone
        last_stone = config.unlockables[i].level
    end

    -- print table
    for _, unlockable in pairs(row) do
        local is_unlocked = unlockable[1] <= force_control.get_force_data('player').current_level
        local list = market_scroll_pane.add {type = 'table', column_count = 2 }

        list.style.horizontal_spacing = 16

        local caption = ''
        if unlockable[4] ~= true then
            caption = 'Level ' .. unlockable[1]
        else
            caption = ''
        end
        local tag_stone = list.add {type = 'label', name = tag_label_stone, caption = caption}
        tag_stone.style.minimal_width = 100

        local tag_items = list.add {type = 'label', name = tag_label_item, caption = unlockable[3]}
        tag_items.style.minimal_width = 220

        -- draw horizontal line
        if unlockable[5] == true then
            list.draw_horizontal_line_after_headers = true
        end

        if (is_unlocked) then
            tag_stone.style.font_color = {r = 1, g = 1, b = 1 }
            tag_items.style.font_color = {r = 1, g = 1, b = 1 }
        else
            tag_stone.style.font_color = {r = 0.5, g = 0.5, b = 0.5 }
            tag_items.style.font_color = {r = 0.5, g = 0.5, b = 0.5 }
        end
    end
end

local function redraw_buff(data) --! Almost equals to the redraw_table() function !
    local buff_scroll_pane = data.buff_scroll_pane
    Gui.clear(buff_scroll_pane)

    local buffs = require 'map_gen.Diggy.Feature.Experience'.get_buffs()
    local row = {}
    local i = 0
    for k, v in pairs(buffs) do
        i = i + 1
        local result = {}

        -- 1st column
        result[1] = 'All levels'

        -- 2nd column
        if k == 'mining_speed' then
            result[2] = '+ '.. v.value .. '% mining speed'
        elseif k == 'inventory_slot' then
            if v.value > 1 then
                result[2] = '+ '.. v.value .. ' inventory slots'
            else
                result[2] = '+ '.. v.value .. ' inventory slot'
            end
        elseif k == 'health_bonus' then
            result[2] = '+ '.. v.value .. ' max health'
        else
            result[2] = 'Description missing: unknown buff. Please contact admin'
        end
        
        -- 3rd column
        result[3] = ''
        -- indicator to stop print level number
        if i > 1 then
            result[4] = true
        else
            result[4] = false
        end
        insert(row, result)
    end    
    for _, unlockable in pairs(row) do
        local list = buff_scroll_pane.add {type = 'table', column_count = 2 }
        list.style.horizontal_spacing = 16

        local caption = ''
        if unlockable[4] ~= true then
            caption = unlockable[1]
        else
            caption = ''
        end
        local tag_stone = list.add {type = 'label', name = buff_tag_label_stone, caption = caption}
        tag_stone.style.minimal_width = 100

        local tag_buffs = list.add {type = 'label', name = buff_tag_label_buff, caption = unlockable[2]}
        tag_buffs.style.minimal_width = 220

        tag_stone.style.font_color = {r = 1, g = 1, b = 1 }
        tag_buffs.style.font_color = {r = 1, g = 1, b = 1 }
    end
end

function MarketExchange.get_market()
    return diggy_market
end

local function on_placed_entity(event)
    local market = event.entity
    if 'market' ~= market.name then
        return
    end
    diggy_market = market
end

function MarketExchange.get_extra_map_info(config)
    return 'Market Exchange, come make a deal at the foreman\'s shop'
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left['Diggy.MarketExchange.Frame']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_title(data)
        redraw_progressbar(data)
        redraw_table(data)
        return
    end

    frame = left.add({name = 'Diggy.MarketExchange.Frame', type = 'frame', direction = 'vertical'})

    local market_progressbars = frame.add({type = 'flow', direction = 'vertical'})
    local market_list_heading = frame.add({type = 'flow', direction = 'horizontal'})

    local market_scroll_pane = frame.add({type = 'scroll-pane'})
    market_scroll_pane.style.maximal_height = 300
    
    local buff_list_heading = frame.add({type = 'flow', direction = 'horizontal'})
    
    local buff_scroll_pane = frame.add({type = 'scroll-pane'})
    buff_scroll_pane.style.maximal_height = 100

    frame.add({ type = 'button', name = 'Diggy.MarketExchange.Button', caption = 'Close'})

    local data = {
        frame = frame,
        market_progressbars = market_progressbars,
        market_list_heading = market_list_heading,
        market_scroll_pane = market_scroll_pane,
        buff_list_heading = buff_list_heading,
        buff_scroll_pane = buff_scroll_pane,
    }

    redraw_title(data)
    redraw_table(data)
    
    redraw_heading(data, 2)
    redraw_buff(data)

    Gui.set_data(frame, data)

end

local function on_player_created(event)
    Game.get_player_by_index(event.player_index).gui.top.add({
        name = 'Diggy.MarketExchange.Button',
        type = 'sprite-button',
        sprite = 'entity/market',
    })
end

Gui.on_click('Diggy.MarketExchange.Button', toggle)
Gui.on_custom_close('Diggy.MarketExchange.Frame', function (event)
    event.element.destroy()
end)

function MarketExchange.update_gui()
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left['Diggy.MarketExchange.Frame']

        if frame and frame.valid then
            local data = {player = p, trigger = 'update_gui'}
            toggle(data)
        end
    end
end

function MarketExchange.on_init()
    Task.set_timeout_in_ticks(50, on_market_timeout_finished, {
        surface = game.surfaces.nauvis,
        position = config.market_spawn_position,
        player_force = game.forces.player,
    })
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
    Event.on_nth_tick(61, MarketExchange.update_gui)
end

return MarketExchange
