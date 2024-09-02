local Declare = require 'utils.test.declare'
local Gui = require 'utils.gui'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'

Declare.module({'utils', 'Gui'}, function()
    Declare.module('can toggle top buttons', function()
        local function count_gui_elements(player)
            -- local gui = player.gui
            -- return #gui.top.children + #gui.left.children + #gui.center.children + #gui.screen.children
            return #Gui.get_top_flow(player).children + #Gui.get_left_flow(player).children + #player.gui.center.children + #player.gui.screen.children
        end

        local function is_ignored_element(element)
            local tooltip = element.tooltip
            if type(tooltip) == 'table' and tooltip[1] == 'evolution_progress.tooltip' then
                return true
            end

            return false
        end

        for _, name in pairs(Gui._top_elements) do
            Declare.test(Gui.names and Gui.names[name] or name, function(context)
                local player = context.player
                local element = Gui.get_top_flow(player)[name]

                if not element.enabled or is_ignored_element(element) then
                    return
                end

                local click_action = function()
                    Helper.click(element)
                end

                local before_count = count_gui_elements(player)

                -- Open
                click_action()
                local after_open_count = count_gui_elements(player)
                Assert.is_true(after_open_count > before_count, 'after open count should be greater than before count.')

                -- Close
                context:next(click_action):next(function()
                    local after_close_count = count_gui_elements(player)
                    Assert.equal(before_count, after_close_count, 'after close count should be equal to before count.')
                end)
            end)
        end
    end)
end)
