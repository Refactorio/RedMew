-- In-game tests for the extra technology unlocks. These run under _DEBUG via /test-runner on
-- every Danger Ores map with them enabled (the default): researching a technology in the list
-- (uranium mining, oil gathering...) also researches the ones it unlocks.
--
-- They research on the player force from script, which raises the research events like a lab.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local DOC = require 'map_gen.maps.danger_ores.configuration'

local config = DOC.technologies
if not (config.enabled and config.unlocks and next(config.unlocks)) then
    return
end

Declare.module(
    {'map_gen', 'danger ores', 'technologies'},
    function()
        for name, unlocks in pairs(config.unlocks) do
            Declare.test(
                'researching ' .. name .. ' also researches ' .. table.concat(unlocks, ', '),
                function(context)
                    -- Arrange
                    local techs = game.forces.player.technologies
                    local tech = techs[name]
                    Assert.is_true(tech ~= nil, 'there is no ' .. name .. ' technology')
                    Assert.is_true(not tech.researched, name .. ' was already researched')
                    context:add_teardown(function()
                        for _, unlock in pairs(unlocks) do
                            if techs[unlock] then
                                techs[unlock].researched = false
                            end
                        end
                        tech.researched = false
                    end)

                    -- Act
                    tech.researched = true

                    -- Assert
                    for _, unlock in pairs(unlocks) do
                        if techs[unlock] then
                            Assert.is_true(techs[unlock].researched, unlock .. ' is not researched after ' .. name)
                        end
                    end
                end
            )
        end
    end
)
