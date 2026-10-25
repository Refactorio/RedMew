-- In-game tests for the Retailer's market window.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Retailer = require 'features.retailer'

Declare.module({'features', 'retailer'}, function()
    -- uses a player's character and GUI
    Declare.tags('skip-headless')

    -- Puts a market `edge_distance` tiles east of the player's character, measured to the market's
    -- near edge the way Factorio measures reach, opens it the way clicking it does, and calls
    -- `check` on the next tick, once the Retailer has handled the opening.
    local function open_market_at(context, edge_distance, check)
        local player = context.player
        local character = player.character
        Assert.is_true(character ~= nil, 'the player needs a character')

        local half_width = prototypes.entity['market'].selection_box.right_bottom.x
        local position = character.position
        local market = character.surface.create_entity {
            name = 'market',
            position = {position.x + edge_distance + half_width, position.y},
            force = 'neutral'
        }
        local group = Retailer.generate_group_id()
        Retailer.add_market(group, market)
        Retailer.set_market_group_label(group, 'Test market')
        context:add_teardown(function()
            player.opened = nil
            if market.valid then
                market.destroy()
            end
        end)

        -- Act
        player.opened = market

        context:next(function()
            check(player, market)
        end)
    end

    Declare.test('a market whose edge is within reach stays open', function(context)
        -- Arrange: past 1.05 times the reach from the market's centre, but its edge is within reach
        local reach = context.player.character.reach_distance

        open_market_at(context, reach - 0.5, function(player)
            -- Assert
            Assert.equal(defines.gui_type.custom, player.opened_gui_type, 'the market window should be open')
        end)
    end)

    Declare.test('a market out of reach of the character closes in remote view', function(context)
        -- Arrange: in remote view over the market, which the player can see but their character
        -- can't reach
        local player = context.player
        local reach = player.character.reach_distance
        local distance = reach + 20
        local position = player.character.position
        player.set_controller {
            type = defines.controllers.remote,
            position = {position.x + distance, position.y}
        }
        context:add_teardown(function()
            player.exit_remote_view()
        end)

        open_market_at(context, distance, function()
            -- Assert
            Assert.is_true(player.opened == nil, 'the market window should have closed')
        end)
    end)

    Declare.test('a market out of reach closes', function(context)
        -- Arrange
        local reach = context.player.character.reach_distance

        open_market_at(context, reach + 1, function(player)
            -- Assert
            Assert.is_true(player.opened == nil, 'the market window should have closed')
        end)
    end)
end)
