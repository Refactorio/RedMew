-- A color picker built from regular GUI elements: a preview, and below it an R/G/B slider and number
-- field per channel and two rows of preset swatches, collapsed until the player opens them. Colors are tables with r, g, b (and optionally a) from 0 to 255.
-- The preview and swatches are full progress bars, the only element whose color can be set at runtime.
local Gui = require 'utils.gui'

local floor = math.floor
local tonumber = tonumber
local tostring = tostring

local slider_name = Gui.uid_name()
local field_name = Gui.uid_name()
local swatch_name = Gui.uid_name()
local toggle_name = Gui.uid_name()
local preview_name = Gui.uid_name()

local channels = {'r', 'g', 'b'}
local channel_captions = {
    r = '[color=1,0.3,0.3]R[/color]',
    g = '[color=0.3,1,0.3]G[/color]',
    b = '[color=0.4,0.6,1]B[/color]',
}

local presets = {
    {r = 255, g = 64, b = 64},
    {r = 255, g = 140, b = 0},
    {r = 255, g = 215, b = 0},
    {r = 50, g = 205, b = 50},
    {r = 0, g = 206, b = 209},
    {r = 30, g = 144, b = 255},
    {r = 106, g = 90, b = 205},
    {r = 186, g = 85, b = 211},
    {r = 255, g = 105, b = 180},
    {r = 139, g = 69, b = 19},
    {r = 255, g = 255, b = 255},
    {r = 160, g = 160, b = 160},
    {r = 80, g = 80, b = 80},
    {r = 0, g = 0, b = 0},
}

local Public = {}

local function clamp_channel(value)
    value = floor((tonumber(value) or 0) + 0.5)
    if value < 0 then
        return 0
    end
    if value > 255 then
        return 255
    end
    return value
end

---0-255 color to the 0-1 color the GUI needs, as 0-255 tables with every channel <= 1 would be
---read as 0-1 instead
local function to_gui_color(color)
    return {r = color.r / 255, g = color.g / 255, b = color.b / 255}
end

local function color_text(color)
    return color.r .. ' ' .. color.g .. ' ' .. color.b
end

local function add_swatch(parent, name, color, size)
    local swatch = parent.add {type = 'progressbar', name = name, value = 1, tooltip = color_text(color)}
    Gui.set_style(swatch, {width = size, height = size, bar_width = size, color = to_gui_color(color)})
    return swatch
end

local function refresh_preview(data)
    local color = data.color
    local gui_color = to_gui_color(color)
    data.preview_swatch.style.color = gui_color
    data.preview_swatch.tooltip = color_text(color)
    data.preview_label.style.font_color = gui_color
end

local function apply_color(data, color)
    for _, channel in pairs(channels) do
        local value = clamp_channel(color[channel])
        data.color[channel] = value
        data.sliders[channel].slider_value = value
        data.fields[channel].text = tostring(value)
    end
    refresh_preview(data)
end

---Adds a color picker to parent and returns its root element
---@param parent LuaGuiElement
---@param color table r, g, b and optionally a, from 0 to 255
---@param preview_caption LocalisedString shown in the picked color
---@return LuaGuiElement
function Public.add(parent, color, preview_caption)
    local root = parent.add {type = 'flow', direction = 'vertical'}
    Gui.set_style(root, {vertical_spacing = 4})

    local data = {
        color = {r = 0, g = 0, b = 0, a = color.a},
        sliders = {},
        fields = {},
        touched = false,
    }

    local header = root.add {type = 'flow', direction = 'horizontal'}
    Gui.set_style(header, {height = 35, vertical_align = 'center', horizontal_spacing = 8})
    data.toggle = header.add {
        type = 'sprite-button',
        name = toggle_name,
        sprite = 'utility/expand',
        style = 'frame_action_button',
        tooltip = {'color_picker.toggle_tooltip'},
    }
    data.preview_swatch = add_swatch(header, preview_name, color, 28)
    data.preview_label = header.add {type = 'label', caption = preview_caption}
    Gui.set_style(data.preview_label, {font = 'default-bold'})

    local body = root.add {type = 'flow', direction = 'vertical', visible = false}
    Gui.set_style(body, {vertical_spacing = 4, bottom_margin = 4})
    data.body = body

    for _, channel in pairs(channels) do
        local row = body.add {type = 'flow', direction = 'horizontal'}
        Gui.set_style(row, {vertical_align = 'center', horizontal_spacing = 6})

        local label = row.add {type = 'label', caption = channel_captions[channel]}
        Gui.set_style(label, {font = 'default-bold', width = 12})

        local slider = row.add {
            type = 'slider',
            name = slider_name,
            minimum_value = 0,
            maximum_value = 255,
            value = 0,
            value_step = 1,
            discrete_values = true,
        }
        Gui.set_style(slider, {width = 150})

        local field = row.add {
            type = 'textfield',
            name = field_name,
            numeric = true,
            allow_decimal = false,
            allow_negative = false,
            lose_focus_on_confirm = true,
        }
        Gui.set_style(field, {width = 48, horizontal_align = 'center'})

        data.sliders[channel] = slider
        data.fields[channel] = field
        Gui.set_data(slider, {picker = data, channel = channel})
        Gui.set_data(field, {picker = data, channel = channel})
    end

    local swatches = body.add {type = 'table', column_count = 7}
    Gui.set_style(swatches, {horizontal_spacing = 4, vertical_spacing = 4, top_margin = 2})
    for _, preset in pairs(presets) do
        -- every swatch shares a name for the click handler, so each needs its own parent
        local swatch = add_swatch(swatches.add {type = 'flow'}, swatch_name, preset, 20)
        Gui.set_data(swatch, {picker = data, color = preset})
    end

    apply_color(data, color)
    Gui.set_data(root, data)
    Gui.set_data(data.toggle, data)
    Gui.set_data(data.preview_swatch, data)

    return root
end

---The picked color, with r, g, b (and a, if the starting color had one) from 0 to 255
---@param root LuaGuiElement returned by Public.add
function Public.get_color(root)
    local color = Gui.get_data(root).color
    return {r = color.r, g = color.g, b = color.b, a = color.a}
end

---@param root LuaGuiElement returned by Public.add
---@param color table r, g, b and optionally a, from 0 to 255
function Public.set_color(root, color)
    local data = Gui.get_data(root)
    data.color.a = color.a
    apply_color(data, color)
end

---Whether the player has changed the color since the picker was added
---@param root LuaGuiElement returned by Public.add
function Public.is_touched(root)
    return Gui.get_data(root).touched
end

Gui.on_value_changed(slider_name, function(event)
    local element = event.element
    local element_data = Gui.get_data(element)
    local data = element_data.picker
    local channel = element_data.channel

    local value = clamp_channel(element.slider_value)
    data.color[channel] = value
    data.fields[channel].text = tostring(value)
    data.touched = true
    refresh_preview(data)
end)

Gui.on_text_changed(field_name, function(event)
    local element = event.element
    local element_data = Gui.get_data(element)
    local data = element_data.picker
    local channel = element_data.channel

    local value = clamp_channel(element.text)
    if tonumber(element.text) and tonumber(element.text) > 255 then
        element.text = tostring(value)
    end
    data.color[channel] = value
    data.sliders[channel].slider_value = value
    data.touched = true
    refresh_preview(data)
end)

local function toggle(event)
    local data = Gui.get_data(event.element)
    local visible = not data.body.visible
    data.body.visible = visible
    data.toggle.sprite = visible and 'utility/collapse' or 'utility/expand'
end

Gui.on_click(toggle_name, toggle)
Gui.on_click(preview_name, toggle)

Gui.on_click(swatch_name, function(event)
    local element_data = Gui.get_data(event.element)
    local data = element_data.picker
    data.touched = true
    apply_color(data, element_data.color)
end)

return Public
