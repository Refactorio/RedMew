local Gui = require 'utils.gui'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local Scenario_Info = require 'features.gui.info'

local creators = storage.config.map_info

local gui_frame = Gui.uid_name()
local generate_tags = Gui.uid_name()
local template_radio = Gui.uid_name()
local close_gui = Gui.uid_name()

local function split(string, delimiter)
    if delimiter == nil then
        delimiter = '%s'
    end
    local t = {}
    for str in string.gmatch(string, '([^' .. delimiter .. ']+)') do
        table.insert(t, str)
    end
    return t
end

local max_char_width = 69

local function generate_spaces(number)
    local return_string = ' '
    for i = 1, number do
        return_string = return_string .. ' '
    end
    return return_string
end

local function center_map_description(string)
    local return_string = '\n[font=default-bold]\n'

    local strings = split(string, '\n')
    for _, str in pairs(strings) do
        local chars, num_spaces = string.gsub(str, ' ', '')
        local string_width = #chars + num_spaces * 2
        local remainding_width = (max_char_width - string_width)
        local right, left = math.ceil(remainding_width), math.floor(remainding_width)
        return_string = return_string .. '  ' .. generate_spaces(left) .. str .. generate_spaces(right) .. '\n'
    end
    return return_string .. '[/font]\n'
end

local function prepair_tags(string)
    local return_string

    return_string = string.gsub(string, ' ', ' ') -- first is a regular space, second is a non-breaking space
    return_string = string.gsub(return_string, '\n', ' ')

    return return_string
end

local desc_header = '[color=1,0.88,0][font=default-bold]├──────┤[/font][img=item.raw-fish][font=default-bold]│[/font][/color][font=default-large-bold][color=red]  REDMEW  [/color][/font][color=1,0.88,0][font=default-bold]│[/font][img=item.raw-fish][font=default-bold]├──────┤[/font][/color]'
local desc_devider = '[color=1,0.88,0][font=default-bold]├───────────┤       ├───────────┤[/font][/color]'
local desc_info = [[
[virtual-signal=signal-info]│[font=default-large-bold] Information[/font]
[virtual-signal=signal-dot]│ We are a community dedicated to making great
[virtual-signal=signal-dot]│ factorio maps and creating a multiplayer server
[virtual-signal=signal-dot]│ for everyone to enjoy.
]]

local desc_community_info = [[
[entity=programmable-speaker]│[font=default-large-bold] Communities[/font]
[virtual-signal=signal-dot]│ Join our discord at [color=blue]redmew.com/discord[/color]
[virtual-signal=signal-dot]│ Download saves at [color=blue]redmew.com/saves[/color]
]]

local desc_modded_info = [[
[img=entity/lab]│[font=default-large-bold] Modded gameplay[/font]
[virtual-signal=signal-dot]│ This server contains modded gameplay
[virtual-signal=signal-dot]│ Visit [color=blue]#modded[/color] in our discord to learn more!
]]

local function generate_desc_map_primary_credit_info()
    local primary = creators.map_primary_creator_key

    if not primary then
        return ''
    end

    return [[
[entity=character]│[font=default-large-bold] Map contributions[/font]
[virtual-signal=signal-dot]│ Map created by ]] .. '[color=orange]' .. primary .. '[/color]\n'
end

local function generate_desc_map_secondary_credit_info()
    local primary = creators.map_primary_creator_key
    local secondary = creators.map_secondary_creator_key

    if not primary or not secondary then
        return ''
    end

    return [[
[virtual-signal=signal-dot]│ Map contributions by ]] .. '[color=orange]' .. secondary .. '[/color]\n'
end

local desc_map_primary_credit_info = generate_desc_map_primary_credit_info()

local desc_map_secondary_credit_info = generate_desc_map_secondary_credit_info()

local desc_donate_info =
    [[
[item=coin]│[font=default-large-bold] Donate[/font]
[virtual-signal=signal-dot]│ Huge thanks to all our donators and patreons!
[virtual-signal=signal-dot]│ They help us host new experiences for you.
[virtual-signal=signal-dot]│ Make a pledge at [color=blue]patreon.com/redmew[/color]
]]

local desc_contribute_info =
    [[
[img=entity/compilatron]│ [font=default-large-bold]The RedMew Scenario[/font]
[virtual-signal=signal-dot]│Want to contribute to the source code?
[virtual-signal=signal-dot]│Visit our github at [color=blue]github.com/Refactorio/RedMew[/color]
[virtual-signal=signal-dot]│You are free to setup your own map.
[virtual-signal=signal-dot]│Go to [color=blue]redmew.com/guide[/color] for more information]]

local server_prefix = '[color=1][R][/color] '

local map_name = Scenario_Info.get_map_name()

local map_desc = Scenario_Info.get_map_description()

local function draw_gui(event)
    local frame_caption = 'Server browser text generator'
    local player = event.player
    local center = player.gui.center

    local frame = center[gui_frame]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
        return
    end

    frame = center.add {type = 'frame', name = gui_frame, caption = frame_caption, direction = 'vertical'}

    local main_table = frame.add {type = 'table', column_count = 1}

    main_table.add {type = 'label', caption = 'Server Name (50 characters limit including prefix)'}
    local server_name = main_table.add {type = 'text-box', text = server_prefix .. string.sub(map_name, 1, 49 - #server_prefix)}
    server_name.read_only = true
    server_name.style.horizontally_stretchable = true
    server_name.word_wrap = false
    server_name.style.width = 250

    main_table.add {type = 'label', caption = 'Server Description'}
    local server_desc = main_table.add {type = 'text-box', text = desc_header .. center_map_description(map_desc) .. desc_devider}
    server_desc.read_only = true
    server_desc.word_wrap = true
    server_desc.style.horizontally_stretchable = true
    server_desc.style.height = 150
    server_desc.style.width = 410

    main_table.add {type = 'label', caption = 'Select a template'}
    local selection_flow = main_table.add {type = 'flow', direction = 'horizontal'}

    local radio =
        selection_flow.add({type = 'flow'}).add {
        type = 'radiobutton',
        name = template_radio,
        caption = 'Vanilla',
        state = false
    }

    Gui.set_data(radio, frame)

    radio =
        selection_flow.add({type = 'flow'}).add {
        type = 'radiobutton',
        name = template_radio,
        caption = 'Modded',
        state = false
    }

    Gui.set_data(radio, frame)

    main_table.add {type = 'label', caption = 'Editable Server Tags'}
    local server_tags = main_table.add {type = 'text-box', text = 'Select a template first'}
    server_tags.read_only = false
    server_tags.word_wrap = false
    server_tags.style.horizontally_stretchable = true
    server_tags.style.height = 250
    server_tags.style.width = 410
    --server_tags.scroll_to_top()

    local button_flow = main_table.add {type = 'flow', direction = 'horizontal'}

    local left_flow = button_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local generate_tag_button = left_flow.add {type = 'button', name = generate_tags, caption = 'Generate Tags'}
    Gui.set_data(generate_tag_button, frame)

    main_table.add {type = 'label', caption = 'Generated Server Tags (Reopen this gui to reset to the template)'}
    local generated_server_tags = main_table.add {type = 'text-box', text = "Press the 'Generate Tags' button to generate the tags"} --prepair_tags(all_desc_info)
    generated_server_tags.read_only = true
    generated_server_tags.word_wrap = false
    generated_server_tags.style.horizontally_stretchable = true
    generated_server_tags.style.height = 40
    generated_server_tags.style.width = 410
    --generated_server_tags.scroll_to_left()
    Gui.set_data(generated_server_tags, frame)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = Gui.make_close_button(left_flow, close_gui)
    Gui.set_data(close_button, frame)

    local data = {
        server_tags = server_tags,
        generated_server_tags = generated_server_tags,
    }

    Gui.set_data(frame, data)
end

Gui.on_click(
    template_radio,
    function(event)
        local radio = event.element
        local frame = Gui.get_data(radio)
        local frame_data = Gui.get_data(frame)
        local focus = frame_data.focus

        if focus then
            frame_data.focus.state = false
        end
        radio.state = true
        frame_data.focus = radio

        desc_map_primary_credit_info = generate_desc_map_primary_credit_info()
        desc_map_secondary_credit_info = generate_desc_map_secondary_credit_info()

        if radio.caption == 'Modded' then
            frame_data.server_tags.text = desc_info .. desc_community_info .. desc_modded_info .. desc_map_primary_credit_info .. desc_map_secondary_credit_info .. desc_donate_info .. desc_contribute_info
        elseif radio.caption == 'Vanilla' then
            frame_data.server_tags.text = desc_info .. desc_community_info .. desc_map_primary_credit_info .. desc_map_secondary_credit_info .. desc_donate_info .. desc_contribute_info
        end
    end
)

Gui.on_click(
    generate_tags,
    function(event)
        local frame = Gui.get_data(event.element)
        local frame_data = Gui.get_data(frame)

        frame_data.generated_server_tags.text = prepair_tags(frame_data.server_tags.text)
    end
)

Gui.on_click(
    close_gui,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    gui_frame,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

local function generate_desc_command(_, player)
    local event = {player = player}
    draw_gui(event)
end

Command.add(
    'generate_desc',
    {
        description = 'Generates server name, description and tags to be pasted into the /config gui',
        capture_excess_arguments = false,
        allowed_by_server = false,
        required_rank = Ranks.admin
    },
    generate_desc_command
)
