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
    local frame = player.gui.screen[rich_text_frame]
    if frame then
        Gui.remove_data_recursively(frame)
        frame.destroy()
        return
    end

    local content, title_close_button
    frame, content, title_close_button = Gui.add_dialog(player, {name = rich_text_frame, caption = frame_caption, close_button_name = close_rich_text})
    Gui.set_data(title_close_button, frame)

    local main_flow = content.add {type = 'flow', direction = 'vertical'}

    main_flow.add {type = 'label', caption = 'Image'}
    local choices_table = main_flow.add {type = 'table', column_count = 4}
    Gui.set_style(choices_table, {horizontal_spacing = 16, vertical_spacing = 8})
    for i = 1, 4 do
        choices_table.style.column_alignments[i] = 'middle-left'
    end

    local focus
    for _, value in ipairs(choices) do
        -- Each in a flow of its own, as siblings can't share the radio buttons' name.
        local radio =
            choices_table.add({type = 'flow'}).add {
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

    -- The picker takes the 12th place, after the 11 choices. Its type can't change, so a new one
    -- replaces it in this flow when another choice is picked.
    local choose_flow = choices_table.add {type = 'flow'}
    local choose =
        choose_flow.add {
        type = 'choose-elem-button',
        name = rich_text_choose_image,
        elem_type = sprite_type,
        style = 'slot_button_in_shallow_frame'
    }

    Gui.set_data(choose, frame)

    local string_box = main_flow.add {type = 'text-box', text = 'Pick an image'}
    string_box.read_only = true
    string_box.word_wrap = false
    Gui.set_style(string_box, {horizontally_stretchable = true, maximal_width = 10000})

    local data = {
        focus = focus,
        choose = choose,
        choose_flow = choose_flow,
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
            frame_data.choose_flow.add {
            type = 'choose-elem-button',
            name = rich_text_choose_image,
            elem_type = radio.caption,
            style = 'slot_button_in_shallow_frame'
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

        frame_data.string_box.text = text
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
