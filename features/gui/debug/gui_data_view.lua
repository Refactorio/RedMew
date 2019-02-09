local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'
local Model = require 'features.gui.debug.model'
local Game = require 'utils.game'

local dump = Model.dump
local dump_text = Model.dump_text
local concat = table.concat

local Public = {}

local header_name = Gui.uid_name()
local left_panel_name = Gui.uid_name()
local right_panel_name = Gui.uid_name()

Public.name = 'Gui Data'

function Public.show(container)
    local main_flow = container.add {type = 'flow', direction = 'horizontal'}

    local left_panel = main_flow.add {type = 'scroll-pane', name = left_panel_name}
    local left_panel_style = left_panel.style
    left_panel_style.width = 300

    for player_index, values in pairs(Gui.data) do
        local player = Game.get_player_by_index(player_index)
        local player_name
        if not player then
            player_name = 'invalid player'
        else
            player_name = player.name
        end

        local header =
            left_panel.add({type = 'flow'}).add {
            type = 'label',
            name = header_name,
            caption = concat({player_index, ' - ', player_name})
        }
        Gui.set_data(header, values)
    end

    local right_flow = main_flow.add {type = 'flow', direction = 'vertical'}

    local right_panel = right_flow.add {type = 'text-box', name = right_panel_name}
    right_panel.word_wrap = true
    right_panel.read_only = true
    right_panel.selectable = true

    local right_panel_style = right_panel.style
    right_panel_style.vertically_stretchable = true
    right_panel_style.horizontally_stretchable = true

    local data = {
        right_panel = right_panel,
        selected_header = nil
    }

    Gui.set_data(left_panel, data)
end

Gui.on_click(
    header_name,
    function(event)
        local element = event.element
        local values = Gui.get_data(element)

        local left_panel = element.parent.parent
        local data = Gui.get_data(left_panel)
        local right_panel = data.right_panel
        local selected_header = data.selected_header

        if selected_header then
            selected_header.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        data.selected_header = element

        local content = dump(values) or 'nil'
        right_panel.text = content
    end
)

return Public
