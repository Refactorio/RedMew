local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Toast = require 'features.gui.toast'
local Settings = require 'utils.redmew_settings'
local Color = require 'resources.color_presets'
local pairs = pairs

local main_button_name = Gui.uid_name()
local save_changes_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local Public = {}

local function close_main_frame(frame, player)
    Gui.destroy(frame)
    player.gui.top[main_button_name].style = 'icon_button'
end

local function player_created(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'item/iron-gear-wheel',
            tooltip = {'redmew_settings_gui.tooltip'}
        }
    )
end

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local main_frame = player.gui.center[main_frame_name]

    if main_frame then
        close_main_frame(main_frame, player)
    end
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

local function set_element_value(element, value)
    if element.type == 'text-box' then
        element.text = value
        return
    end
    if element.type == 'slider' then
        element.slider_value = value
        return
    end
    if element.type == 'checkbox' then
        element.state = value
        return
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
    local settings_frame =
        center.add(
        {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = {'redmew_settings_gui.frame_title'}
        }
    )

    local settings_frame_style = settings_frame.style
    settings_frame_style.width = 400

    local info_text = settings_frame.add({type = 'label', caption = {'redmew_settings_gui.setting_info'}})
    local info_text_style = info_text.style
    info_text_style.single_line = false
    info_text_style.bottom_padding = 5
    info_text_style.left_padding = 5
    info_text_style.right_padding = 5
    info_text_style.top_padding = 5
    info_text_style.width = 370

    local scroll_pane = settings_frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.maximal_height = 800
    scroll_style.bottom_padding = 5
    scroll_style.left_padding = 5
    scroll_style.right_padding = 5
    scroll_style.top_padding = 5

    local setting_grid = scroll_pane.add({type = 'table', column_count = 2})
    local player_index = player.index

    local data = {}

    for name, setting in pairs(settings) do
        local label =
            setting_grid.add(
            {
                type = 'label',
                caption = setting.locale_string
            }
        )

        local label_style = label.style
        label_style.horizontally_stretchable = true
        label_style.height = 35
        label_style.vertical_align = 'center'

        local value = Settings.toScalar(name, Settings.get(player_index, name))
        local input_container = setting_grid.add({type = 'flow'})
        local input_container_style = input_container.style
        input_container_style.height = 35
        input_container_style.vertical_align = 'center'
        local input = create_input_element(input_container, setting.type, value)

        data[name] = {
            label = label,
            input = input,
            previous_value = value
        }
    end

    local bottom_flow = settings_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button =
        left_flow.add({type = 'button', name = main_button_name, caption = {'redmew_settings_gui.button_cancel'}})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button =
        right_flow.add(
        {type = 'button', name = save_changes_button_name, caption = {'redmew_settings_gui.button_save_changes'}}
    )
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)
    Gui.set_data(settings_frame, data)

    player.opened = settings_frame
end

local function toggle(event)
    local player = event.player
    local gui = player.gui
    local center = gui.center
    local main_frame = center[main_frame_name]
    local main_button = gui.top[main_button_name]

    if main_frame then
        close_main_frame(main_frame, player)
    else
        draw_main_frame(center, player)

        main_button.style = 'selected_slot_button'
        local style = main_button.style
        style.width = 38
        style.height = 38
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

    for name, value in pairs(values) do
        Settings.set(player_index, name, value)
    end

    Toast.toast_player(player, 5, {'redmew_settings_gui.save_success_toast_message'})

    local main_frame = player.gui.center[main_frame_name]

    if main_frame then
        close_main_frame(main_frame, player)
    end
end

local function setting_set(event)
    if not event.value_changed then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local main_frame = player.gui.center[main_frame_name]
    if not main_frame or not main_frame.valid then
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
    set_element_value(input, Settings.toScalar(setting_name, event.new_value))
    element_data.previous_value = Settings.toScalar(setting_name, event.old_value)
end

Gui.on_custom_close(
    main_frame_name,
    function(event)
        close_main_frame(event.element, event.player)
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, toggle)
Gui.on_click(save_changes_button_name, save_changes)
Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(Settings.events.on_setting_set, setting_set)

return Public
