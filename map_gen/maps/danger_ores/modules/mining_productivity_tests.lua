-- In-game tests for replacing mining productivity. These run on every Danger Ores map with it
-- enabled (the default): researching mining productivity gives robot cargo size instead, and so
-- does resetting the technology effects, which Factorio does when mods or the game version
-- change. With replace off, the research is disabled instead.
--
-- They research on the player force from script, which raises the research events like a lab.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'

local config = DOC.disable_mining_productivity
if not config.enabled then
    return
end

local TECH = 'mining-productivity-1'

Declare.module(
    {'map_gen', 'danger ores', 'mining productivity'},
    function()
        if not config.replace then
            Declare.test(
                'mining productivity cannot be researched',
                function()
                    -- Assert: the map's setup turned it off
                    Assert.is_true(not game.forces.player.technologies[TECH].enabled, TECH .. ' is enabled')
                end
            )
            return
        end

        -- the force, the technology and the bonuses before researching it, all put back afterwards
        local function prepare(context)
            local force = game.forces.player
            local tech = force.technologies[TECH]
            local mining, cargo = force.mining_drill_productivity_bonus, force.worker_robots_storage_bonus
            Assert.is_true(not tech.researched, TECH .. ' was already researched')
            context:add_teardown(function()
                tech.researched = false
                force.mining_drill_productivity_bonus = mining
                force.worker_robots_storage_bonus = cargo
            end)
            return force, tech, mining, cargo
        end

        Declare.test(
            'researching mining productivity gives robot cargo size instead',
            function(context)
                -- Arrange
                local force, tech, mining, cargo = prepare(context)

                -- Act
                tech.researched = true

                -- Assert
                Assert.equal(mining, force.mining_drill_productivity_bonus, 'mining productivity after researching ' .. TECH)
                Assert.equal(cargo + 1, force.worker_robots_storage_bonus, 'robot cargo size after researching ' .. TECH)
            end
        )

        Declare.test(
            'resetting technology effects keeps mining productivity as robot cargo size',
            function(context)
                -- Arrange
                local force, tech, mining, cargo = prepare(context)
                tech.researched = true

                -- Act
                force.reset_technology_effects()

                -- Assert
                Assert.equal(mining, force.mining_drill_productivity_bonus, 'mining productivity after the reset')
                Assert.equal(cargo + 1, force.worker_robots_storage_bonus, 'robot cargo size after the reset')
            end
        )
    end
)
