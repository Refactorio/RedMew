local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'

local config = storage.config.paint
local default_fallback_hidden_tile = 'dirt-6'

local brush_tools = {
    ['refined-concrete'] = true,
    ['refined-hazard-concrete'] = true
}

local valid_filters = {
    ['acid-refined-concrete'] = true,
    ['black-refined-concrete'] = true,
    ['blue-refined-concrete'] = true,
    ['brown-refined-concrete'] = true,
    ['cyan-refined-concrete'] = true,
    ['green-refined-concrete'] = true,
    ['orange-refined-concrete'] = true,
    ['pink-refined-concrete'] = true,
    ['purple-refined-concrete'] = true,
    ['red-refined-concrete'] = true,
    ['yellow-refined-concrete'] = true
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

local function refund_tiles(player, tiles)
    local count = 0
    local set_hidden_tile = player.surface.set_hidden_tile
    local fallback_tile = config.fallback_hidden_tile or default_fallback_hidden_tile
    for i = 1, #tiles do
        local tile_data = tiles[i]
        if valid_filters[tile_data.old_tile.name] then
            count = count + 1
            set_hidden_tile(tile_data.position, fallback_tile)
        end
    end

    if count > 0 then
        player.insert {name = 'refined-concrete', count = count}
    end
end

local function player_build_tile(event)
    local item = event.item
    if not item then
        return
    end

    local item_name = item.name
    if not brush_tools[item_name] then
        return
    end

    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return
    end

    local surface = game.surfaces[event.surface_index]
    if not surface or not surface.valid then
        return
    end

    local replace_tile = paint_brushes_by_player[player_index]
    if not replace_tile then
        refund_tiles(player, event.tiles)
        return
    end

    if not Gui.get_left_element(player, main_frame_name) then
        refund_tiles(player, event.tiles)
        return
    end

    local get_hidden_tile = surface.get_hidden_tile
    local tile_name = event.tile.name
    local tiles = event.tiles
    local count = 0
    local hidden_tiles = {}
    local prevent_on_landfill = config.prevent_on_landfill
    local print_no_landfill_message = false
    local fallback_tile = config.fallback_hidden_tile or default_fallback_hidden_tile
    for i = 1, #tiles do
        local tile_data = tiles[i]

        local hidden_tile = get_hidden_tile(tile_data.position)
        if prevent_on_landfill and hidden_tile == 'landfill' then
            tile_data.name = tile_name
            print_no_landfill_message = true
            goto continue
        end

        tile_data.name = replace_tile

        if valid_filters[tile_data.old_tile.name] then
            count = count + 1
        end

        if valid_filters[hidden_tile] then
            hidden_tiles[#hidden_tiles + 1] = {position = tile_data.position, name = fallback_tile}
        end

        ::continue::
    end

    surface.set_tiles(tiles)

    local set_hidden_tile = surface.set_hidden_tile
    for i = 1, #hidden_tiles do
        local tile = hidden_tiles[i]
        set_hidden_tile(tile.position, tile.name)
    end

    if count > 0 then
        player.insert {name = item_name, count = count}
    end

    if print_no_landfill_message then
        player.print({'paint.no_place_landfill'})
    end
end

local function robot_built_tile(event)
    local item = event.item
    if not item then
        return
    end

    local item_name = item.name
    if not brush_tools[item_name] then
        return
    end

    local surface = game.surfaces[event.surface_index]
    if not surface or not surface.valid then
        return
    end

    local tiles = event.tiles
    local hidden_tiles = {}
    local fallback_tile = config.fallback_hidden_tile or default_fallback_hidden_tile
    for i = 1, #tiles do
        local tile_data = tiles[i]
        local hidden_tile = surface.get_hidden_tile(tile_data.position)

        if valid_filters[hidden_tile] then
            hidden_tiles[#hidden_tiles + 1] = {position = tile_data.position, name = fallback_tile}
        end
    end

    for i = 1, #hidden_tiles do
        local tile = hidden_tiles[i]
        surface.set_hidden_tile(tile.position, tile.name)
    end
end

local function get_tile_localised_name(tile_name)
    if not tile_name then
        return
    end

    local proto = prototypes.tile[tile_name]
    if proto then
        return proto.localised_name or proto.name
    end
end

local function player_created(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local b = Gui.add_top_element(player,
        {
            name = main_button_name,
            type = 'sprite-button',
            sprite = 'utility/spray_icon',
            tooltip = {'paint.tooltip'},
            auto_toggle = true,
        }
    )
    b.style.padding = 2
end

local function draw_filters_table(event)
    local center = event.player.gui.center

    if center[filters_table_name] then
        return
    end

    local frame =
        center.add {type = 'frame', name = filters_table_name, direction = 'vertical', caption = {'paint.palette'}}

    local t = frame.add {type = 'table', column_count = 6}
    t.style.horizontal_spacing = 0
    t.style.vertical_spacing = 0

    for tile_name, _ in pairs(valid_filters) do
        local flow = t.add {type = 'flow'}
        local button =
            flow.add {
            type = 'sprite-button',
            name = filter_element_name,
            sprite = 'tile/' .. tile_name,
            tooltip = get_tile_localised_name(tile_name)
        }
        Gui.set_data(button, {frame = frame, tile_name = tile_name})
        button.style = 'slot_button'
    end

    local flow = frame.add {type = 'flow'}

    local close_button = Gui.make_close_button(flow, filter_table_close_button_name)
    Gui.set_data(close_button, frame)

    event.player.opened = frame

    Gui.set_data(frame, event.element)
end

local function toggle(event)
    local player = event.player
    local main_frame = Gui.get_left_element(player, main_frame_name)

    if main_frame and main_frame.valid then
        Gui.destroy(main_frame)
        local main_button = Gui.get_top_element(player, main_button_name)
        main_button.toggled = false
    else
        main_frame = Gui.add_left_element(player,  {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = {'paint.frame_name'}
        })

        local top_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

        local tile_name = paint_brushes_by_player[event.player_index]

        local brush =
            top_flow.add({type = 'flow'}).add {
            type = 'sprite-button',
            name = filter_button_name,
            tooltip = get_tile_localised_name(tile_name) or {'paint.select_brush'},
            sprite = tile_name and 'tile/' .. tile_name
        }
        brush.style = 'slot_button'

        local label = top_flow.add {type = 'label', caption = {'paint.instructions'}}
        local label_style = label.style
        label_style.font = 'default-bold'
        label_style.single_line = false
        label_style.left_padding = 10

        local buttons_flow = main_frame.add {type = 'flow', direction = 'horizontal'}

        Gui.make_close_button(buttons_flow, main_button_name)

        local clear_brush =
            buttons_flow.add {type = 'button', name = filter_clear_name, caption = {'paint.clear_brush'}}
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
            element.tooltip = {'paint.select_brush'}
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
        brush.tooltip = {'paint.select_brush'}

        paint_brushes_by_player[event.player_index] = nil
    end
)

Gui.on_click(
    filter_element_name,
    function(event)
        local element = event.element
        if not element or not element.valid then
            return
        end

        local data = Gui.get_data(element)
        local frame = data.frame
        local tile_name = data.tile_name
        local filter_button = Gui.get_data(frame)

        paint_brushes_by_player[event.player_index] = tile_name
        filter_button.sprite = element.sprite
        filter_button.tooltip = element.tooltip

        Gui.destroy(frame)
    end
)

Gui.on_click(
    filter_table_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        Gui.destroy(frame)
    end
)

Gui.on_custom_close(
    filters_table_name,
    function(event)
        local element = event.element
        Gui.destroy(element)
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_built_tile, player_build_tile)
Event.add(defines.events.on_robot_built_tile, robot_built_tile)
