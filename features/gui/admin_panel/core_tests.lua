-- Tests for features.gui.admin_panel.core, discovered when the admin panel is enabled. They open
-- the panel for a player, so they need one.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local AdminPanel = require 'features.gui.admin_panel.core'

Declare.module({ 'features', 'gui', 'admin panel' }, function()
    -- uses a player's GUI
    Declare.tags('skip-headless')

    local name = AdminPanel._main_frame_name

    Declare.test('the panel opens on its first page', function(context)
        -- Arrange
        local player = context.player
        if player.gui.screen[name] then
            AdminPanel.toggle_main_button(player)
        end
        context:add_teardown(function()
            if player.gui.screen[name] then
                AdminPanel.toggle_main_button(player)
            end
        end)

        -- Act
        AdminPanel.toggle_main_button(player)

        -- Assert
        local toggled = {}
        local first
        for i, button in pairs(player.gui.screen[name].flow.left.children[1].children[1].children) do
            if button.toggled then
                toggled[#toggled + 1] = i
            end
            if button.visible and not first then
                first = i
            end
        end
        Assert.equal(1, #toggled, 'pages shown as open: ' .. serpent.line(toggled))
        Assert.equal(first, toggled[1], 'the page shown as open is not the first one')
        Assert.is_true(#AdminPanel.get_canvas(player).children > 0, 'the page is empty')
    end)
end)
