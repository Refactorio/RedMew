-- In-game bootstrap tests for Diggy. These run under _DEBUG via /test-runner, and are only
-- discovered when scenario.lua is loaded, i.e. when a Diggy map is active. They check that the
-- map starts the way the rest of it relies on: a dug-out starting zone with a ring of rocks
-- around it, and the market.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local EventFactory = require 'utils.test.event_factory'
local Helper = require 'utils.test.helper'
local Event = require 'utils.event'
local DiggyCaveCollapse = require 'map_gen.maps.diggy.feature.diggy_cave_collapse'
local RS = require 'map_gen.shared.redmew_surface'

-- collapses seen, by when they were triggered and where the rock came down
local collapses = {triggered = 0, done = 0, at = {}}
Event.add(DiggyCaveCollapse.events.on_collapse_triggered, function()
    collapses.triggered = collapses.triggered + 1
end)
Event.add(DiggyCaveCollapse.events.on_collapse, function(event)
    collapses.done = collapses.done + 1
    collapses.at[#collapses.at + 1] = event.position
end)

-- the collapses since the `since`th that came down in `area`, as "x,y" strings
local function collapses_in(area, since)
    local found = {}
    for i = since + 1, #collapses.at do
        local p = collapses.at[i]
        if p.x >= area[1][1] and p.x < area[2][1] and p.y >= area[1][2] and p.y < area[2][2] then
            found[#found + 1] = p.x .. ',' .. p.y
        end
    end
    return found
end

local ROCKS = {'big-rock', 'huge-rock'}

-- how many times robots have mined something (a rock's entity is replaced by the time this
-- sees it, so it can't tell what)
local robot_mined = 0
Event.add(defines.events.on_robot_mined_entity, function()
    robot_mined = robot_mined + 1
end)

-- Real construction robots, on a pad of dirt east of the starting zone (out-of-map takes no
-- buildings). They reach the starting zone and its ring of rocks from there.
local PAD = {{22, -8}, {38, 8}}
local ROBOT_TICKS = 1800

local function robot_network(context, surface, items)
    local tiles = {}
    for x = PAD[1][1], PAD[2][1] - 1 do
        for y = PAD[1][2], PAD[2][2] - 1 do
            if surface.get_tile(x, y).name == 'out-of-map' then
                tiles[#tiles + 1] = {name = 'dirt-1', position = {x, y}}
            end
        end
    end
    surface.set_tiles(tiles)
    local storage, remove_network = Helper.robot_network(surface, {x = 30, y = 0}, items)
    context:add_teardown(remove_network)
    return storage
end

local function surface_around_spawn()
    local surface = RS.get_surface()
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()
    return surface
end

Declare.module(
    {'map_gen', 'diggy'},
    function()
        Declare.test(
            'the starting zone is dug out and ringed by rocks',
            function()
                local surface = surface_around_spawn()
                Assert.equal('stone-path', surface.get_tile(0, 0).name, 'tile at spawn')
                -- nothing in the middle of the zone, rocks all round its edge
                Assert.equal(0, surface.count_entities_filtered {position = {0, 0}, radius = 3, name = 'big-rock'}, 'rocks in the middle of the starting zone')
                local rocks = surface.count_entities_filtered {position = {0, 0}, radius = 12, name = 'big-rock'}
                Assert.is_true(rocks >= 8, 'only ' .. rocks .. ' rocks around the starting zone')
            end
        )

        Declare.test(
            'mining brick laid over landfill leaves the landfill (issue #1490)',
            function()
                -- Arrange: landfill with stone path on top, in the starting zone
                local surface = surface_around_spawn()
                local position = {x = 3, y = -3}
                surface.set_tiles {{name = 'landfill', position = position}}
                surface.set_tiles {{name = 'stone-path', position = position}}
                surface.set_hidden_tile(position, 'landfill')
                Assert.equal('stone-path', surface.get_tile(position.x, position.y).name, 'the test tile was not laid')

                -- Act: mining a tile puts back its hidden tile, then raises the event, which
                -- carries the prototype of the tile that was mined
                surface.set_tiles {{name = 'landfill', position = position}}
                EventFactory.raise {
                    name = defines.events.on_player_mined_tile,
                    tick = game.tick,
                    player_index = 1,
                    surface_index = surface.index,
                    tiles = {{position = position, old_tile = prototypes.tile['stone-path']}}
                }

                -- Assert
                Assert.equal('landfill', surface.get_tile(position.x, position.y).name, 'tile left after mining the stone path')
            end
        )

        Declare.test(
            'mining a floor tile that would leave void fills it with dirt',
            function()
                -- Arrange: stone path with nothing under it but the cave's void
                local surface = surface_around_spawn()
                local position = {x = -3, y = 3}
                surface.set_tiles {{name = 'stone-path', position = position}}

                -- Act: as above, with the void coming back
                surface.set_tiles {{name = 'out-of-map', position = position}}
                EventFactory.raise {
                    name = defines.events.on_player_mined_tile,
                    tick = game.tick,
                    player_index = 1,
                    surface_index = surface.index,
                    tiles = {{position = position, old_tile = prototypes.tile['stone-path']}}
                }

                -- Assert
                local name = surface.get_tile(position.x, position.y).name
                Assert.is_true(name:sub(1, 5) == 'dirt-', 'tile left after mining the stone path: ' .. name)
            end
        )

        Declare.test(
            'the market is in the starting zone',
            function()
                local surface = surface_around_spawn()
                local markets = surface.count_entities_filtered {position = {0, 0}, radius = 12, name = 'market'}
                Assert.equal(1, markets, 'markets in the starting zone')
            end
        )
        Declare.test(
            'destroying a rock beside the void digs into it, with rock behind',
            function()
                -- Arrange: a rock of the ring west of the starting zone, with void beside it; the
                -- cave-in rooms are north and south, where its void would add to their stress
                local surface = surface_around_spawn()
                local rock, void
                for _, r in pairs(surface.find_entities_filtered {area = {{-16, -3}, {-5, 3}}, name = ROCKS}) do
                    local p = r.position
                    for _, d in pairs({{0, -1}, {1, 0}, {0, 1}, {-1, 0}}) do
                        if surface.get_tile(p.x + d[1], p.y + d[2]).name == 'out-of-map' then
                            rock, void = r, {x = p.x + d[1], y = p.y + d[2]}
                            break
                        end
                    end
                    if rock then
                        break
                    end
                end
                Assert.is_true(rock ~= nil, 'no rock beside the void round the starting zone')

                -- Act
                rock.die()

                -- Assert: the void beside it is now ground, with a new rock on it
                local name = surface.get_tile(void.x, void.y).name
                Assert.is_true(name:sub(1, 5) == 'dirt-', 'tile dug into at ' .. void.x .. ',' .. void.y .. ': ' .. name)
                Assert.equal(1, surface.count_entities_filtered {position = void, radius = 0.5, name = ROCKS}, 'rocks on the tile dug into')
            end
        )

        Declare.test(
            'digging out a big room with nothing holding it up caves it in',
            function(context)
                -- Arrange: a room's worth of rock north of the starting zone, from its ring of rocks out
                local surface = surface_around_spawn()
                local room = {{-12, -36}, {12, -6}}
                local before = {triggered = collapses.triggered, at = #collapses.at}

                -- Act: dig it out the way a player would, a rock at a time, until it caves in
                local steps = 120
                local function dig()
                    if #collapses_in(room, before.at) > 0 then
                        -- Assert: rock came back down into the room
                        Assert.is_true(surface.count_entities_filtered {area = room, name = ROCKS} > 0, 'the room caved in but no rock came down in it')
                        return
                    end
                    for _, r in pairs(surface.find_entities_filtered {area = room, name = ROCKS}) do
                        if r.valid then
                            r.die()
                        end
                    end
                    steps = steps - 1
                    local open = surface.count_tiles_filtered {area = room, name = 'out-of-map', invert = true}
                    Assert.is_true(steps > 0, 'a room with ' .. open .. ' tiles dug out did not cave in (' .. (collapses.triggered - before.triggered) .. ' collapses triggered)')
                    context:timeout(10, dig)
                end
                dig()
            end
        )
        Declare.test(
            'the same room held up by stone wall pillars stands',
            function(context)
                -- Arrange: a room's worth of rock south of the starting zone, from its ring of rocks out
                local surface = surface_around_spawn()
                local room = {{-12, 6}, {12, 36}}
                local before = #collapses.at
                -- digging can turn up one of Diggy's random rooms next to this one, which takes
                -- support from its edge: the pillars have to hold up the rest
                local middle = {{room[1][1] + 3, room[1][2] + 3}, {room[2][1] - 3, room[2][2] - 3}}

                -- Act: dig it out, putting up a wall on every 3rd tile, edges included, as it opens
                -- up (every 4th is right at the limit)
                local function prop_up()
                    for x = room[1][1], room[2][1], 3 do
                        for y = room[1][2], room[2][2], 3 do
                            local p = {x + 0.5, y + 0.5}
                            if surface.get_tile(x, y).name ~= 'out-of-map' and surface.can_place_entity {name = 'stone-wall', position = p, force = 'player'} then
                                local wall = surface.create_entity {name = 'stone-wall', position = p, force = 'player'}
                                EventFactory.raise {name = defines.events.on_built_entity, tick = game.tick, player_index = 1, entity = wall}
                            end
                        end
                    end
                end
                local steps = 120
                local function dig()
                    prop_up()
                    local rocks = surface.find_entities_filtered {area = room, name = ROCKS}
                    if #rocks == 0 then
                        -- Assert, once anything triggered has had time to come down
                        context:timeout(200, function()
                            Assert.equal(0, #collapses_in(middle, before), 'collapses in a room held up by pillars: ' .. table.concat(collapses_in(middle, before), ' '))
                        end)
                        return
                    end
                    for _, r in pairs(rocks) do
                        if r.valid then
                            r.die()
                        end
                    end
                    steps = steps - 1
                    Assert.is_true(steps > 0, 'the room was not dug out')
                    Assert.equal(0, #collapses_in(middle, before), 'collapses in a room held up by pillars: ' .. table.concat(collapses_in(middle, before), ' '))
                    context:timeout(10, dig)
                end
                dig()
            end
        )

        Declare.test(
            'robots mining a floor laid on landfill leave the landfill',
            function(context)
                local surface = surface_around_spawn()
                robot_network(context, surface, {{name = 'stone-brick', count = 10}})
                local p = {x = 30, y = 6}
                surface.set_tiles {{name = 'landfill', position = p}}
                Assert.valid(surface.create_entity {name = 'tile-ghost', inner_name = 'stone-path', position = p, force = 'player'}, 'the stone path ghost was not placed')

                Helper.wait_until(context, ROBOT_TICKS, function()
                    return surface.get_tile(p.x, p.y).name == 'stone-path'
                end, function(laid)
                    Assert.is_true(laid, 'the robots did not lay the stone path on the landfill')
                    Assert.is_true(surface.get_tile(p.x, p.y).order_deconstruction('player') ~= nil, 'the stone path could not be marked for deconstruction')
                    Helper.wait_until(context, ROBOT_TICKS, function()
                        return surface.get_tile(p.x, p.y).name ~= 'stone-path'
                    end, function(mined)
                        Assert.is_true(mined, 'the robots did not mine the stone path')
                        Assert.equal('landfill', surface.get_tile(p.x, p.y).name, 'tile left after robots mined the stone path')
                    end)
                end)
            end
        )

        Declare.test(
            'robots wear a rock beside the void down over several trips and dig into the void',
            function(context)
                -- Arrange: a rock of the ring east of the starting zone, with void beside it, a few
                -- trips from breaking (each trip takes off robot_mining_delay * robot_per_tick_damage)
                local surface = surface_around_spawn()
                robot_network(context, surface)
                local rock, void
                for _, r in pairs(surface.find_entities_filtered {area = {{5, -3}, {16, 3}}, name = ROCKS}) do
                    local q = r.position
                    for _, d in pairs({{0, -1}, {1, 0}, {0, 1}}) do
                        if surface.get_tile(q.x + d[1], q.y + d[2]).name == 'out-of-map' then
                            rock, void = r, {x = q.x + d[1], y = q.y + d[2]}
                            break
                        end
                    end
                    if rock then
                        break
                    end
                end
                Assert.is_true(rock ~= nil, 'no rock beside the void east of the starting zone')
                local at = rock.position
                local key = at.x .. ',' .. at.y
                rock.health = 50
                local before = robot_mined
                local function trips()
                    return robot_mined - before
                end

                -- Act
                rock.order_deconstruction('player')

                -- Assert: it took more than one trip, then the void beside it was dug into
                Helper.wait_until(context, ROBOT_TICKS * 2, function()
                    return surface.count_entities_filtered {position = at, radius = 0.5, name = ROCKS} == 0 and surface.get_tile(void.x, void.y).name ~= 'out-of-map'
                end, function(dug)
                    Assert.is_true(dug, 'the robots did not break the rock at ' .. key .. ' and dig in: ' .. trips() .. ' trips, tile beside it ' .. surface.get_tile(void.x, void.y).name)
                    Assert.equal(3, trips(), 'robot trips to break a rock with 50 health')
                    local name = surface.get_tile(void.x, void.y).name
                    Assert.is_true(name:sub(1, 5) == 'dirt-', 'tile dug into at ' .. void.x .. ',' .. void.y .. ': ' .. name)
                end)
            end
        )
    end
)
