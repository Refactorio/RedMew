local Gui = require 'utils.gui'
local Token = require 'utils.token'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Server = require 'features.server'
local Toast = require 'features.gui.toast'
local Settings = require 'utils.redmew_settings'
local Color = require 'resources.color_presets'

local pairs = pairs
local table_size = table.size

local main_button_name = Gui.uid_name()
local save_changes_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local Public = {}

local on_player_settings_get = Token.register(function (data)
    local player = game.players[data.key]

    if not player or not player.valid then
        return
    end

    local settings = data.value

    if settings ~= nil then
        local player_index = player.index
        for key, value in pairs(settings) do
            Settings.set(player_index, key, value)
        end
    end

    local button = player.gui.top[main_button_name]
    button.enabled = true
    button.tooltip = {'redmew_settings_gui.menu_item_tooltip'}
end)

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local button = player.gui.top.add({
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'item/iron-gear-wheel',
        tooltip = {'redmew_settings_gui.menu_item_tooltip'}
    })

    -- disable the button if the remote server is used, won't be available until the settings are loaded
    if global.config.redmew_settings.use_remote_server then
        button.enabled = false
        button.tooltip = {'redmew_settings_gui.menu_item_tooltip_loading'}
    end
end

local function player_joined(event)
    if not global.config.redmew_settings.use_remote_server then
        return
    end

    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    Server.try_get_data('player_settings', player.name, on_player_settings_get);
end

local function get_element_value(element)
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

local function create_input_element(frame, type, value)
    if type == 'fraction' then
        return frame.add({type = 'slider', value = value, minimum_value = 0, maximum_value = 1})
    end
    if type == 'boolean' then
        return frame.add({type = 'checkbox', state = value})
    end

    -- ensure something is always added to prevent errors
    return frame.add({type = 'text-box', text = value})
end

local function draw_main_frame(center, player)
    local settings = Settings.get_setting_metadata()
    local settings_frame = center.add({
        type = 'frame',
        name = main_frame_name,
        direction = 'vertical',
        caption = {'redmew_settings_gui.frame_title'},
    })

    local settings_frame_style = settings_frame.style
    settings_frame_style.width = 400

    local scroll_pane = settings_frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.maximal_height = 800
    scroll_style.minimal_height = 35 * table_size(settings)
    scroll_style.bottom_padding = 5
    scroll_style.left_padding = 5
    scroll_style.right_padding = 5
    scroll_style.top_padding = 5

    local setting_grid = scroll_pane.add({type = 'table', column_count = 2})
    local player_index = player.index

    local data = {}

    for name, setting in pairs(settings) do
        local caption = name

        if setting.localisation_key then
            caption = {setting.localisation_key}
        end

        local label = setting_grid.add({
            type = 'label',
            caption = caption,
        })
        label.style.horizontally_stretchable = true

        local value = Settings.get(player_index, name)
        local input = create_input_element(setting_grid, setting.type, value)

        data[name] = {
            label = label,
            input = input,
            previous_value = value,
        }
    end

    local bottom_flow = settings_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = main_button_name, caption = {'redmew_settings_gui.button_cancel'}})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_changes_button_name, caption = {'redmew_settings_gui.button_save_changes'}})
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)

    player.opened = settings_frame
end

local function toggle(event)
    local player = event.player
    local center = player.gui.center
    local main_frame = center[main_frame_name]

    if main_frame then
        Gui.destroy(main_frame)
    else
        draw_main_frame(center, player)
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
        local value = get_element_value(input)
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

    for name, value in pairs (values) do
        Settings.set(player_index, name, value)
    end

    Toast.toast_player(player, 5, {'redmew_settings_gui.save_success_toast_message'})

    if global.config.redmew_settings.use_remote_server then
        Server.set_data('player_settings', player.name, Settings.all(player_index));
    end

    local main_frame = player.gui.center[main_frame_name]

    if main_frame then
        Gui.destroy(main_frame)
    end
end

Gui.on_custom_close(main_frame_name, function(event)
    Gui.destroy(event.element)
end)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, toggle)
Gui.on_click(save_changes_button_name, save_changes)
Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_joined_game, player_joined)

return Public
