local Gui = require 'utils.gui'
local Command = require 'utils.command'

local rich_text_frame = Gui.uid_name()
local rich_text_choose_image = Gui.uid_name()
local rich_text_image_type = Gui.uid_name()
local close_rich_text = Gui.uid_name()

local choices = {
    'item',
    'tile',
    'entity',
    'signal',
    'fluid',
    'recipe',
    'decorative',
    'item-group',
    'achievement',
    'equipment',
    'technology'
}
local function draw_rich_text(event)
    local sprite_type = choices[1]
    local frame_caption = 'Rich Text'
    local player = event.player
    local center = player.gui.center

    local frame = center[rich_text_frame]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
        return
    end

    frame = center.add {type = 'frame', name = rich_text_frame, caption = frame_caption, direction = 'vertical'}

    local main_table = frame.add {type = 'table', column_count = 1}

    main_table.add {type = 'label', caption = 'Image'}
    local icons_flow = main_table.add {type = 'flow', direction = 'horizontal'}
    local selection_flow = icons_flow.add {type = 'flow'}
    selection_flow.style.top_margin = 7

    local focus
    local count = 0
    for _, value in ipairs(choices) do
        count = count + 1
        if count > 6 then
            count = 0
            icons_flow = main_table.add {type = 'flow', direction = 'horizontal'}
            selection_flow = icons_flow.add {type = 'flow'}
            selection_flow.style.top_margin = 7
        end
        local radio =
            selection_flow.add({type = 'flow'}).add {
            type = 'radiobutton',
            name = rich_text_image_type,
            caption = value,
            state = value == sprite_type
        }

        if value == sprite_type then
            focus = radio
        end

        Gui.set_data(radio, frame)
    end

    local choose =
        icons_flow.add {
        type = 'choose-elem-button',
        name = rich_text_choose_image,
        elem_type = sprite_type
    }

    Gui.set_data(choose, frame)

    local string_flow = main_table.add {type = 'flow', direction = 'horizontal'}
    string_flow.style.width = 352
    string_flow.style.horizontally_stretchable = true
    local string_box = string_flow.add {type = 'text-box', text = 'Pick an image'}
    string_box.read_only = true
    string_box.style.horizontally_stretchable = true
    string_box.word_wrap = false
    string_box.style.width = 352

    Gui.set_data(string_box, frame)

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = Gui.make_close_button(left_flow, close_rich_text)
    Gui.set_data(close_button, frame)

    local data = {
        focus = focus,
        choose = choose,
        icons_flow = icons_flow,
        string_flow = string_flow,
        string_box = string_box
    }
    Gui.set_data(frame, data)

    player.opened = frame
end

Gui.on_click(
    rich_text_image_type,
    function(event)
        local radio = event.element
        local frame = Gui.get_data(radio)
        local frame_data = Gui.get_data(frame)

        frame_data.focus.state = false
        radio.state = true
        frame_data.focus = radio

        local choose = frame_data.choose
        Gui.remove_data_recursively(choose)
        choose.destroy()

        choose =
            frame_data.icons_flow.add {
            type = 'choose-elem-button',
            name = rich_text_choose_image,
            elem_type = radio.caption
        }
        Gui.set_data(choose, frame)

        frame_data.choose = choose
    end
)

Gui.on_click(
    close_rich_text,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_custom_close(
    rich_text_frame,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

Gui.on_elem_changed(
    rich_text_choose_image,
    function(event)
        local choose = event.element
        local frame = Gui.get_data(choose)
        local frame_data = Gui.get_data(frame)

        local type = frame_data.focus.caption
        local sprite = choose.elem_value

        local path
        local text
        if not sprite or sprite == '' then
            text = 'Pick an image'
        elseif type == 'signal' then
            local name = sprite.name
            if string.sub(name, 1, 6) == 'signal' then
                path = 'virtual-signal/' .. name
            else
                text = 'Pick a signal or another image type'
            end
        else
            path = type .. '/' .. sprite
        end

        if not text then
            text = '[img=' .. path .. '] | ' .. path
        end

        local string_box = frame_data.string_box
        Gui.remove_data_recursively(string_box)
        string_box.destroy()

        string_box = frame_data.string_flow.add {type = 'text-box', text = text}
        string_box.read_only = true
        string_box.word_wrap = false
        string_box.style.width = 352

        frame_data.string_box = string_box
    end
)

local function rich_text_command(_, player)
    local event = {player = player}
    draw_rich_text(event)
end

Command.add(
    'rich-text',
    {
        description = 'Opens rich text gui',
        capture_excess_arguments = false,
        allowed_by_server = false
    },
    rich_text_command
)
