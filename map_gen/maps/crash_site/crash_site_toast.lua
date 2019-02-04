local Gui = require 'utils.gui'
local Toast = require 'features.gui.toast'
local Color = require 'resources.color_presets'

local Public = {}

local market_signal = {type = 'virtual', name = 'signal-O'}

local find_outpost_name = Gui.uid_name()

function Public.do_outpost_toast(market, outpost_name, message)
    local data = {market = market, outpost_name = outpost_name}
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

            Gui.set_data(sprite, data)

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
        local market = data.market
        local outpost_name = data.outpost_name

        player.add_custom_alert(market, market_signal, outpost_name, true)
    end
)

return Public
