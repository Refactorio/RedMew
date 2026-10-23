-- In-game tests for Toxic Jungle. These run when it is the active map: spawn is ringed by dense
-- jungle with the water turned green, and there are no flamethrowers to burn it with, neither
-- from research nor from the market.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Retailer = require 'features.retailer'
local RS = require 'map_gen.shared.redmew_surface'

Declare.module(
    {'map_gen', 'toxic jungle'},
    function()
        Declare.test(
            'spawn is ringed by dense jungle',
            function()
                -- Act
                local surface = RS.get_surface()
                surface.request_to_generate_chunks({0, 0}, 3)
                surface.force_generate_chunk_requests()

                -- Assert: a tree is tried on every tile within 100 of spawn, bar the middle
                local trees = surface.count_entities_filtered {position = {0, 0}, radius = 64, type = 'tree'}
                local ground = surface.count_tiles_filtered {position = {0, 0}, radius = 64, collision_mask = 'ground_tile'}
                Assert.is_true(trees > ground / 20, 'only ' .. trees .. ' trees on ' .. ground .. ' ground tiles within 64 of spawn')
                Assert.equal(0, surface.count_tiles_filtered {position = {0, 0}, radius = 96, name = {'water', 'deepwater'}}, 'plain water tiles near spawn')
            end
        )

        Declare.test(
            'researching flamethrowers does not unlock them',
            function(context)
                -- Arrange
                local force = game.forces.player
                local tech = force.technologies['flamethrower']
                Assert.is_true(not tech.researched, 'flamethrower was already researched')
                context:add_teardown(function()
                    tech.researched = false
                end)

                -- Act
                tech.researched = true

                -- Assert
                Assert.is_true(not force.recipes['flamethrower'].enabled, 'the flamethrower recipe is enabled')
                Assert.is_true(not force.recipes['flamethrower-turret'].enabled, 'the flamethrower turret recipe is enabled')
            end
        )

        Declare.test(
            'the market sells no flamethrowers',
            function()
                -- Assert: the market as the map set it up
                local items = Retailer.get_items('fish_market')
                Assert.is_true(next(items) ~= nil, 'the spawn market sells nothing')
                for name in pairs(items) do
                    Assert.is_true(not name:find('flamethrower'), 'the market sells ' .. name)
                end
            end
        )
    end
)
