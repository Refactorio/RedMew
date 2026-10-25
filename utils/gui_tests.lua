local Declare = require 'utils.test.declare'
local Gui = require 'utils.gui'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'

-- A side panel of the tests' own, with a toggle the way a top button's handler toggles one.
local TEST_PANEL = 'gui_tests_panel'
local TEST_TOGGLE = 'gui_tests_panel_toggle'
Gui.on_click(TEST_TOGGLE, function(event)
    local panel = Gui.get_panel(event.player, TEST_PANEL)
    if panel then
        panel.destroy()
    else
        Gui.add_panel(event.player, { name = TEST_PANEL, caption = 'Test panel', toggle_name = TEST_TOGGLE, width = 'narrow' })
    end
end)

Declare.module({'utils', 'Gui'}, function()
    Declare.module('can toggle top buttons', function()
        -- uses a player's GUI
        Declare.tags('skip-headless')

        local function count_gui_elements(player)
            local roots = {Gui.get_top_flow(player), Gui.get_left_flow(player), player.gui.center, player.gui.screen}
            local count = 0
            for _, root in pairs(roots) do
                for _, child in pairs(root.children) do
                    -- Only visible elements count as open: a GUI can hide its frame on
                    -- close instead of destroying it.
                    if child.visible then
                        count = count + 1
                    end
                end
            end
            return count
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

                -- Elements owned by other mods (see mod compatibility in utils/gui.lua) only
                -- exist when those mods are active, skip the test when they don't.
                if not element or not element.valid then
                    return
                end

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

    Declare.module('windows', function()
        -- uses a player's GUI
        Declare.tags('skip-headless')

        local WINDOW = 'gui_tests_window'
        local CLOSE = 'gui_tests_window_close'

        local function open(context)
            local frame, close_button = Gui.add_window(context.player, { name = WINDOW, caption = 'Test window', close_button_name = CLOSE })
            context:add_teardown(function()
                if frame.valid then
                    frame.destroy()
                end
            end)
            return frame, close_button
        end

        Declare.test('a window opens in the middle of the screen with a title bar to drag it by', function(context)
            -- Act
            local frame, close_button = open(context)

            -- Assert
            Assert.equal(context.player.gui.screen, frame.parent)
            Assert.is_true(frame.auto_center, 'the window should open in the middle')
            local title_bar = frame.children[1]
            local title = title_bar.children[1]
            Assert.equal('Test window', title.caption)
            Assert.equal(frame, title.drag_target, 'the title should drag the window')
            Assert.equal(title_bar, close_button.parent, 'the X should be in the title bar')
            Assert.equal(CLOSE, close_button.name)
        end)
    end)

    Declare.module('side panels', function()
        -- uses a player's GUI
        Declare.tags('skip-headless')

        local function header_button(panel, name)
            for _, child in pairs(panel.children[1].children) do
                if child.name == name then
                    return child
                end
            end
        end

        -- Opens the test panel docked, as a player who never floated it, and closes it after.
        local function open_docked(context)
            local player = context.player
            local floating = Gui.floating_panels()
            local player_index = player.index
            floating[player_index] = floating[player_index] or {}
            floating[player_index][TEST_PANEL] = nil
            context:add_teardown(function()
                floating[player_index][TEST_PANEL] = nil
                local locations = Gui.panel_locations()[player_index]
                if locations then
                    locations[TEST_PANEL] = nil
                end
                local panel = Gui.get_panel(player, TEST_PANEL)
                if panel then
                    panel.destroy()
                end
            end)
            return Gui.add_panel(player, { name = TEST_PANEL, caption = 'Test panel', toggle_name = TEST_TOGGLE, width = 'narrow' })
        end

        local function pin_name(panel)
            -- the pin is the first sprite button in the header
            for _, child in pairs(panel.children[1].children) do
                if child.type == 'sprite-button' then
                    return child.name
                end
            end
        end

        Declare.test('a panel opens docked on the side with its title and a pin, and no X', function(context)
            -- Act
            local panel, content = open_docked(context)

            -- Assert
            Assert.equal(Gui.get_left_flow(context.player), panel.parent, 'the panel should be docked on the side')
            Assert.equal('Test panel', panel.children[1].children[1].caption)
            Assert.is_true(pin_name(panel) ~= nil, 'the panel should have a pin')
            Assert.is_true(header_button(panel, TEST_TOGGLE) == nil, 'a docked panel closes from its top button, not an X')
            Assert.equal(panel, content.parent, 'the content should be inside the panel')
            Assert.equal(panel, Gui.get_panel(context.player, TEST_PANEL))
        end)

        Declare.test('the pin floats a docked panel into a window with an X, and docks it again', function(context)
            -- Arrange
            local player = context.player
            local panel = open_docked(context)

            -- Act
            Helper.click(header_button(panel, pin_name(panel)))

            -- Assert
            panel = Gui.get_panel(player, TEST_PANEL)
            Assert.is_true(panel ~= nil, 'the panel should still be open')
            Assert.equal(player.gui.screen, panel.parent, 'the panel should be floating')
            Assert.equal(panel, panel.children[1].children[1].drag_target, 'the title should drag the floating panel')
            Assert.is_true(header_button(panel, TEST_TOGGLE) ~= nil, 'a floating panel should have an X')

            -- Act: and back
            Helper.click(header_button(panel, pin_name(panel)))

            -- Assert
            panel = Gui.get_panel(player, TEST_PANEL)
            Assert.equal(Gui.get_left_flow(player), panel.parent, 'the panel should be docked again')
        end)

        Declare.test('a floating panel the player moved reopens where they left it', function(context)
            -- Arrange
            local player = context.player
            local panel = open_docked(context)
            Helper.click(header_button(panel, pin_name(panel)))
            panel = Gui.get_panel(player, TEST_PANEL)
            panel.location = { x = 40, y = 50 }
            EventFactory.raise({ name = defines.events.on_gui_location_changed, tick = game.tick, player_index = player.index, element = panel })
            Helper.click(header_button(panel, TEST_TOGGLE))

            -- Act
            panel = Gui.add_panel(player, { name = TEST_PANEL, caption = 'Test panel', toggle_name = TEST_TOGGLE, width = 'narrow' })

            -- Assert
            Assert.equal(40, panel.location.x)
            Assert.equal(50, panel.location.y)
            Assert.is_true(not panel.auto_center, 'the panel should not move back to the middle')
        end)

        Declare.test('the X closes a floating panel', function(context)
            -- Arrange
            local player = context.player
            local panel = open_docked(context)
            Helper.click(header_button(panel, pin_name(panel)))
            panel = Gui.get_panel(player, TEST_PANEL)

            -- Act
            Helper.click(header_button(panel, TEST_TOGGLE))

            -- Assert
            Assert.is_true(Gui.get_panel(player, TEST_PANEL) == nil, 'the panel should have closed')
        end)
    end)
end)
