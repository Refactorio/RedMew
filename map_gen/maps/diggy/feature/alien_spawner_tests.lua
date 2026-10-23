-- In-game tests for Diggy's alien spawner. These run on Diggy maps with it enabled: opening the
-- void raises enemy evolution, and far enough from spawn lets aliens out of it; near spawn it
-- doesn't.
--
-- The void is opened through Template.insert, the way digging does it.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RS = require 'map_gen.shared.redmew_surface'
local D = require 'map_gen.maps.diggy.diggy_test_helper'

-- far from spawn (aliens can come out past 40 tiles), away from the other tests' digging
local FAR = {{100, -10}, {120, 10}}
-- inside 40 tiles of spawn (margin included), west of the starting zone where no other test digs
local NEAR = {{-34, -4}, {-26, 4}}

local function around(area, margin)
    return {{area[1][1] - margin, area[1][2] - margin}, {area[2][1] + margin, area[2][2] + margin}}
end

-- aliens come out next to the tile opened
local function aliens_in(surface, area)
    return surface.count_entities_filtered {area = around(area, 4), force = 'enemy', type = {'unit', 'turret'}}
end

Declare.module(
    {'map_gen', 'diggy', 'alien spawner'},
    function()
        Declare.test(
            'opening the void far from spawn raises evolution and lets aliens out',
            function(context)
                -- Arrange
                local surface = RS.get_surface()
                local enemy = game.forces.enemy
                -- evolution also rises with time: not while this test runs
                local enemy_evolution = game.map_settings.enemy_evolution
                local time_factor = enemy_evolution.time_factor
                enemy_evolution.time_factor = 0
                local evolution = enemy.get_evolution_factor(surface)
                context:add_teardown(function()
                    enemy_evolution.time_factor = time_factor
                    D.clear_enemies(surface, around(FAR, 32))
                end)

                -- Act
                D.open(context, surface, FAR, function(opened)
                    -- Assert
                    Assert.is_true(opened >= 300, 'only ' .. opened .. ' void tiles opened')
                    Assert.is_true(enemy.get_evolution_factor(surface) > evolution, 'evolution stayed at ' .. evolution .. ' after opening ' .. opened .. ' void tiles')
                    -- each tile has a 5% chance: none in 300 is about one in five million
                    Assert.is_true(aliens_in(surface, FAR) > 0, 'no aliens came out of ' .. opened .. ' void tiles opened far from spawn')
                end)
            end
        )

        Declare.test(
            'opening the void near spawn lets no aliens out',
            function(context)
                -- Arrange: digging elsewhere can turn up a random room here: make it void again
                local surface = RS.get_surface()
                local void = {}
                for x = NEAR[1][1], NEAR[2][1] - 1 do
                    for y = NEAR[1][2], NEAR[2][2] - 1 do
                        void[#void + 1] = {name = 'out-of-map', position = {x, y}}
                    end
                end
                for _, entity in pairs(surface.find_entities_filtered {area = NEAR}) do
                    entity.destroy()
                end
                surface.set_tiles(void)
                local before = aliens_in(surface, NEAR)
                context:add_teardown(function()
                    D.clear_enemies(surface, around(NEAR, 32))
                end)

                -- Act
                D.open(context, surface, NEAR, function(opened)
                    -- Assert
                    Assert.is_true(opened >= 50, 'only ' .. opened .. ' void tiles opened')
                    Assert.equal(before, aliens_in(surface, NEAR), 'aliens near ' .. NEAR[1][1] .. ',' .. NEAR[1][2] .. ' after opening ' .. opened .. ' void tiles near spawn')
                end)
            end
        )
    end
)
