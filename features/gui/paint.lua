local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'
local Global = require 'utils.global'

local brush_tool = 'refined-hazard-concrete'

local valid_filters = {
    'dirt-1',
    'dirt-2',
    'dirt-3',
    'dirt-4',
    'dirt-5',
    'dirt-6',
    'dirt-7',
    'dry-dirt',
    'grass-1',
    'grass-2',
    'grass-3',
    'grass-4',
    'lab-dark-1',
    'lab-dark-2',
    'lab-white',
    'red-desert-0',
    'red-desert-1',
    'red-desert-2',
    'red-desert-3',
    'sand-1',
    'sand-2',
    'sand-3',
    'tutorial-grid'
}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local filter_button_name = Gui.uid_name()
local filter_clear_name = Gui.uid_name()
local filter_element_name = Gui.uid_name()
local filters_table_name = Gui.uid_name()
local filter_table_close_button_name = Gui.uid_name()

local paint_brushes_by_player = {}

Global.register(
    {
        paint_brushes_by_player = paint_brushes_by_player
    },
    function(tbl)
        paint_brushes_by_player = tbl.paint_brushes_by_player
    end
)

local function player_build_tile(event)
    local item = event.item
    if not item then
        return
    end

    if item.name ~= brush_tool then
        return
    end

    local replace_tile = paint_brushes_by_player[event.player_index]
    if not replace_tile then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player.gui.left[main_frame_name] then
        return
    end

    local tiles = event.tiles
    local count = 0
    for i = 1, #tiles do
        local tile_data = tiles[i]
        tile_data.name = replace_tile

        if tile_data.old_tile.name == replace_tile then
            count = count + 1
        end
    end

    game.surfaces[event.surface_index].set_tiles(tiles)

    if count > 0 then
        player.insert {name = brush_tool, count = count}
    end
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'utility/spray_icon'}
end

local function draw_filters_table(event)
    local center = event.player.gui.center

    if center[filters_table_name] then
        return
    end

    local frame = center.add {type = 'frame', name = filters_table_name, direction = 'vertical', caption = 'Palette'}

    local t = frame.add {type = 'table', column_count = 10}
    t.style.horizontal_spacing = 0
    t.style.vertical_spacing = 0

    for _, v in ipairs(valid_filters) do
        local flow = t.add {type = 'flow'}
        local b = flow.add {type = 'sprite-button', name = filter_element_name, sprite = 'tile/' .. v, tooltip = v}
        Gui.set_data(b, frame)
        b.style = 'slot_button'
    end

    local flow = frame.add {type = 'flow'}

    local close = flow.add {type = 'button', name = filter_table_close_button_name, caption = 'Close'}
    Gui.set_data(close, frame)

    event.player.opened = frame

    Gui.set_data(frame, event.element)
end

local function toggle(event)
    local left = event.player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        Gui.remove_data_recursively(main_frame)
        main_frame.destroy()
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Paint Brush'
        }

        local tooltip = paint_brushes_by_player[event.player_index] or ''

        local brush =
            main_frame.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = filter_button_name,
            tooltip = tooltip,
            sprite = tooltip ~= '' and 'tile/' .. tooltip or nil
        }
        brush.style = 'slot_button'

        local buttons_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

        buttons_flow.add {type = 'button', name = main_button_name, caption = 'Close'}

        local clear_brush = buttons_flow.add {type = 'button', name = filter_clear_name, caption = 'Clear Brush'}
        Gui.set_data(clear_brush, brush)
    end
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    filter_button_name,
    function(event)
        if event.button == defines.mouse_button_type.right then
            paint_brushes_by_player[event.player_index] = nil
            local element = event.element
            element.sprite = 'utility/pump_cannot_connect_icon'
            element.tooltip = ''
        else
            draw_filters_table(event)
        end
    end
)

Gui.on_click(
    filter_clear_name,
    function(event)
        local brush = Gui.get_data(event.element)

        brush.sprite = 'utility/pump_cannot_connect_icon'
        brush.tooltip = ''

        paint_brushes_by_player[event.player_index] = nil
    end
)

Gui.on_click(
    filter_element_name,
    function(event)
        local element = event.element
        local frame = Gui.get_data(element)
        local filter_button = Gui.get_data(frame)

        paint_brushes_by_player[event.player_index] = element.tooltip
        filter_button.sprite = element.sprite
        filter_button.tooltip = element.tooltip

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_click(
    filter_table_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    filters_table_name,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_player_built_tile, player_build_tile)
