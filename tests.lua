local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'

Declare.module(
    'Gui top buttons',
    function()
        Declare.test(
            'can toggle',
            function(step)
                local player = game.get_player(1)
                local top_buttons = player.gui.top.children
                for _, child in pairs(top_buttons) do
                    if child.type == 'sprite-button' then
                        local event = EventFactory.on_gui_click(child, player.index)

                        -- Open
                        step =
                            step:next(
                            function()
                                EventFactory.raise(event)
                            end
                        )

                        -- Close
                        step =
                            step:next(
                            function()
                                EventFactory.raise(event)
                            end
                        )
                    end
                end
            end
        )
    end
)
