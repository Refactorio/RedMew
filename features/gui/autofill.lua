local Autofill = require 'features.autofill'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Settings = require 'utils.redmew_settings'
local Color = require 'resources.color_presets'

local enabled_style = 'green_slot_button'
local disabled_style = 'red_slot_button'

local style_map = {[true] = enabled_style, [false] = disabled_style}
local enabled_locale_map = {[true] = {'common.enabled'}, [false] = {'common.disabled'}}

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local enabled_checkbox_name = Gui.uid_name()
local ammo_count_name = Gui.uid_name()
local enabled_ammo_button = Gui.uid_name()

local function player_created(event)
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    player.gui.top.add {
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'item/piercing-rounds-magazine',
        tooltip = {'autofill.main_button_tooltip'}
    }
end

local function update_ammo_button(button, name, enabled)
    local locale_name = Autofill.ammo_locales[name]
    local style = style_map[enabled]
    local tooltip = {'', locale_name, ' ', enabled_locale_map[enabled]}

    button.style = style
    button.tooltip = tooltip
end

local function toggle_main_frame(event)
    local player = event.player
    local player_index = player.index
    local gui = player.gui
    local left = gui.left
    local frame = left[main_frame_name]
    local main_button = gui.top[main_button_name]

    if frame then
        Gui.destroy(frame)
        main_button.style = 'icon_button'
    else
        main_button.style = 'selected_slot_button'
        local style = main_button.style
        style.width = 38
        style.height = 38

        frame =
            left.add {type = 'frame', name = main_frame_name, caption = {'autofill.frame_name'}, direction = 'vertical'}

        local enabled_checkbox =
            frame.add {
            type = 'checkbox',
            name = enabled_checkbox_name,
            caption = {'autofill.enable'},
            state = Autofill.get_enabled(player_index)
        }

        local ammo_count_flow = frame.add {type = 'flow', direction = 'horizontal'}
        local ammo_count_label = ammo_count_flow.add {type = 'label', caption = {'autofill.ammo_count'}}
        local ammo_count_textfield =
            ammo_count_flow.add {
            type = 'textfield',
            name = ammo_count_name,
            text = Autofill.get_ammo_count(player_index)
        }

        local enabled_ammos_flow = frame.add {type = 'flow', direction = 'horizontal'}
        enabled_ammos_flow.add {type = 'label', caption = {'autofill.enabled_ammos'}}

        for name, enabled in pairs(Autofill.get_player_ammos(player_index)) do
            local button =
                enabled_ammos_flow.add({type = 'flow'}).add(
                {
                    type = 'sprite-button',
                    name = enabled_ammo_button,
                    sprite = 'item/' .. name
                }
            )
            update_ammo_button(button, name, enabled)

            Gui.set_data(button, name)
        end

        frame.add {type = 'button', name = main_button_name, caption = 'Close'}

        local data = {
            enabled_checkbox = enabled_checkbox,
            ammo_count_label = ammo_count_label,
            ammo_count_textfield = ammo_count_textfield
        }

        Gui.set_data(frame, data)
        Gui.set_data(ammo_count_textfield, data)
    end
end

local function enabled_checkbox_changed(event)
    Autofill.set_enabled(event.player_index, event.element.state)
end

local function set_ammo_count_elements_validation(textfield, label, valid)
    local color, label_color, tooltip
    if valid then
        color = Color.black
        label_color = Color.white
        tooltip = ''
    else
        color = Color.red
        label_color = Color.red
        tooltip = {'autofill.invalid_ammo_count'}
    end

    textfield.style.font_color = color
    label.style.font_color = label_color
    textfield.tooltip = tooltip
    label.tooltip = tooltip
end

local function ammo_count_changed(event)
    local element = event.element
    local data = Gui.get_data(element)
    local ammo_count_label = data.ammo_count_label

    local valid = Autofill.set_ammo_count(event.player_index, element.text)
    set_ammo_count_elements_validation(element, ammo_count_label, valid)
end

local function enabled_ammos_changed(event)
    local player_index = event.player_index
    local element = event.element
    local name = Gui.get_data(element)

    local ammos = Autofill.get_player_ammos(player_index)
    local enabled = not ammos[name]
    Autofill.set_player_ammo(player_index, name, enabled)

    update_ammo_button(element, name, enabled)
end

local function settings_changed(event)
    local setting_name = event.setting_name

    if setting_name == Autofill.enable_autofill_name then
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local frame = player.gui.left[main_frame_name]
        if not frame then
            return
        end

        local data = Gui.get_data(frame)
        local checkbox = data.enabled_checkbox

        checkbox.state = event.new_value
    elseif setting_name == Autofill.ammo_count_name then
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local frame = player.gui.left[main_frame_name]
        if not frame then
            return
        end

        local data = Gui.get_data(frame)
        local ammo_count_label = data.ammo_count_label
        local ammo_count_textfield = data.ammo_count_textfield

        ammo_count_textfield.text = event.new_value
        set_ammo_count_elements_validation(ammo_count_textfield, ammo_count_label, true)
    end
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_checked_state_changed(enabled_checkbox_name, enabled_checkbox_changed)
Gui.on_text_changed(ammo_count_name, ammo_count_changed)
Gui.on_click(enabled_ammo_button, enabled_ammos_changed)
Gui.on_click(main_button_name, toggle_main_frame)

Event.add(Settings.events.on_setting_set, settings_changed)
Event.add(defines.events.on_player_created, player_created)
