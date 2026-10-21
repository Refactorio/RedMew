-- In-game tests for Safety Ores, the Danger Ores preset where buildings must stand on ore. These
-- run under _DEBUG via /test-runner when it is the active map: a building off ore is removed and
-- its item handed back, the same building on ore stays, poles stay anywhere but belts don't, and
-- a new pumpjack gets a square of stone round it so the oil can be defended.
--
-- They build on the real map and raise the build event the way Factorio would. The refund goes
-- to a player, so it is read from the restriction module's pre-destroy event instead. One
-- building is built by real robots from a ghost, so the game's own build event and refund run too.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local EventFactory = require 'utils.test.event_factory'
local Event = require 'utils.event'
local RE = require 'map_gen.shared.entity_placement_restriction'
local H = require 'map_gen.maps.danger_ores.modules.terrain_test_helper'
local RS = require 'map_gen.shared.redmew_surface'

local SAFETY_RADIUS = 7 -- as in the preset: the stone square is 15 tiles across

-- what the restriction module last said it was about to destroy (and refund)
local last_pre_destroy
Event.add(RE.events.on_pre_restricted_entity_destroyed, function(event)
    last_pre_destroy = event
end)

Declare.module(
    {'map_gen', 'safety ores'},
    function()
        local function build(name, p, extra)
            local surface = RS.get_surface()
            local spec = {name = name, position = p, force = 'player'}
            for k, v in pairs(extra or {}) do
                spec[k] = v
            end
            local entity = surface.create_entity(spec)
            Assert.valid(entity, 'the test ' .. name .. ' was not created')
            last_pre_destroy = nil
            EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = entity}
            return entity
        end

        Declare.test(
            'a building off ore is removed and handed back',
            function()
                local p = H.dry_spot(RS.get_surface(), 'iron-chest')
                Assert.is_true(p ~= nil, 'no ore-free ground near spawn')

                local chest = build('iron-chest', p)

                Assert.is_true(not chest.valid, 'the iron chest built off ore at ' .. p.x .. ',' .. p.y .. ' is still there')
                Assert.is_true(last_pre_destroy ~= nil, 'the restriction module did not say it was destroying anything')
                Assert.equal('iron-chest', last_pre_destroy.stack.name, 'item handed back')
            end
        )

        Declare.test(
            'a building real robots build off ore goes back to storage',
            function(context)
                local surface = RS.get_surface()
                local p = H.dry_spot(surface, 'iron-chest')
                Assert.is_true(p ~= nil, 'no ore-free ground near spawn')
                local storage, remove_network = Helper.robot_network(surface, {x = p.x + 8, y = p.y}, {{name = 'iron-chest', count = 1}})
                context:add_teardown(remove_network)
                local ghost = surface.create_entity {name = 'entity-ghost', inner_name = 'iron-chest', position = p, force = 'player'}
                Assert.valid(ghost, 'the test iron chest ghost was not placed')
                local area = {{p.x - 1, p.y - 1}, {p.x + 1, p.y + 1}}

                Helper.wait_until(context, 1800, function()
                    return not ghost.valid and storage.get_item_count('iron-chest') == 1
                end, function(ok)
                    local built = surface.count_entities_filtered {area = area, name = 'iron-chest'}
                    Assert.is_true(ok, 'the iron chest robots built off ore at ' .. p.x .. ',' .. p.y .. ' did not come back: ghost there ' .. tostring(ghost.valid) .. ', built ' .. built .. ', in storage ' .. storage.get_item_count('iron-chest'))
                    Assert.equal(0, built, 'iron chests left off ore')
                end)
            end
        )

        Declare.test(
            'the same building on ore stays',
            function()
                local p = H.ore_spot(RS.get_surface(), 'iron-chest')
                Assert.is_true(p ~= nil, 'no ore near spawn to build on')

                local chest = build('iron-chest', p)

                Assert.is_true(chest.valid, 'the iron chest built on ore at ' .. p.x .. ',' .. p.y .. ' was removed')
                chest.destroy()
            end
        )

        Declare.test(
            'poles stay off ore, belts do not',
            function()
                local surface = RS.get_surface()
                local p = H.dry_spot(surface, 'small-electric-pole')
                Assert.is_true(p ~= nil, 'no ore-free ground near spawn')
                local pole = build('small-electric-pole', p)
                Assert.is_true(pole.valid, 'a pole built off ore was removed')
                pole.destroy()

                p = H.dry_spot(surface, 'transport-belt')
                local belt = build('transport-belt', p)
                Assert.is_true(not belt.valid, 'a belt built off ore is still there')
            end
        )

        Declare.test(
            'a new pumpjack gets a square of stone round it',
            function()
                local surface = RS.get_surface()
                local p = H.dry_spot(surface, 'pumpjack')
                Assert.is_true(p ~= nil, 'no ore-free ground near spawn')
                -- no ore where the square will go, so all the stone in it is the square's
                local clear = SAFETY_RADIUS + 3
                for _, ore in pairs(surface.find_entities_filtered {area = {{p.x - clear, p.y - clear}, {p.x + clear, p.y + clear}}, type = 'resource'}) do
                    ore.destroy()
                end
                -- a pumpjack needs oil under it
                local oil = surface.create_entity {name = 'crude-oil', position = p, amount = 100000}
                Assert.valid(oil, 'the test oil was not created')
                local before = surface.count_entities_filtered {position = p, radius = 16, name = 'stone'}

                local pumpjack = build('pumpjack', p)

                -- Assert: stone on every ground tile of the square centred on the pumpjack
                Assert.is_true(pumpjack.valid, 'the pumpjack was removed')
                local box = pumpjack.bounding_box
                local cx = math.floor((box.left_top.x + box.right_bottom.x) / 2)
                local cy = math.floor((box.left_top.y + box.right_bottom.y) / 2)
                local square = {{cx - SAFETY_RADIUS, cy - SAFETY_RADIUS}, {cx + SAFETY_RADIUS + 1, cy + SAFETY_RADIUS + 1}}
                local ground = surface.count_tiles_filtered {area = square, collision_mask = 'ground_tile'}
                Assert.is_true(ground > 100, 'only ' .. ground .. ' ground tiles round the pumpjack')
                Assert.equal(ground, surface.count_entities_filtered {area = square, name = 'stone'}, 'stone round the pumpjack')
                Assert.equal(ground, surface.count_entities_filtered {position = p, radius = 16, name = 'stone'} - before, 'stone added near the pumpjack')
                pumpjack.destroy()
            end
        )
    end
)
