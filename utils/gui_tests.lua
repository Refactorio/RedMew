local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'
local Gui = require 'utils.gui'
local Assert = require 'utils.test.assert'

Declare.module(
    'Gui',
    function()
        Declare.module(
            'can toggle top buttons',
            function()
                local function count_gui_elements(gui)
                    return #gui.top.children + #gui.left.children + #gui.center.children
                end

                for _, name in pairs(Gui._top_elements) do
                    Declare.test(
                        Gui.names[name],
                        function(context)
                            local player = context.player
                            local element = player.gui.top[name]

                            if not element.enabled then
                                return
                            end

                            local event = EventFactory.on_gui_click(element, player.index)
                            local click_action = function()
                                EventFactory.raise(event)
                            end

                            local before_count = count_gui_elements(player.gui)

                            -- Open
                            click_action()
                            local after_open_count = count_gui_elements(player.gui)
                            Assert.is_true(
                                after_open_count > before_count,
                                'after open count should be greater than before count.'
                            )

                            -- Close
                            context:next(click_action):next(
                                function()
                                    local after_close_count = count_gui_elements(player.gui)
                                    Assert.equal(
                                        before_count,
                                        after_close_count,
                                        'after close count should be equal to before count.'
                                    )
                                end
                            )
                        end
                    )
                end
            end
        )
    end
)
