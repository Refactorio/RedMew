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

    -- Floating with its side strip, the header and content are in a column beside the strip.
    local function body_of(panel)
        if panel.direction == 'horizontal' then
            return panel.children[1]
        end
        return panel
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

        Declare.test('the HUD shows its numbers on a dark inner frame, ' .. where, function(context)
            -- Act
            local panel = open(context, floating)

            -- Assert
            Assert.equal('inside_deep_frame', body_of(panel).children[2].style.name, 'inner frame')
        end)
    end

    Declare.test('the floating HUD is dragged by a strip down its side, which leaves its title room', function(context)
        -- Act
        local panel = open(context, true)

        -- Assert
        local strip = panel.children[#panel.children]
        Assert.equal('empty-widget', strip.type, 'the last element should be the strip')
        Assert.equal(panel, strip.drag_target, 'the strip should drag the HUD')
    end)
end)
