-- Tests for features.gui.production_hud, discovered when the production HUD is enabled. They open
-- the HUD for a player, so they need one.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Gui = require 'utils.gui'
local ProductionHud = require 'features.gui.production_hud'

-- Factorio's minimap, top right, is this wide: a floating HUD dragged under it lines up with it.
local MINIMAP_WIDTH = 256

Declare.module({ 'features', 'gui', 'production hud' }, function()
    -- uses a player's GUI
    Declare.tags('skip-headless')

    local name = ProductionHud._main_frame_name

    -- Opens the HUD docked or floating, and closes it and forgets the choice after.
    local function open(context, floating)
        local player = context.player
        local panels = Gui.floating_panels()
        local player_index = player.index
        panels[player_index] = panels[player_index] or {}
        local panel = Gui.get_panel(player, name)
        if panel then
            ProductionHud.toggle_main_button(player)
        end
        panels[player_index][name] = floating or nil
        context:add_teardown(function()
            if Gui.get_panel(player, name) then
                ProductionHud.toggle_main_button(player)
            end
            panels[player_index][name] = nil
        end)
        ProductionHud.toggle_main_button(player)
        return Gui.get_panel(player, name)
    end

    local function count_header_buttons(panel)
        local count = 0
        for _, child in pairs(panel.children[1].children) do
            if child.type == 'sprite-button' or child.type == 'choose-elem-button' or child.type == 'drop-down' then
                count = count + 1
            end
        end
        return count
    end

    for _, floating in pairs({ false, true }) do
        local where = floating and 'floating' or 'docked'

        Declare.test('the HUD is as wide as the minimap, ' .. where, function(context)
            -- Act
            local panel = open(context, floating)

            -- Assert
            Assert.equal(MINIMAP_WIDTH, panel.style.minimal_width, 'minimal width')
            Assert.equal(MINIMAP_WIDTH, panel.style.maximal_width, 'maximal width')
        end)

        Declare.test('the HUD keeps its own buttons out of the header, so it fits that width, ' .. where, function(context)
            -- Act
            local panel = open(context, floating)

            -- Assert: only the pin, and a floating panel's X
            Assert.equal(floating and 2 or 1, count_header_buttons(panel), 'buttons in the header')
        end)
    end
end)
