-- This feature adds a small HUD for production stats,
-- similar to Factorio built-in "P", but always on screen
-- made by RedRafe
-- ======================================================= --

local config = require 'config'.production_hud
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local table = require 'utils.table'
local math_abs = math.abs
local round_sig = math.round_sig

local Public = {}

local player_settings = {
    --[player.index] = {
    --    precision_index = defines.flow_precision_index.ten_minutes,
    --    items = { 'iron-ore', 'copper-ore' },
    --}
}

Global.register({
    player_settings = player_settings,
}, function(tbl)
    player_settings = tbl.player_settings
end)

local item_p = prototypes.item
local fluid_p = prototypes.fluid
local to_time = {
    [defines.flow_precision_index.five_seconds] = '5s',
    [defines.flow_precision_index.one_minute] = '1m',
    [defines.flow_precision_index.ten_minutes] = '10m',
    [defines.flow_precision_index.one_hour] = '1h',
    [defines.flow_precision_index.ten_hours] = '10h',
    [defines.flow_precision_index.fifty_hours] = '50h',
    [defines.flow_precision_index.two_hundred_fifty_hours] = '250h',
    [defines.flow_precision_index.one_thousand_hours] = '1000h',
}
local si_prefixes = {
    { 'Q', 1e30 }, -- quetta
    { 'R', 1e27 }, -- ronna
    { 'Y', 1e24 }, -- yotta
    { 'Z', 1e21 }, -- zetta
    { 'E', 1e18 }, -- exa
    { 'P', 1e15 }, -- peta
    { 'T', 1e12 }, -- tera
    { 'G', 1e09 }, -- giga
    { 'M', 1e06 }, -- mega
    { 'k', 1e03 }, -- kilo
}

---@param value number
---@return string
local function format_si(value)
    if value == 0 then
        return '0'
    end

    local abs_value = math_abs(round_sig(value, 3))
    for i = #si_prefixes, 1, -1 do
        local suffix = si_prefixes[i]
        if abs_value >= suffix[2] then
            local scaled = value / suffix[2]
            return ('%.2f%s'):format(scaled, suffix[1])
        end
    end

    if value > 100 then
        return ('%d'):format(value)
    elseif value > 10 then
        return ('%.1f'):format(value)
    end
    return ('%.2f'):format(value)
end

-- == GUI =====================================================================

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()
local action_scroll_precision_index = Gui.uid_name()
local action_add_item = Gui.uid_name()
local action_remove_item = Gui.uid_name()

---@param parent LuaGuiElement
---@param items string[]
local function init_hud(parent, items)
    Gui.clear(parent)
    Public.sanitize_player_settings(parent.player_index)

    --- Appending rows
    for _, name in pairs(items) do
        local flow = parent.add { type = 'flow', direction = 'horizontal', name = name }
        flow.add {
            type = 'sprite-button',
            name = action_remove_item,
            sprite = (item_p[name] and 'item.' or 'fluid.') .. name,
            tooltip = {
                'production_hud.item_tooltip',
                { '?', { 'item-name.' .. name }, { 'entity-name.' .. name }, { 'fluid-name.' .. name } },
            },
            tags = { name = name },
        }
        Gui.set_style(flow, { padding = 2, vertical_align = 'center' })
        Gui.add_pusher(flow)

        local vert = flow.add { type = 'flow', direction = 'vertical', name = 'stats' }
        Gui.set_style(vert, { vertical_align = 'center', vertical_spacing = 0, horizontal_align = 'right' })

        for _, info in pairs({
            { name = 'plus', font_color = { 150, 255, 150 }, caption = '---' },
            { name = 'minus', font_color = { 255, 150, 150 }, caption = '---' },
        }) do
            local l = vert.add {
                type = 'label',
                name = info.name,
                caption = info.caption,
            }
            Gui.set_style(l, { font_color = info.font_color, minimal_width = 52, horizontal_align = 'right' })
        end
    end
end

---@param player_index uint
Public.sanitize_player_settings = function(player_index)
    local s = player_settings[player_index]
    if not (s and s.items) then
        return
    end

    for i = #s.items, 1, -1 do
        local name = s.items[i]
        if item_p[name] == nil and fluid_p[name] == nil then
            table.remove(s.items, i)
        end
    end
end

---@param player LuaPlayer
Public.toggle = function(event)
    Public.toggle_main_button(event.player)
end

---@param player LuaPlayer
Public.toggle_main_button = function(player)
    local frame = player.gui.screen[main_frame_name]
    if frame and frame.valid then
        frame.visible = not frame.visible
    else
        Public.get_main_frame(player)
    end
end

---@param player LuaPlayer
Public.get_main_frame = function(player)
    local frame = player.gui.screen[main_frame_name]
    if frame and frame.valid then
        return Public.update_main_frame(player)
    end

    local data = {}
    local settings = player_settings[player.index]

    frame = player.gui.screen.add {
        type = 'frame',
        name = main_frame_name,
        direction = 'vertical',
    }
    Gui.set_style(frame, { padding = 4, width = 256 })

    do -- header
        local flow, label, button
        flow = frame.add { type = 'flow', direction = 'horizontal' }
        flow.drag_target = frame

        label = flow.add({ type = 'label', style = 'subheader_caption_label', caption = 'Production' })
        label.drag_target = frame
        Gui.set_style(label, { left_padding = 0 })

        Gui.add_pusher(flow).drag_target = frame

        --- Display time
        button = flow.add {
            type = 'sprite-button',
            name = action_scroll_precision_index,
            caption = to_time[settings.precision_index],
            style = 'frame_button',
        }
        data.action_scroll_precision_index = button
        Gui.set_style(button, { height = 24, width = 48, font_color = { 255, 255, 255 } })
        Gui.set_data(button, data)

        --- Add new
        button = flow.add {
            type = 'choose-elem-button',
            name = action_add_item,
            style = 'frame_button',
            tooltip = { 'production_hud.new_item_tooltip' },
            elem_type = 'signal',
            signal = { type = 'virtual', name = 'shape-cross' },
        }
        Gui.set_style(button, { size = 24, font_color = { 255, 255, 255 } })
        Gui.set_data(button, data)
    end

    do -- body
        local panel = frame.add { type = 'frame', style = 'quick_bar_inner_panel' }
        local tbl = panel.add { type = 'table', column_count = 2, draw_horizontal_lines = true }
        data.table = tbl
    end

    Gui.set_data(frame, data)
    Public.update_main_frame(player)
    frame.force_auto_center()
end

---@param player LuaPlayer
Public.update_main_frame = function(player)
    local frame = player.gui.screen[main_frame_name]
    if not (frame and frame.valid and frame.visible) then
        return
    end

    local data = Gui.get_data(frame)
    local tbl = data.table

    local settings = player_settings[player.index]
    if #settings.items ~= table_size(tbl.children) then
        init_hud(tbl, settings.items)
    end

    local item_stats = player.force.get_item_production_statistics(player.physical_surface)
    local fluid_stats = player.force.get_fluid_production_statistics(player.physical_surface)

    for _, name in pairs(settings.items) do
        local children = tbl[name]
        local stats = ((item_p[name] ~= nil) and item_stats or fluid_stats)
        local minus = stats.get_flow_count { name = name, category = 'output', precision_index = settings.precision_index }
        local plus = stats.get_flow_count { name = name, category = 'input', precision_index = settings.precision_index }
        local count = stats.get_input_count(name) - stats.get_output_count(name)

        children.stats.plus.caption = format_si(plus)
        children.stats.minus.caption = format_si(minus)
        children[action_remove_item].number = count
    end
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)
Gui.on_click(main_button_name, Public.toggle)

Gui.on_click(action_scroll_precision_index, function(event)
    local settings = player_settings[event.player_index]
    settings.precision_index = (settings.precision_index + 1) % table_size(defines.flow_precision_index)

    local data = Gui.get_data(event.element)
    data.action_scroll_precision_index.caption = to_time[settings.precision_index]

    Public.update_main_frame(event.player)
end)

Gui.on_elem_changed(action_add_item, function(event)
    local player = event.player
    local element = event.element
    local items = player_settings[player.index].items
    local item = element.elem_value and element.elem_value.name
    element.elem_value = { name = 'shape-cross', type = 'virtual' }

    if not item then
        player.print({ 'production_hud.err_invalid_item' }, { sound_path = 'utility/cannot_build' })
        return
    end

    if item_p[item] == nil and fluid_p[item] == nil then
        player.print({ 'production_hud.err_invalid_item' }, { sound_path = 'utility/cannot_build' })
        return
    end

    if table.contains(items, item) then
        player.print({ 'production_hud.err_item_already_present' }, { sound_path = 'utility/cannot_build' })
        return
    end

    if #items >= config.limit then
        player.print({ 'production_hud.err_limit_reached', config.limit }, { sound_path = 'utility/cannot_build' })
        return
    end

    table.insert(items, item)
    player.play_sound{ path = 'utility/armor_insert' }
    Public.update_main_frame(player)
end)

Gui.on_click(action_remove_item, function(event)
    if event.button ~= defines.mouse_button_type.right then
        return
    end

    table.remove_element(player_settings[event.player_index].items, event.element.tags.name)
    event.player.play_sound{ path = 'utility/armor_remove' }
    Public.update_main_frame(event.player)
end)

-- == EVENTS ==================================================================

Event.add(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    Gui.add_top_element(player, {
        name = main_button_name,
        type = 'sprite-button',
        sprite = 'utility/side_menu_production_icon',
        tooltip = { 'production_hud.feature_tooltip' },
    })

    player_settings[player.index] = {
        precision_index = defines.flow_precision_index.ten_minutes,
        items = table.deepcopy(config.starting_items or {}),
    }
end)

Event.add(defines.events.on_player_removed, function(event)
    player_settings[event.player_index] = nil
end)

Event.on_nth_tick(307, function()
    for _, p in pairs(game.connected_players) do
        Public.update_main_frame(p)
    end
end)

Event.on_configuration_changed(function()
    for _, p in pairs(game.players) do
        Public.sanitize_player_settings(p.index)
    end
end)

-- ============================================================================
