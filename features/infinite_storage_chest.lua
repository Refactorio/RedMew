local Module = {}

local Event = require 'utils.event'
local Token = require 'utils.token'
local Gui = require 'utils.gui'
local Task = require 'utils.task'
local Global = require 'utils.global'
local Game = require 'utils.game'

local format = string.format

local chests = {}
local chests_next = {}
local config = global.config.infinite_storage_chest


Global.register(
    {chests = chests, chests_next = chests_next},
    function(tbl)
        chests = tbl.chests
        chests_next = tbl.chests_next
    end
)

local chest_gui_frame_name = Gui.uid_name()
local chest_content_table_name = Gui.uid_name()

function Module.create_chest(surface, position, storage)
    local entity = surface.create_entity {name = 'infinity-chest', position = position, force = 'player'}
    chests[entity.unit_number] = {entity = entity, storage = storage}
    return entity
end

local function built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid or entity.name ~= 'infinity-chest' then
        return
    end

    entity.active = false

    chests[entity.unit_number] = {entity = entity, storage = {}}
end

local function get_stack_size(name)
    local proto = game.item_prototypes[name]
    if not proto then
        log('item prototype ' .. name .. ' not found')
        return 1
    end

    return proto.stack_size
end

local function do_item(name, count, inv, storage)
    local size = get_stack_size(name)
    local diff = count - size

    if diff == 0 then
        return
    end

    local new_amount = 0

    if diff > 0 then
        inv.remove({name = name, count = diff})
        local prev = storage[name] or 0
        new_amount = prev + diff
    elseif diff < 0 then
        local prev = storage[name]
        if not prev then
            return
        end

        diff = math.min(prev, -diff)
        local inserted = inv.insert({name = name, count = diff})
        new_amount = prev - inserted
    end

    if new_amount == 0 then
        storage[name] = nil
    else
        storage[name] = new_amount
    end
end

local function tick()
    local chest_id, chest_data = next(chests, chests_next[1])

    chests_next[1] = chest_id

    if not chest_id then
        return
    end

    local entity = chest_data.entity
    if not entity or not entity.valid then
        chests[chest_id] = nil
    else
        local storage = chest_data.storage
        local inv = entity.get_inventory(1) --defines.inventory.chest
        local contents = inv.get_contents()

        for name, count in pairs(contents) do
            do_item(name, count, inv, storage)
        end

        for name, _ in pairs(storage) do
            if not contents[name] then
                do_item(name, 0, inv, storage)
            end
        end
    end
end

local function create_chest_gui_content(frame, player, chest)
    local storage = chest.storage
    local inv = chest.entity.get_inventory(1).get_contents()

    local grid = frame[chest_content_table_name]

    if grid then
        grid.clear()
    else
        grid = frame.add {type = 'table', name = chest_content_table_name, column_count = 10, style = 'slot_table'}
    end

    for name, count in pairs(storage) do
        local number = count + (inv[name] or 0)
        grid.add {
            type = 'sprite-button',
            sprite = 'item/' .. name,
            number = number,
            tooltip = name,
            --style = 'slot_button'
            enabled = false
        }
    end

    for name, count in pairs(inv) do
        if not storage[name] then
            grid.add {
                type = 'sprite-button',
                sprite = 'item/' .. name,
                number = count,
                tooltip = name,
                --style = 'slot_button'
                enabled = false
            }
        end
    end

    player.opened = frame
end

local chest_gui_content_callback
chest_gui_content_callback =
    Token.register(
    function(data)
        local player = data.player

        if not player or not player.valid then
            return
        end

        local opened = data.opened
        if not opened or not opened.valid then
            return
        end

        local entity = data.chest.entity
        if not entity.valid then
            player.opened = nil
            opened.destroy()
            return
        end

        if not player.connected then
            player.opened = nil
            opened.destroy()
            return
        end

        create_chest_gui_content(opened, player, data.chest)

        Task.set_timeout_in_ticks(60, chest_gui_content_callback, data)
    end
)

local function gui_opened(event)
    if not event.gui_type == defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= 'infinity-chest' then
        return
    end

    local chest = chests[entity.unit_number]

    if not chest then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local frame =
        player.gui.center.add {
        type = 'frame',
        name = chest_gui_frame_name,
        caption = 'Infinite Storage Chest',
        direction = 'vertical'
    }

    local text =
        frame.add {
        type = 'label',
        caption = format('This chest stores unlimited quantity of items (up to 48 different item types).\nThe chest is best used with an inserter to add / remove items.\nIf the chest is mined or destroyed the items are lost.\nYou can buy the chest at the market for %s coins.', config.cost)
    }
    text.style.single_line = false

    local content_header = frame.add {type = 'label', caption = 'Content'}
    content_header.style.font = 'default-listbox'

    create_chest_gui_content(frame, player, chest)

    Task.set_timeout_in_ticks(60, chest_gui_content_callback, {player = player, chest = chest, opened = frame})
end

Event.add(defines.events.on_built_entity, built_entity)
Event.add(defines.events.on_robot_built_entity, built_entity)
Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_gui_opened, gui_opened)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = Game.get_player_by_index(event.player_index or 0)

        if not player or not player.valid then
            return
        end

        local element = player.gui.center

        if element and element.valid then
            element = element[chest_gui_frame_name]
            if element and element.valid then
                element.destroy()
            end
        end
    end
)

Gui.on_custom_close(
    chest_gui_frame_name,
    function(event)
        event.element.destroy()
    end
)

local market_items = require 'resources.market_items'
table.insert(
    market_items,
    {
        price = config.cost,
        name = 'infinity-chest',
        description = 'Stores unlimited quantity of items for up to 48 different item types'
    }
)
return Module
