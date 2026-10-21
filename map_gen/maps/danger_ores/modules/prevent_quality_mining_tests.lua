-- In-game tests for preventing quality mining. These run under _DEBUG via /test-runner on Danger
-- Ores maps with it enabled (the default) and quality in the game (Space Age): a mining drill
-- above normal quality is removed when built on ore, and a normal one stays.
--
-- They build on the real map's ore and raise the build event the way Factorio would. One drill
-- is built by real robots from a ghost, so the game's own build event and refund run too.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

if not prototypes.quality['rare'] then
    return
end

local DRILL = 'electric-mining-drill'

Declare.module(
    {'map_gen', 'danger ores', 'prevent quality mining'},
    function()
        local function build_on_ore(quality)
            local surface = RS.get_surface()
            local p = H.ore_spot(surface, DRILL)
            Assert.is_true(p ~= nil, 'no ore near spawn to build on')
            local drill = surface.create_entity {name = DRILL, position = p, force = 'player', quality = quality}
            Assert.valid(drill, 'the test drill was not created')
            EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = drill}
            return drill
        end

        Declare.test(
            'a quality mining drill on ore is removed',
            function()
                local drill = build_on_ore('rare')
                Assert.is_true(not drill.valid, 'a rare ' .. DRILL .. ' on ore is still there')
            end
        )

        Declare.test(
            'a quality mining drill real robots build on ore goes back to storage at its quality',
            function(context)
                local surface = RS.get_surface()
                local p = H.ore_spot(surface, DRILL)
                Assert.is_true(p ~= nil, 'no ore near spawn to build on')
                local rare = {name = DRILL, quality = 'rare'}
                local storage, remove_network = Helper.robot_network(surface, {x = p.x + 8, y = p.y}, {{name = DRILL, count = 1, quality = 'rare'}})
                context:add_teardown(remove_network)
                local ghost = surface.create_entity {name = 'entity-ghost', inner_name = DRILL, position = p, force = 'player', quality = 'rare'}
                Assert.valid(ghost, 'the test drill ghost was not placed')
                local area = {{p.x - 2, p.y - 2}, {p.x + 2, p.y + 2}}

                Helper.wait_until(context, 1800, function()
                    return not ghost.valid and storage.get_item_count(rare) == 1
                end, function(ok)
                    local built = surface.count_entities_filtered {area = area, name = DRILL}
                    Assert.is_true(ok, 'the rare ' .. DRILL .. ' robots built on ore at ' .. p.x .. ',' .. p.y .. ' did not come back: ghost there ' .. tostring(ghost.valid) .. ', built ' .. built .. ', rare in storage ' .. storage.get_item_count(rare))
                    Assert.equal(0, built, DRILL .. 's left on ore')
                end)
            end
        )

        Declare.test(
            'a normal mining drill on ore stays',
            function()
                local drill = build_on_ore('normal')
                Assert.is_true(drill.valid, 'a normal ' .. DRILL .. ' on ore was removed')
                drill.destroy()
            end
        )
    end
)
