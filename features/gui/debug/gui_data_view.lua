local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'
local Model = require 'features.gui.debug.model'

local dump = Model.dump
local dump_text = Model.dump_text
local concat = table.concat

local Public = {}

local player_header_name = Gui.uid_name()
local element_header_name = Gui.uid_name()
local player_panel_name = Gui.uid_name()
local element_panel_name = Gui.uid_name()
local input_text_box_name = Gui.uid_name()
local refresh_name = Gui.uid_name()
local data_panel_name = Gui.uid_name()

Public.name = 'Gui Data'

local function draw_player_headers(player_panel, selected_index)
    local selected_header = nil

    for player_index, values in pairs(Gui.data()) do
        local player = game.get_player(player_index)
        local player_name
        if not player then
            player_name = 'invalid player'
        else
            player_name = player.name
        end

        local header =
            player_panel.add({type = 'flow'}).add {
            type = 'label',
            name = player_header_name,
            caption = concat({player_index, ' - ', player_name})
        }
        Gui.set_data(header, {values = values, player_index = player_index})

        if player_index == selected_index then
            selected_header = header
        end
    end

    return selected_header
end

function Public.show(container)
    local main_flow = container.add {type = 'flow', direction = 'horizontal'}

    local player_panel = main_flow.add {type = 'scroll-pane', name = player_panel_name}
    local player_panel_style = player_panel.style
    player_panel_style.width = 200

    draw_player_headers(player_panel)

    local right_flow = main_flow.add {type = 'flow', direction = 'vertical'}

    local element_panel = right_flow.add {type = 'scroll-pane', name = element_panel_name}
    local element_panel_style = element_panel.style
    element_panel_style.horizontally_stretchable = true
    element_panel_style.height = 200

    local right_middle_flow = right_flow.add {type = 'flow', direction = 'horizontal'}

    local input_text_box = right_middle_flow.add {type = 'text-box', name = input_text_box_name}
    local input_text_box_style = input_text_box.style
    input_text_box_style.horizontally_stretchable = true
    input_text_box_style.height = 32
    input_text_box_style.maximal_width = 1000

    local refresh_button =
        right_middle_flow.add {
        type = 'sprite-button',
        name = refresh_name,
        sprite = 'utility/reset',
        tooltip = 'refresh'
    }
    local refresh_button_style = refresh_button.style
    refresh_button_style.width = 32
    refresh_button_style.height = 32

    local data_panel = right_flow.add {type = 'text-box', name = data_panel_name}
    data_panel.read_only = true
    data_panel.selectable = true

    local data_panel_style = data_panel.style
    data_panel_style.vertically_stretchable = true
    data_panel_style.horizontally_stretchable = true
    data_panel_style.maximal_width = 1000
    data_panel_style.maximal_height = 1000

    local data = {
        player_panel = player_panel,
        element_panel = element_panel,
        input_text_box = input_text_box,
        data_panel = data_panel,
        selected_player_header = nil,
        selected_element_header = nil,
        selected_player_index = nil,
        selected_element_index = nil
    }

    Gui.set_data(player_panel, data)
    Gui.set_data(element_panel, data)
    Gui.set_data(input_text_box, data)
    Gui.set_data(refresh_button, data)
end

local function draw_element_headers(element_panel, values, selected_index)
    local copy = {}
    for k, v in pairs(values) do
        copy[k] = v
    end

    local selected_header = nil
    local element_map = Gui.element_map()
    local name_map = Gui.names

    for ei, stored_data in pairs(copy) do
        local ele = element_map[ei]
        local ele_name = ''
        if ele and ele.valid then
            ele_name = ele.name
        end

        local gui_name = name_map[ele_name]
        if gui_name then
            ele_name = gui_name
        end

        if ele_name:match('%d* %- features/gui/debug') then
            goto continue
        end

        local middle_header =
            element_panel.add({type = 'flow'}).add {
            type = 'label',
            name = element_header_name,
            caption = concat({ei, ' - ', ele_name})
        }

        Gui.set_data(middle_header, {stored_data = stored_data, element_index = ei})

        if ei == selected_index then
            selected_header = middle_header
        end

        ::continue::
    end

    return selected_header
end

Gui.on_click(
    player_header_name,
    function(event)
        local element = event.element
        local header_data = Gui.get_data(element)
        local values = header_data.values
        local player_index = header_data.player_index

        local player_panel = element.parent.parent
        local data = Gui.get_data(player_panel)
        local element_panel = data.element_panel
        local selected_player_header = data.selected_player_header
        local input_text_box = data.input_text_box

        if selected_player_header then
            selected_player_header.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        data.selected_player_header = element
        data.selected_player_index = player_index
        data.selected_element_index = nil

        input_text_box.text = ''

        if not values then
            return
        end

        draw_element_headers(element_panel, values)
    end
)

Gui.on_click(
    element_header_name,
    function(event)
        local element = event.element
        local header_data = Gui.get_data(element)
        local stored_data = header_data.stored_data
        local element_index = header_data.element_index

        local player_panel = element.parent.parent
        local data = Gui.get_data(player_panel)
        local data_panel = data.data_panel
        local selected_element_header = data.selected_element_header
        local input_text_box = data.input_text_box

        if selected_element_header then
            selected_element_header.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        data.selected_element_header = element
        data.selected_element_index = element_index

        local selected_player_index = data.selected_player_index

        if selected_player_index then
            input_text_box.text =
                concat {'global.tokens[', Gui.token, '].data[', selected_player_index, '][', element_index, ']'}
        else
            input_text_box.text = 'missing player'
        end

        local content = dump(stored_data) or 'nil'
        data_panel.text = content
    end
)

local function update_dump(text_input, data, player)
    local suc, ouput = dump_text(text_input.text, player)
    if not suc then
        text_input.style.font_color = Color.red
    else
        text_input.style.font_color = Color.black
        data.data_panel.text = ouput
    end
end

Gui.on_text_changed(
    input_text_box_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)

        update_dump(element, data, event.player)
    end
)

Gui.on_click(
    refresh_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)

        local input_text_box = data.input_text_box
        local player_panel = data.player_panel
        local element_panel = data.element_panel
        local selected_player_index = data.selected_player_index
        local selected_element_index = data.selected_element_index

        Gui.clear(player_panel)
        local selected_player_header = draw_player_headers(player_panel, selected_player_index)
        data.selected_player_header = selected_player_header
        if selected_player_header then
            selected_player_header.style.font_color = Color.orange
        end

        Gui.clear(element_panel)
        if selected_player_header then
            local player_header_data = Gui.get_data(selected_player_header)
            local values = player_header_data.values

            local selected_element_header = draw_element_headers(element_panel, values, selected_element_index)
            data.selected_element_header = selected_element_header
            if selected_element_header then
                selected_element_header.style.font_color = Color.orange
                update_dump(input_text_box, data, event.player)

                return
            end
        end

        data.input_text_box.text = ''
        data.data_panel.text = ''
    end
)

return Public
