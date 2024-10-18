local Gui = require 'utils.gui'
local Toast = require 'features.gui.toast'
local Color = require 'resources.color_presets'

local Public = {}

local find_outpost_name = Gui.uid_name()

function Public.do_outpost_toast(market, message)
    Toast.toast_all_players_template(
        15,
        function(container)
            local sprite =
                container.add {
                type = 'sprite-button',
                name = find_outpost_name,
                sprite = 'utility/search_icon',
                style = 'slot_button'
            }

            Gui.set_data(sprite, { position = market.position, surface_index = market.surface.index })

            local label =
                container.add {
                type = 'label',
                name = Toast.close_toast_name,
                caption = message
            }
            local label_style = label.style
            label_style.single_line = false
            label_style.font_color = Color.lawn_green
        end
    )
end

Gui.on_click(
    find_outpost_name,
    function(event)
        local player = event.player
        local element = event.element
        local data = Gui.get_data(element)

        player.set_controller{
            type = defines.controllers.remote,
            position = data.position,
            surface = data.surface_index
        }
    end
)

return Public
