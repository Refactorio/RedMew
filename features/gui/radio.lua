local Gui = require 'utils.gui'
local Command = require 'utils.command'
local Event = require 'utils.event'

local main_button_name = Gui.uid_name()
local radio_frame = Gui.uid_name()
local close_radio = Gui.uid_name()

local sounds = {
    ['ambient'] = {
        'after-the-crash',
        'automation',
        'resource-deficiency',
        'are-we-alone',
        'beyond-factory-outskirts',
        'censeqs-discrepancy',
        'efficiency-program',
        'expansion',
        'the-search-for-iron',
        'gathering-horizon',
        'research-and-minerals',
        'solar-intervention',
        'the-oil-industry',
        'the-right-tools',
        'pollution',
        'turbine-dynamics',
        'sentient',
        'anomaly',
        'first-light',
        'transmit',
        'swell-pad',
        'world-ambience-1',
        'world-ambience-2',
        'world-ambience-3',
        'world-ambience-4',
        'world-ambience-5',
        'world-ambience-6'
    },
    ['default'] = {
        'worm-sends-biters',
        'mainframe-activated',
        'car-repaired'
    },
    ['utility'] = {
        'achievement_unlocked',
        'alert_destroyed',
        'armor_insert',
        'armor_remove',
        'axe_fighting',
        'axe_mining_ore',
        'build_big',
        'build_medium',
        'build_small',
        'cannot_build',
        'console_message',
        'crafting_finished',
        'deconstruct_big',
        'deconstruct_medium',
        'deconstruct_small',
        'default_manual_repair',
        'game_lost',
        'game_won',
        'gui_click',
        'inventory_move',
        'list_box_click',
        'metal_walking_sound',
        'mining_wood',
        'new_objective',
        'research_completed',
        'scenario_message',
        'tutorial_notice',
        'wire_connect_pole',
        'wire_disconnect',
        'wire_pickup'
    }
}

local function draw_radio(event)
    local frame_caption

    frame_caption = 'Radio'
    local player = event.player
    local center = player.gui.center

    local frame = center[radio_frame]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
        return
    end

    frame = center.add {type = 'frame', name = radio_frame, caption = frame_caption, direction = 'vertical'}
    local scroll_pane =
        frame.add {
        type = 'scroll-pane',
        vertical_scroll_policy = 'auto-and-reserve-space',
        horizontal_scroll_policy = 'never'
    }
    Gui.set_data(scroll_pane, frame)

    local main_table = scroll_pane.add {type = 'table', column_count = 4}

    for type, sound in pairs(sounds) do
        for i = 1, #sound do
            local name = (type == 'default') and sound[i] or type .. '/' .. sound[i]
            local textbox = main_table.add {type = 'text-box', text = type .. '/' .. sound[i]}
            textbox.read_only = true
            textbox.style.height = 28
            textbox.style.width = 250
            local button = main_table.add {type = 'button', name = 'radio_play:' .. name, caption = 'Play'}
            button.style.width = 54
        end
    end

    local information_pane =
        frame.add {
        type = 'scroll-pane',
        vertical_scroll_policy = 'auto-and-reserve-space',
        horizontal_scroll_policy = 'never'
    }
    information_pane.style.horizontally_stretchable = true
    information_pane.style.horizontal_align = 'center'
    Gui.set_data(information_pane, frame)

    local text =
        [[
        Other types:
        syntax = <type>/<entity>
        "tile-walking" - for example "tile-walking/concrete"
        "tile-build"
        "tile-mined"
        "entity-build" - for example "entity-build/wooden-chest"
        "entity-mined"
        "entity-vehicle_impact"
        "entity-open"
        "entity-close"
    ]]
    local information = information_pane.add {type = 'text-box', text = text}
    information.style.horizontally_stretchable = true
    information.style.vertically_stretchable = true
    information.style.minimal_height = 200
    information.style.minimal_width = 400

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = close_radio, caption = 'Close'}
    Gui.set_data(close_button, frame)

    player.opened = frame
end

Gui.on_click(main_button_name, draw_radio)

Gui.on_click(
    close_radio,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    radio_frame,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

local function radio_command(_, player)
    if player and player.valid then
        local event = {player = player}
        draw_radio(event)
    end
end

Command.add(
    'radio',
    {
        description = 'Opens radio gui',
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    radio_command
)

local function handler(event)
    local element = event.element
    if not element or not element.valid then
        return
    end
    local name = element.name
    local subname = string.sub(name, 1, 11)
    if subname == 'radio_play:' then
        local path = string.sub(name, 12)
        local player = game.get_player(event.player_index)
        if (game.is_valid_sound_path(path)) then
            player.play_sound {path = path}
            return
        else
            player.print('Unable to play sound: ' .. path)
        end
    end
end

Event.add(defines.events.on_gui_click, handler)
