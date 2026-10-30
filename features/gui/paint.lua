local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'

local config = storage.config.paint
local default_fallback_hidden_tile = 'dirt-6'

local brush_tools = {
    ['refined-concrete'] = true,
    ['refined-hazard-concrete'] = true,
}

local valid_filters = {
    ['acid-refined-concrete']   = true,
    ['black-refined-concrete']  = true,
    ['blue-refined-concrete']   = true,
    ['brown-refined-concrete']  = true,
    ['cyan-refined-concrete']   = true,
    ['green-refined-concrete']  = true,
    ['orange-refined-concrete'] = true,
    ['pink-refined-concrete']   = true,
    ['purple-refined-concrete'] = true,
    ['red-refined-concrete']    = true,
    ['yellow-refined-concrete'] = true,
}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local filter_button_name = Gui.uid_name()
local filter_element_name = Gui.uid_name()
local filters_table_name = Gui.uid_name()
local filter_table_close_button_name = Gui.uid_name()

local paint_brushes_by_player = {}

Global.register({
    paint_brushes_by_player = paint_brushes_by_player,
}, function(tbl)
    paint_brushes_by_player = tbl.paint_brushes_by_player
end)

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
        player.insert { name = 'refined-concrete', count = count }
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

    if not Gui.get_panel(player, main_frame_name) then
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
            hidden_tiles[#hidden_tiles + 1] = { position = tile_data.position, name = fallback_tile }
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
        player.insert { name = item_name, count = count }
    end

    if print_no_landfill_message then
        player.print({ 'paint.no_place_landfill' })
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
            hidden_tiles[#hidden_tiles + 1] = { position = tile_data.position, name = fallback_tile }
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

    local b = Gui.add_top_element(player, {
        name = main_button_name,
        type = 'sprite-button',
        sprite = 'item/refined-hazard-concrete',
        tooltip = { 'paint.tooltip' },
        auto_toggle = true,
    })
    b.style.padding = 2
end

local function player_removed(event)
    paint_brushes_by_player[event.player_index] = nil
end

local function draw_filters_table(event)
    if event.player.gui.screen[filters_table_name] then
        return
    end

    local frame, title_close_button = Gui.add_window(event.player, {
        name = filters_table_name,
        caption = { 'paint.palette' },
        close_button_name = filter_table_close_button_name,
    })
    Gui.set_data(title_close_button, frame)

    local inner = frame.add { type = 'frame', style = 'inside_deep_frame' }.add { type = 'frame', style = 'filter_frame' }.add { type = 'scroll-pane', style = 'deep_slots_scroll_pane' }

    Gui.set_style(inner.parent, { natural_height = 0 })

    local t = inner.add { type = 'table', column_count = 6, style = 'filter_slot_table' }
    Gui.set_style(t, { bottom_padding = 8 })

    for tile_name, _ in pairs(valid_filters) do
        local flow = t.add { type = 'flow' }
        local button = flow.add {
            type = 'sprite-button',
            name = filter_element_name,
            sprite = 'tile/' .. tile_name,
            tooltip = get_tile_localised_name(tile_name),
        }
        Gui.set_data(button, { frame = frame, tile_name = tile_name })
        button.style = 'slot_button'
    end

    event.player.opened = frame

    Gui.set_data(frame, event.element)
end

-- Shows the player's brush tile in the brush's slot and names it beside it, or an empty slot
-- asking for one. Its tooltip says a right click clears it.
local function show_brush(brush, tile_name)
    brush.sprite = tile_name and 'tile/' .. tile_name or nil
    local caption = tile_name and get_tile_localised_name(tile_name) or { 'paint.select_brush' }
    brush.tooltip = tile_name and { 'paint.brush_tooltip', caption } or caption
    Gui.get_data(brush).caption = caption
end

local function toggle(event)
    local player = event.player
    local main_frame = Gui.get_panel(player, main_frame_name)

    if main_frame and main_frame.valid then
        Gui.destroy(main_frame)
        local main_button = Gui.get_top_element(player, main_button_name)
        main_button.toggled = false
    else
        local _, inner_frame = Gui.add_panel(player, { name = main_frame_name, caption = { 'paint.frame_name' }, toggle_name = main_button_name })

        local row = inner_frame.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(row, { vertical_align = 'center', horizontal_spacing = 8 })

        local brush = row.add {
            type = 'sprite-button',
            style = 'slot_button_in_shallow_frame',
            name = filter_button_name,
        }
        local label = row.add { type = 'label' }
        Gui.set_data(brush, label)
        show_brush(brush, paint_brushes_by_player[event.player_index])

        -- a wrapping label needs a width of its own
        local instructions = inner_frame.add { type = 'label', caption = { 'paint.instructions' } }
        Gui.set_style(instructions, { single_line = false, width = 260, top_margin = 4 })
    end
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(filter_button_name, function(event)
    if event.button == defines.mouse_button_type.right then
        paint_brushes_by_player[event.player_index] = nil
        show_brush(event.element, nil)
    else
        draw_filters_table(event)
    end
end)

Gui.on_click(filter_element_name, function(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local data = Gui.get_data(element)
    local frame = data.frame
    local tile_name = data.tile_name
    local filter_button = Gui.get_data(frame)

    paint_brushes_by_player[event.player_index] = tile_name
    show_brush(filter_button, tile_name)

    Gui.destroy(frame)
end)

Gui.on_click(filter_table_close_button_name, function(event)
    local frame = Gui.get_data(event.element)
    Gui.destroy(frame)
end)

Gui.on_custom_close(filters_table_name, function(event)
    local element = event.element
    Gui.destroy(element)
end)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_removed, player_removed)
Event.add(defines.events.on_player_built_tile, player_build_tile)
Event.add(defines.events.on_robot_built_tile, robot_built_tile)
