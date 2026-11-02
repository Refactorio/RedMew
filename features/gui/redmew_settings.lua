local Color = require 'resources.color_presets'
local ColorPicker = require 'features.gui.color_picker'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Settings = require 'utils.redmew_settings'
local Styles = require 'resources.styles'
local Toast = require 'features.gui.toast'
local pairs = pairs
local floor = math.floor

local main_button_name = Gui.uid_name()
local save_changes_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local fraction_slider_name = Gui.uid_name()

local Public = {}

-- setting types edited with a color picker instead of a text box
local color_types = {color = true, chat_color = true}

local function player_created(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Gui.add_top_element(player, {
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'item/iron-gear-wheel',
        tooltip = { 'redmew_settings_gui.tooltip' },
    })
end

local function close(player)
    local main_frame = Gui.get_panel(player, main_frame_name)
    if main_frame then
        Gui.destroy(main_frame)
    end
    local main_button = Gui.get_top_element(player, main_button_name)
    if main_button then
        main_button.toggled = false
    end
end

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    close(player)
end

---0-255 copy of a color the game gives from 0 to 1, like player.color
local function to_255(color)
    return {
        r = floor(color.r * 255 + 0.5),
        g = floor(color.g * 255 + 0.5),
        b = floor(color.b * 255 + 0.5),
        a = floor((color.a or 1) * 255 + 0.5),
    }
end

local function get_element_value(element_data)
    local element = element_data.input
    if element_data.color_picker then
        -- a color the player never set stays unset unless they pick one, so saving other settings
        -- doesn't start syncing their current color
        if element_data.unset and not ColorPicker.is_touched(element) then
            return ''
        end
        return ColorPicker.get_color(element)
    end
    if element.type == 'text-box' then
        return element.text
    end
    if element.type == 'slider' then
        return element.slider_value
    end
    if element.type == 'checkbox' then
        return element.state
    end
end

-- the percentage next to a fraction's slider
local function show_fraction(slider)
    Gui.get_data(slider).caption = floor(slider.slider_value * 100 + 0.5) .. ' %'
end

local function set_element_value(element, value)
    if element.type == 'text-box' then
        element.text = tostring(value)
        return
    end
    if element.type == 'slider' then
        element.slider_value = value
        show_fraction(element)
        return
    end
    if element.type == 'checkbox' then
        element.state = value
        return
    end
end

local function create_input_element(frame, _type, value)
    if _type == 'fraction' then
        local slider = frame.add { type = 'slider', name = fraction_slider_name, value = value, minimum_value = 0, maximum_value = 1 }
        Gui.set_data(slider, frame.add { type = 'label' })
        show_fraction(slider)
        return slider
    end
    if _type == 'boolean' then
        return frame.add { type = 'checkbox', state = value }
    end

    -- ensure something is always added to prevent errors
    return frame.add { type = 'text-box', text = tostring(value) }
end

local function draw_main_frame(player)
    local settings = Settings.get_setting_metadata()
    local main_frame, inner = Gui.add_panel(player, {
        name = main_frame_name,
        caption = { 'redmew_settings_gui.frame_title' },
        toggle_name = main_button_name,
        width = 'wide',
    })

    -- the subheader and the list fill the inner frame
    Gui.set_style(inner, { padding = 0 })

    local header = inner.add { type = 'frame', style = 'subheader_frame' }
    Gui.set_style(header, { horizontally_stretchable = true, maximal_height = 200, padding = 5 })

    local info_text = header.add { type = 'label', caption = { 'redmew_settings_gui.setting_info' } }
    Gui.set_style(info_text, {
        single_line = false,
        padding = 5,
        width = Styles.panel_width.wide - 50,
    })

    local scroll_pane = inner.add { type = 'scroll-pane', style = 'naked_scroll_pane' }
    Gui.set_style(scroll_pane, {
        horizontally_stretchable = true,
        vertically_squashable = true,
        maximal_height = 800,
        padding = 8,
    })

    local setting_grid = scroll_pane.add { type = 'table', column_count = 2 }
    -- keep labels at the top of rows made taller by an opened color picker
    local column_alignments = setting_grid.style.column_alignments
    column_alignments[1] = 'top-left'
    column_alignments[2] = 'top-left'
    local player_index = player.index

    local data = {}

    for name, setting in pairs(settings) do
        local label = setting_grid.add { type = 'label', caption = setting.locale_string }
        Gui.set_style(label, { horizontally_stretchable = true, height = 35, vertical_align = 'center' })

        local raw_value = Settings.get(player_index, name)
        local value = Settings.toScalar(name, raw_value)
        local input_container = setting_grid.add { type = 'flow' }
        local color_picker = color_types[setting.type] or nil
        local input
        if color_picker then
            -- an unset color starts from the player's current one
            local color = raw_value or to_255(setting.type == 'chat_color' and player.chat_color or player.color)
            input = ColorPicker.add(input_container, color, player.name)
        else
            Gui.set_style(input_container, { height = 35, vertical_align = 'center' })
            input = create_input_element(input_container, setting.type, value)
        end

        data[name] = {
            label = label,
            input = input,
            previous_value = value,
            color_picker = color_picker,
            unset = color_picker and raw_value == nil,
        }
    end

    -- Save in a row under the inner frame, like Factorio's own dialogs: a floating panel can be
    -- dragged by the space beside it, as by its header
    local buttons = main_frame.add { type = 'flow', direction = 'horizontal', style = 'dialog_buttons_horizontal_flow' }
    if main_frame.parent == player.gui.screen then
        local filler = buttons.add { type = 'empty-widget', style = 'draggable_space' }
        Gui.set_style(filler, { horizontally_stretchable = true, height = 32 })
        filler.drag_target = main_frame
    else
        Gui.add_pusher(buttons)
    end
    local save_button = buttons.add {
        type = 'button',
        name = save_changes_button_name,
        caption = { 'redmew_settings_gui.button_save_changes' },
        style = 'confirm_button_without_tooltip',
    }

    Gui.set_data(save_button, data)
    Gui.set_data(main_frame, data)
end

local function toggle(event)
    local player = event.player
    if Gui.get_panel(player, main_frame_name) then
        close(player)
    else
        draw_main_frame(player)
        Gui.get_top_element(player, main_button_name).toggled = true
    end
end

local function save_changes(event)
    local data = Gui.get_data(event.element)
    local player_index = event.player_index
    local player = event.player

    local errors_count = 0
    local values = {}

    for name, element_data in pairs(data) do
        local input = element_data.input
        local label = element_data.label
        local value = get_element_value(element_data)
        local validated = Settings.validate(name, value)

        if nil ~= validated then
            errors_count = errors_count + 1
            label.style.font_color = Color.red
            label.tooltip = validated
            label.parent.tooltip = validated
            input.tooltip = validated
            input.parent.tooltip = validated
        else
            label.style.font_color = Color.white
            label.tooltip = ''
            label.parent.tooltip = ''
            input.tooltip = ''
            input.parent.tooltip = ''
        end
        values[name] = value
    end

    if errors_count > 0 then
        return
    end

    for name, value in pairs(values) do
        Settings.set(player_index, name, value)
    end

    Toast.toast_player(player, 5, { 'redmew_settings_gui.save_success_toast_message' })
    close(player)
end

local function setting_set(event)
    if not event.value_changed then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local main_frame = Gui.get_panel(player, main_frame_name)
    if not main_frame then
        return
    end

    local data = Gui.get_data(main_frame)
    if not data then
        return
    end

    local setting_name = event.setting_name
    local element_data = data[setting_name]

    if not element_data then
        return
    end

    local input = element_data.input
    if not input or not input.valid then
        -- for some reason it has been removed already
        return
    end
    if element_data.color_picker then
        if event.new_value then
            ColorPicker.set_color(input, event.new_value)
            element_data.unset = false
        end
    else
        set_element_value(input, Settings.toScalar(setting_name, event.new_value))
    end
    element_data.previous_value = Settings.toScalar(setting_name, event.old_value)
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, toggle)
Gui.on_click(save_changes_button_name, save_changes)
Gui.on_value_changed(fraction_slider_name, function(event)
    show_fraction(event.element)
end)
Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(Settings.events.on_setting_set, setting_set)

return Public
