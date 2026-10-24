-- In-game bootstrap tests for Crash Site. These are only discovered when scenario.lua is
-- loaded, i.e. when a Crash Site map is active. They check that the map comes up with what the
-- rest of the scenario relies on: the spawn market and payment chests, the commands, the
-- cutscene surface, and defended outposts around spawn. Past that, they check outposts are
-- captured and make things, and that market upgrades take.
--
-- Upgrades are bought by raising the market purchase event the way the retailer does, with a
-- stand-in buyer: the market itself needs a player and their coins. /strike and /barrage are
-- called the way their commands call them, by a stand-in player with the player force, and with
-- the markers they draw for that player going nowhere: drawing for a player needs a real one.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local EventFactory = require 'utils.test.event_factory'
local Helper = require 'utils.test.helper'
local CSCommands = require 'map_gen.maps.crash_site.commands'
local OutpostBuilder = require 'map_gen.maps.crash_site.outpost_builder'
local Retailer = require 'features.retailer'
local RS = require 'map_gen.shared.redmew_surface'

local AIRSTRIKE_CHEST = CSCommands.airstrike_chest_position
local BARRAGE_CHEST = CSCommands.barrage_chest_position

-- the first ring of outposts sits one grid block (180 tiles) from spawn, give or take 59, and an
-- outpost reaches up to 33 tiles from its middle: 272 at most, so 9 chunks
local OUTPOST_REACH = 288
-- outposts are at most 11 blocks of 6 tiles across, with the market inside
local OUTPOST_RADIUS = 96
-- how far from its market an outpost's machines are counted as its own; the next outpost is a
-- grid block (180 tiles) away
local MACHINE_REACH = 48

local function generate(radius)
    local surface = RS.get_surface()
    surface.request_to_generate_chunks({0, 0}, math.ceil(radius / 32))
    surface.force_generate_chunk_requests()
    return surface
end

local function spawn_market(surface)
    local markets = surface.find_entities_filtered {area = {{-16, -16}, {16, 16}}, name = 'market'}
    Assert.equal(1, #markets, 'markets at spawn')
    return markets[1]
end

local BUYER = {name = 'test runner', index = 1, valid = true}

local function buy(group, item)
    EventFactory.raise {name = Retailer.events.on_market_purchase, tick = game.tick, item = item, count = 1, player = BUYER, group_name = group}
end

-- The outposts' magic crafters near spawn: the machines nobody can open, mine or destroy, which
-- make their product out of nothing. Grouped by the market of their outpost; some outposts make
-- things without a market, and their machines are left out.
-- @return table<string, LuaEntity[]> market group -> machines
local function outpost_machines(surface)
    local area = {{-OUTPOST_REACH, -OUTPOST_REACH}, {OUTPOST_REACH, OUTPOST_REACH}}
    local markets = surface.find_entities_filtered {area = area, name = 'market'}
    local by_group = {}
    for _, entity in pairs(surface.find_entities_filtered {area = area, type = {'assembling-machine', 'furnace'}}) do
        if not entity.operable and not entity.minable and not entity.destructible and entity.get_output_inventory() then
            local market, best
            for _, m in pairs(markets) do
                local dx, dy = m.position.x - entity.position.x, m.position.y - entity.position.y
                local d = dx * dx + dy * dy
                if not best or d < best then
                    market, best = m, d
                end
            end
            local group = market and best <= MACHINE_REACH * MACHINE_REACH and Retailer.get_market_group_name(market)
            if group then
                by_group[group] = by_group[group] or {}
                table.insert(by_group[group], entity)
            end
        end
    end
    return by_group
end

-- Counts what each group of machines makes over `ticks`, emptying them every second so none
-- fills its output slot and stops, then calls back with the count per group.
local function measure(context, by_group, ticks, callback)
    local counts = {}
    for group, machines in pairs(by_group) do
        counts[group] = 0
        for _, machine in pairs(machines) do
            machine.get_output_inventory().clear()
        end
    end
    local left = ticks
    local function sample()
        for group, machines in pairs(by_group) do
            for _, machine in pairs(machines) do
                if machine.valid then
                    local inventory = machine.get_output_inventory()
                    counts[group] = counts[group] + inventory.get_item_count()
                    inventory.clear()
                end
            end
        end
        left = left - 60
        if left > 0 then
            context:timeout(60, sample)
        else
            callback(counts)
        end
    end
    context:timeout(60, sample)
end

Declare.module(
    {'map_gen', 'crash site'},
    function()
        Declare.test(
            'spawn has its market with the airstrike, barrage and rocket tank upgrades',
            function()
                -- Act
                local surface = generate(32)

                -- Assert
                local market = spawn_market(surface)
                local group = Retailer.get_market_group_name(market)
                Assert.equal('Spawn', Retailer.get_market_group_label(group), 'spawn market label')

                local items = Retailer.get_items(group)
                for _, name in pairs {'airstrike_planner', 'airstrike_damage', 'airstrike_radius', 'barrage_planner', 'barrage_damage', 'barrage_radius', 'rocket_tanks_fire_rate'} do
                    Assert.is_true(items[name] ~= nil, 'spawn market is missing ' .. name)
                end
            end
        )

        Declare.test(
            'the payment chests are where /strike and /barrage look for them',
            function()
                -- Act
                local surface = generate(32)

                -- Assert
                for name, position in pairs {airstrike = AIRSTRIKE_CHEST, barrage = BARRAGE_CHEST} do
                    local chest = surface.find_entities_filtered {position = position, type = 'logistic-container', limit = 1}[1]
                    Assert.is_true(chest ~= nil, 'no ' .. name .. ' payment chest at ' .. position.x .. ',' .. position.y)
                    Assert.is_true(not chest.minable, 'the ' .. name .. ' payment chest can be mined')
                    Assert.is_true(not chest.destructible, 'the ' .. name .. ' payment chest can be destroyed')
                end
            end
        )

        Declare.test(
            'the /spy, /strike and /barrage commands are registered',
            function()
                -- Assert: the scenario registered them as it loaded
                for _, name in pairs {'spy', 'strike', 'barrage'} do
                    Assert.is_true(commands.commands[name] ~= nil, '/' .. name .. ' is not registered')
                end
            end
        )

        Declare.test(
            'the cutscene surface exists and is hidden from players',
            function()
                -- Assert: the scenario made them as it started
                Assert.is_true(game.get_surface('cutscene') ~= nil, 'no cutscene surface')
                Assert.is_true(game.forces.player.get_surface_hidden('cutscene'), 'the cutscene surface is visible to the player force')
                Assert.is_true(game.forces['cutscene'] ~= nil, 'no cutscene force')
            end
        )

        Declare.test(
            'outposts near spawn are defended and locked until captured',
            function()
                -- Act
                local surface = generate(OUTPOST_REACH)

                -- Assert
                local area = {{-OUTPOST_REACH, -OUTPOST_REACH}, {OUTPOST_REACH, OUTPOST_REACH}}
                local spawn = spawn_market(surface)
                local outposts = 0
                for _, market in pairs(surface.find_entities_filtered {area = area, name = 'market'}) do
                    if market ~= spawn then
                        local group = Retailer.get_market_group_name(market)
                        Assert.is_true(group ~= nil, 'outpost market at ' .. market.position.x .. ',' .. market.position.y .. ' is not registered')
                        local upgrade = Retailer.get_items(group)['upgrade']
                        Assert.is_true(upgrade ~= nil and upgrade.disabled, 'outpost ' .. tostring(Retailer.get_market_group_label(group)) .. ' can be upgraded before it is captured')
                        outposts = outposts + 1
                    end
                end
                -- the first ring alone has four outposts, though not every outpost has a market
                Assert.is_true(outposts >= 1, 'no outpost markets within ' .. OUTPOST_REACH .. ' of spawn')

                local turrets = surface.count_entities_filtered {area = area, force = 'enemy', type = {'ammo-turret', 'electric-turret', 'fluid-turret', 'artillery-turret'}}
                Assert.is_true(turrets > 0, 'no enemy turrets within ' .. OUTPOST_REACH .. ' of spawn')
            end
        )

        Declare.test(
            'killing every defender captures the outpost',
            function(context)
                -- Arrange: the outpost nearest to spawn. Outposts are at most 66 tiles across
                -- with the market inside, so everything defending it is within OUTPOST_RADIUS.
                local surface = generate(OUTPOST_REACH)
                local spawn = spawn_market(surface)
                local market, best
                for _, m in pairs(surface.find_entities_filtered {area = {{-OUTPOST_REACH, -OUTPOST_REACH}, {OUTPOST_REACH, OUTPOST_REACH}}, name = 'market'}) do
                    local p = m.position
                    local d = p.x * p.x + p.y * p.y
                    if m ~= spawn and (not best or d < best) then
                        market, best = m, d
                    end
                end
                Assert.is_true(market ~= nil, 'no outpost near spawn')
                local group = Retailer.get_market_group_name(market)
                local name = Retailer.get_market_group_label(group)
                Assert.is_true(Retailer.get_items(group)['upgrade'].disabled, name .. ' was already unlocked')

                local p = market.position
                local around = {{p.x - OUTPOST_RADIUS, p.y - OUTPOST_RADIUS}, {p.x + OUTPOST_RADIUS, p.y + OUTPOST_RADIUS}}
                Assert.is_true(surface.count_entities_filtered {area = around, name = 'stone-wall', force = 'enemy'} > 0, name .. ' has no enemy walls')

                -- Act: turrets and worms are what an outpost counts down to its capture
                local defenders = surface.find_entities_filtered {area = around, force = 'enemy', type = {'ammo-turret', 'electric-turret', 'fluid-turret', 'artillery-turret', 'turret'}}
                Assert.is_true(#defenders > 0, name .. ' has no defenders')
                for _, defender in pairs(defenders) do
                    if defender.valid then
                        defender.die()
                    end
                end

                -- Assert, once the destroyed events have come through at the end of the tick
                context:timeout(5, function()
                    local upgrade = Retailer.get_items(group)['upgrade']
                    Assert.is_true(not upgrade.disabled or upgrade.disabled_reason == 'No machines to upgrade.',
                        name .. ' is still locked after its ' .. #defenders .. ' defenders died: ' .. tostring(upgrade.disabled_reason))
                    -- a neighbouring outpost's walls can be in range too, so count what changed hands
                    Assert.is_true(surface.count_entities_filtered {area = around, name = 'stone-wall', force = 'player'} > 0,
                        'none of the walls around ' .. name .. ' became the player\'s when it was captured')
                end)
            end
        )
        Declare.test(
            'outpost machines make their product over time',
            function(context)
                -- Arrange
                local surface = generate(OUTPOST_REACH)
                local all = {}
                for _, machines in pairs(outpost_machines(surface)) do
                    for _, machine in pairs(machines) do
                        all[#all + 1] = machine
                    end
                end
                Assert.is_true(#all > 0, 'no outpost machines within ' .. OUTPOST_REACH .. ' of spawn')

                -- Act: let them run for 10 seconds
                measure(context, {all = all}, 600, function(counts)
                    -- Assert
                    Assert.is_true(counts.all > 0, 'the ' .. #all .. ' outpost machines near spawn made nothing in 10 seconds')
                end)
            end
        )

        Declare.test(
            'buying an outpost upgrade raises its price and speeds up its machines',
            function(context)
                -- Arrange: the outpost near spawn that makes the most, so the speed-up shows
                local surface = generate(OUTPOST_REACH)
                local by_group = outpost_machines(surface)

                local function test_upgrade(WINDOW, counts)
                    local group, before
                    for g, count in pairs(counts) do
                        if not before or count > before then
                            group, before = g, count
                        end
                    end
                    Assert.is_true(group ~= nil, 'no outpost machines within ' .. OUTPOST_REACH .. ' of spawn')
                    local name = Retailer.get_market_group_label(group)
                    Assert.is_true(before >= 20, 'the busiest outpost near spawn, ' .. name .. ', made only ' .. before .. ' items in ' .. WINDOW .. ' ticks')

                    -- capturing an outpost puts its upgrade on sale
                    OutpostBuilder.activate_market_upgrade(group)
                    local item = Retailer.get_items(group)['upgrade']
                    Assert.is_true(not item.disabled, name .. '\'s upgrade is not on sale: ' .. tostring(item.disabled_reason))
                    local price, label = item.price, item.name_label
                    local level = tonumber(label:match('(%d+)$'))
                    Assert.is_true(level ~= nil, 'no level in the upgrade label ' .. label)

                    -- Act
                    buy(group, item)

                    -- Assert
                    item = Retailer.get_items(group)['upgrade']
                    Assert.equal('Upgrade Outpost to level ' .. (level + 1), item.name_label, name .. '\'s upgrade label after buying one')
                    Assert.is_true(item.price > price, name .. '\'s upgrade price went from ' .. price .. ' to ' .. item.price)

                    measure(context, {[group] = by_group[group]}, WINDOW, function(after)
                        -- an upgrade adds half the base rate; allow for when in each second
                        -- a machine was last topped up
                        Assert.is_true(after[group] >= before * 1.25, name .. ' made ' .. before .. ' items before its upgrade and ' .. after[group] .. ' after')
                    end)
                end

                -- 20 seconds shows the speed-up for most outposts; slow ones (16 items in that
                -- time on one World seed) are measured for a minute instead
                measure(context, by_group, 1200, function(counts)
                    local busiest = 0
                    for _, count in pairs(counts) do
                        busiest = math.max(busiest, count)
                    end
                    if busiest >= 20 then
                        return test_upgrade(1200, counts)
                    end
                    measure(context, by_group, 3600, function(longer)
                        test_upgrade(3600, longer)
                    end)
                end)
            end
        )

        Declare.test(
            'buying a spawn market upgrade raises its level and price',
            function()
                local surface = generate(32)
                local group = Retailer.get_market_group_name(spawn_market(surface))
                local items = Retailer.get_items(group)
                for _, key in pairs({'airstrike_damage', 'airstrike_radius', 'barrage_damage', 'barrage_radius'}) do
                    -- Arrange
                    local item = items[key]
                    Assert.is_true(item ~= nil, 'no ' .. key .. ' at the spawn market')
                    local level, price = item.name_label[2], item.price

                    -- Act
                    buy(group, item)

                    -- Assert
                    item = Retailer.get_items(group)[key]
                    Assert.equal(level + 1, item.name_label[2], key .. ' level after buying it')
                    Assert.is_true(item.price > price, key .. ' price went from ' .. price .. ' to ' .. item.price)
                end
            end
        )
        -- Calls a Crash Site command (strike or barrage) at `target`, the way the command does.
        local function call(context, command, target)
            local surface = RS.get_surface()
            -- the commands only print to say why they did nothing; the print is on the metatable
            -- because the caller is kept for later in Task's save data, which can't hold functions
            local caller = setmetatable({name = 'test runner', valid = true, surface = surface, force = game.forces.player}, {__index = {
                print = function(message)
                    error('the command said ' .. serpent.line(message), 2)
                end
            }})
            Helper.modify_global(context, 'rendering', setmetatable({}, {__index = function()
                return function() end
            end}))
            command({location = '[gps=' .. target.x .. ',' .. target.y .. ',' .. surface.name .. ']'}, caller)
        end

        -- An enemy nest on open ground some way from spawn, for a strike to aim at.
        local function target_nest(context)
            local surface = generate(160)
            local p = surface.find_non_colliding_position('biter-spawner', {x = 96, y = 96}, 64, 1)
            Assert.is_true(p ~= nil, 'no room for a nest near spawn')
            local nest = surface.create_entity {name = 'biter-spawner', position = p, force = 'enemy'}
            Assert.valid(nest, 'the target nest was not created')
            context:add_teardown(function()
                if nest.valid then
                    nest.destroy()
                end
            end)
            return surface, nest
        end

        -- Polls every 10 ticks, up to `ticks`, until `done` returns true, then calls `after`.
        local function poll(context, ticks, done, after)
            local function check()
                if done() then
                    after(true)
                    return
                end
                ticks = ticks - 10
                if ticks <= 0 then
                    after(false)
                    return
                end
                context:timeout(10, check)
            end
            context:timeout(10, check)
        end

        local function payment_chest(surface, position, item, count)
            local chest = surface.find_entities_filtered {position = position, type = 'logistic-container', limit = 1}[1]
            Assert.valid(chest, 'no payment chest at ' .. position.x .. ',' .. position.y)
            local inventory = chest.get_inventory(defines.inventory.chest)
            inventory.clear()
            inventory.insert {name = item, count = count}
            return inventory
        end

        Declare.test(
            'an airstrike takes its poison capsules and gasses the target',
            function(context)
                -- Arrange: an airstrike damage upgrade, capsules to pay with, and a nest
                local surface, nest = target_nest(context)
                local group = Retailer.get_market_group_name(spawn_market(surface))
                buy(group, Retailer.get_items(group)['airstrike_damage'])
                local inventory = payment_chest(surface, AIRSTRIKE_CHEST, 'poison-capsule', 200)
                local target = nest.position

                -- Act
                call(context, CSCommands.call_strike, target)

                -- Assert
                Assert.is_true(inventory.get_item_count('poison-capsule') < 200, 'the airstrike took no poison capsules')
                local function gassed()
                    return surface.count_entities_filtered {position = target, radius = 40, name = 'poison-cloud'} > 0
                end
                poll(context, 600, gassed, function(ok)
                    Assert.is_true(ok, 'no poison cloud near the target ' .. target.x .. ',' .. target.y .. ' 10 seconds after the airstrike')
                end)
            end
        )

        Declare.test(
            'a barrage takes its rockets and shells the nearest nest',
            function(context)
                -- Arrange: a barrage damage upgrade, rockets to pay with, and a nest
                local surface, nest = target_nest(context)
                local group = Retailer.get_market_group_name(spawn_market(surface))
                buy(group, Retailer.get_items(group)['barrage_damage'])
                local inventory = payment_chest(surface, BARRAGE_CHEST, 'explosive-rocket', 400)
                local target = nest.position

                -- Act
                call(context, CSCommands.call_barrage, target)

                -- Assert
                Assert.is_true(inventory.get_item_count('explosive-rocket') < 400, 'the barrage took no rockets')
                local function hit()
                    return not nest.valid or nest.health < nest.max_health
                end
                poll(context, 900, hit, function(ok)
                    Assert.is_true(ok, 'the nest at ' .. target.x .. ',' .. target.y .. ' was not hit 15 seconds after the barrage')
                end)
            end
        )
        Declare.test(
            'after the rocket tank upgrade, a driven tank with rockets fires at a nest',
            function(context)
                -- Arrange: the upgrade, then a tank with a driver and rockets next to a nest. A
                -- character can drive without a player.
                local surface, nest = target_nest(context)
                local group = Retailer.get_market_group_name(spawn_market(surface))
                buy(group, Retailer.get_items(group)['rocket_tanks_fire_rate'])
                local p = surface.find_non_colliding_position('tank', {nest.position.x - 12, nest.position.y}, 16, 1)
                Assert.is_true(p ~= nil, 'no room for a tank by the nest')
                local tank = surface.create_entity {name = 'tank', position = p, force = 'player'}
                local driver = surface.create_entity {name = 'character', position = p, force = 'player'}
                context:add_teardown(function()
                    for _, e in pairs({driver, tank}) do
                        if e.valid then
                            e.destroy()
                        end
                    end
                end)
                tank.set_driver(driver)
                Assert.is_true(tank.get_driver() ~= nil, 'the character did not get in the tank')
                local trunk = tank.get_inventory(defines.inventory.car_trunk)
                trunk.insert {name = 'rocket', count = 10}

                -- Act: the tank is built, the way a player builds one
                EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = tank}

                -- Assert: it fires every 2 seconds at this level
                poll(context, 300, function()
                    return trunk.get_item_count('rocket') < 10
                end, function(ok)
                    Assert.is_true(ok, 'the tank fired no rockets at the nest ' .. math.floor(nest.position.x - p.x) .. ' tiles away in 5 seconds')
                end)
            end
        )
        local function outpost_area()
            return {{-OUTPOST_REACH, -OUTPOST_REACH}, {OUTPOST_REACH, OUTPOST_REACH}}
        end

        Declare.test(
            'an outpost gun turret that runs dry gets its ammo back',
            function(context)
                -- Arrange
                local surface = generate(OUTPOST_REACH)
                local turret = surface.find_entities_filtered {area = outpost_area(), force = 'enemy', type = 'ammo-turret', limit = 1}[1]
                Assert.valid(turret, 'no enemy gun turrets within ' .. OUTPOST_REACH .. ' of spawn')
                local ammo = turret.get_inventory(defines.inventory.turret_ammo)
                Assert.is_true(not ammo.is_empty(), 'the turret at ' .. turret.position.x .. ',' .. turret.position.y .. ' started with no ammo')
                -- Act
                ammo.clear()

                -- Assert: turrets are refilled one a tick, in turn
                poll(context, 6000, function()
                    return not turret.valid or not ammo.is_empty()
                end, function(ok)
                    Assert.is_true(ok, 'the turret at ' .. turret.position.x .. ',' .. turret.position.y .. ' got no ammo back in 100 seconds')
                end)
            end
        )

        -- whether an enemy pole's supply area reaches the turret
        local function covered_by_pole(surface, turret)
            local box = turret.bounding_box
            for _, pole in pairs(surface.find_entities_filtered {position = turret.position, radius = 16, type = 'electric-pole', force = 'enemy'}) do
                local d = pole.prototype.get_supply_area_distance(pole.quality)
                local q = pole.position
                if box.left_top.x < q.x + d and box.right_bottom.x > q.x - d and box.left_top.y < q.y + d and box.right_bottom.y > q.y - d then
                    return true
                end
            end
            return false
        end

        Declare.test(
            'outpost laser turrets a pole reaches have power',
            function(context)
                -- Act: not every map has laser turrets a pole reaches in its first ring of outposts
                local reach, surface, turrets
                for _, r in pairs({OUTPOST_REACH, OUTPOST_REACH * 2, OUTPOST_REACH * 3}) do
                    reach, surface = r, generate(r)
                    turrets = surface.find_entities_filtered {area = {{-r, -r}, {r, r}}, force = 'enemy', type = 'electric-turret'}
                    local reached = false
                    for _, turret in pairs(turrets) do
                        reached = reached or covered_by_pole(surface, turret)
                    end
                    if reached then
                        break
                    end
                end
                Assert.is_true(#turrets > 0, 'no enemy laser turrets within ' .. reach .. ' of spawn')

                -- Assert: give any just built a moment to charge. A turret's pole is left out where
                -- something was in its way when the outpost was built, or isn't there yet where it
                -- is in a chunk not generated yet, which leaves the turret without power: only
                -- turrets inside a pole's supply area are counted (a pole nearby may be another
                -- group's, out of reach).
                context:timeout(300, function()
                    local unpowered, poled = {}, 0
                    for _, turret in pairs(turrets) do
                        local p = turret.valid and turret.position
                        if p and covered_by_pole(surface, turret) then
                            poled = poled + 1
                            if turret.energy <= 0 then
                                unpowered[#unpowered + 1] = p.x .. ',' .. p.y .. ' (network ' .. tostring(turret.electric_network_id) .. ')'
                            end
                        end
                    end
                    Assert.is_true(poled > 0, 'no pole reaches any of the ' .. #turrets .. ' laser turrets')
                    Assert.equal(0, #unpowered, 'of ' .. poled .. ' laser turrets a pole reaches, these have no power: ' .. table.concat(unpowered, ' '))
                end)
            end
        )

        Declare.test(
            'outpost poles that power laser turrets come back a minute after they are destroyed',
            function(context)
                -- the laser turrets within reach of each enemy pole: what the respawn looks for
                local function turrets_reached(surface, pole, d)
                    local q = pole.position
                    return surface.find_entities_filtered {area = {{q.x - d, q.y - d}, {q.x + d, q.y + d}}, name = 'laser-turret', force = 'enemy'}
                end

                -- poles whose turrets are only in the outer half of their supply area first: a
                -- respawn that looked at half the supply area missed those
                local surface, outer, inner
                for _, r in pairs({OUTPOST_REACH, OUTPOST_REACH * 2, OUTPOST_REACH * 3}) do
                    surface = generate(r)
                    outer, inner = {}, {}
                    for _, pole in pairs(surface.find_entities_filtered {area = {{-r, -r}, {r, r}}, type = 'electric-pole', force = 'enemy'}) do
                        local d = pole.prototype.get_supply_area_distance(pole.quality)
                        if #turrets_reached(surface, pole, d) > 0 then
                            local list = #turrets_reached(surface, pole, d / 2) == 0 and outer or inner
                            list[#list + 1] = pole
                        end
                    end
                    if #outer + #inner > 0 then
                        break
                    end
                end
                local poles = {}
                for _, list in pairs({outer, inner}) do
                    for _, pole in pairs(list) do
                        if #poles < 4 then
                            poles[#poles + 1] = pole
                        end
                    end
                end
                Assert.is_true(#poles > 0, 'no enemy pole reaches a laser turret')

                -- Act
                local killed = {}
                for _, pole in pairs(poles) do
                    local d = pole.prototype.get_supply_area_distance(pole.quality)
                    killed[#killed + 1] = {name = pole.name, position = pole.position, turrets = turrets_reached(surface, pole, d)}
                    pole.die()
                end

                -- Assert: back after a minute, and their turrets on a network again
                context:timeout(60 * 60 + 60, function()
                    local missing, unpowered = {}, {}
                    for _, k in pairs(killed) do
                        local p = k.position
                        if surface.count_entities_filtered {position = p, radius = 0.5, name = k.name, force = 'enemy'} == 0 then
                            missing[#missing + 1] = k.name .. ' at ' .. p.x .. ',' .. p.y
                        end
                        for _, turret in pairs(k.turrets) do
                            if turret.valid and not turret.electric_network_id then
                                unpowered[#unpowered + 1] = turret.position.x .. ',' .. turret.position.y
                            end
                        end
                    end
                    Assert.equal(0, #missing, 'of ' .. #killed .. ' poles destroyed (' .. #outer .. ' reaching their turrets only in the outer half), these did not come back: ' .. table.concat(missing, ' '))
                    Assert.equal(0, #unpowered, 'laser turrets with no network after their pole came back: ' .. table.concat(unpowered, ' '))
                end)
            end
        )

        Declare.test(
            'outpost markets have goods for sale',
            function()
                -- Act
                local surface = generate(OUTPOST_REACH)

                -- Assert
                local spawn = spawn_market(surface)
                local checked = 0
                for _, market in pairs(surface.find_entities_filtered {area = outpost_area(), name = 'market'}) do
                    local group = market ~= spawn and Retailer.get_market_group_name(market)
                    if group then
                        checked = checked + 1
                        local goods = 0
                        for name, item in pairs(Retailer.get_items(group)) do
                            if name ~= 'upgrade' and item.price and item.price > 0 then
                                goods = goods + 1
                            end
                        end
                        Assert.is_true(goods > 0, Retailer.get_market_group_label(group) .. ' has nothing for sale')
                    end
                end
                Assert.is_true(checked > 0, 'no outpost markets within ' .. OUTPOST_REACH .. ' of spawn')
            end
        )

        Declare.test(
            'outposts have loot in their chests',
            function()
                -- Act
                local surface = generate(OUTPOST_REACH)

                -- Assert
                local chests, full = 0, 0
                for _, chest in pairs(surface.find_entities_filtered {area = outpost_area(), type = 'container'}) do
                    local p = chest.position
                    if math.abs(p.x) > 16 or math.abs(p.y) > 16 then
                        chests = chests + 1
                        if not chest.get_inventory(defines.inventory.chest).is_empty() then
                            full = full + 1
                        end
                    end
                end
                Assert.is_true(chests > 0, 'no chests in the outposts within ' .. OUTPOST_REACH .. ' of spawn')
                Assert.is_true(full > 0, 'all ' .. chests .. ' outpost chests within ' .. OUTPOST_REACH .. ' of spawn are empty')
            end
        )
    end
)
