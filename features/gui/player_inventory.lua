local Gui = require 'utils.gui'
local Rank = require 'features.rank_system'
local ENTITIES = prototypes.entity
local ITEMS = prototypes.item
local TILES = prototypes.tile

local Public = {
    main_frame_name = Gui.uid_name(),
    close_button_name = Gui.uid_name(),
}

local function get_sprite_from_name(name)
    if ITEMS[name] then
        return 'item.'..name
    elseif TILES[name] then
        return 'tile.'..name
    elseif ENTITIES[name] then
        return 'entity.'..name
    end
    return 'virtual-signal.signal-deny'
end

local function get_tooltip_from_name(name)
    if ITEMS[name] then
        return ITEMS[name].localised_name
    elseif TILES[name] then
        return TILES[name].localised_name
    elseif ENTITIES[name] then
        return ENTITIES[name].localised_name
    end
    return name
end

Public.get_player_inventory = function(player)
    local results = {}

    for k = 1, player.get_max_inventory_index() do
        local inventory = player.get_inventory(k)
        if (inventory and inventory.valid) then
            for _, stack in pairs(inventory.get_contents()) do
                results[stack.name] = (results[stack.name] or 0) + stack.count
            end
        end
    end

    return results
end

Public.get_main_frame = function(player, selected)
    local frame = player.gui.screen[Public.main_frame_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    frame = player.gui.screen.add {
        type = 'frame',
        name = Public.main_frame_name,
        direction = 'vertical',
    }
    Gui.set_style(frame, { maximal_height = 930 })

    do -- Header
        local header = frame.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(header, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

        local label = header.add { type = 'label', caption = 'Player inventory', style = 'frame_title' }
        label.drag_target = frame

        local dragger = header.add { type = 'empty-widget', style = 'draggable_space_header' }
        dragger.drag_target = frame
        Gui.set_style(dragger, { height = 24, horizontally_stretchable = true })

        local button = header.add {
            type = 'sprite-button',
            name = Public.close_button_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = {'gui.close-instruction'}
        }
        Gui.set_data(button, frame)
    end

    do -- Content
        local inner = frame.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }
        local online = inner
            .add { type = 'frame', style = 'subheader_frame'}
            .add { type = 'label', caption = ('Online: %d/%d'):format(#game.connected_players, #game.players), style = 'subheader_label' }
        Gui.set_style(online.parent, { horizontally_stretchable = true })

        local grid = inner
            .add { type = 'scroll-pane', style = 'naked_scroll_pane' }
            .add { type = 'table', style = 'table_with_selection', column_count = 4 }

        local function make_rank(name)
            local label = grid.add { type = 'label', caption = Rank.get_player_rank_name(name) }
            Gui.set_style(label, { font_color = Rank.get_player_rank_color(name) })
        end

        local function make_status(target)
            grid.add {
                type = 'label',
                caption = target.connected and 'Online' or 'Offline',
                style = target.connected and 'bold_green_label' or 'bold_red_label',
            }
        end

        local function make_inventory(target)
            local list = grid
                .add { type = 'scroll-pane', style = 'naked_scroll_pane' }
                .add { type = 'table', column_count = 10, style = 'filter_slot_table' }
            list.parent.horizontal_scroll_policy = 'never'

            for name, count in pairs(Public.get_player_inventory(target)) do
                list.add{
                    type = 'sprite-button',
                    style = 'slot_button',
                    sprite = get_sprite_from_name(name),
                    tooltip = get_tooltip_from_name(name),
                    number = count,
                }
            end
        end

        grid.add { type = 'label', caption = 'Name' }
        grid.add { type = 'label', caption = 'Rank' }
        grid.add { type = 'label', caption = 'Status' }
        grid.add { type = 'label', caption = 'Inventory' }

        local player_list = selected and { selected } or game.players
        for _, p in pairs(player_list) do
            grid.add { type = 'label', caption = p.name }
            make_rank(p.name)
            make_status(p)
            make_inventory(p)
        end
    end

    frame.force_auto_center()
    player.opened = frame
    return frame
end

Gui.on_click(Public.close_button_name, function(event)
    Gui.destroy(Gui.get_data(event.element))
end)

Gui.on_custom_close(Public.main_frame_name, function(event)
    Gui.destroy(event.element)
end)

return Public
