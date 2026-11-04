-- In-game tests for the oil tank and pipes that feed each Crash Site outpost's flamethrower
-- turrets. These are only discovered when oil_network.lua is loaded, i.e. when a Crash Site map
-- is active. They check that every flamethrower turret a pipe can reach is fed by its outpost's
-- tank, that the pipes that go under ground come up again, that the tank is topped up and the
-- turrets it feeds aren't, and that a destroyed tank or pipe comes back a minute later while a
-- turret it feeds still stands, and not after.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local OilNetwork = require 'map_gen.maps.crash_site.oil_network'
local RS = require 'map_gen.shared.redmew_surface'

-- the first ring of outposts is within 288 tiles of spawn
local REACHES = {288, 576}
-- a pipe or tank comes back after a minute, checked every 30 ticks
local RESPAWN_TICKS = 60 * 60 + 60
-- long enough for the refill round robin to have reached every turret
local REFILL_TICKS = 3000

local PIPES = {OilNetwork.pipe_name, OilNetwork.pipe_to_ground_name}

local function generate(radius)
    local surface = RS.get_surface()
    surface.request_to_generate_chunks({0, 0}, math.ceil(radius / 32))
    surface.force_generate_chunk_requests()
    return surface
end

local function area_of(network)
    local left, top, size = network.left, network.top, network.size
    return {{left, top}, {left + size, top + size}}
end

-- the nearest outpost oil network whose flamethrower turrets all still stand
local function find_network()
    for _, r in pairs(REACHES) do
        local surface = generate(r)
        local tanks = surface.find_entities_filtered {area = {{-r, -r}, {r, r}}, name = OilNetwork.tank_name, force = 'enemy'}
        for _, tank in pairs(tanks) do
            local network = OilNetwork.get_network(tank)
            if network and network.tank == tank and #network.turrets > 0 and #OilNetwork.get_live_turrets(tank) == #network.turrets then
                return surface, network
            end
        end
    end
    error('no outpost with an oil tank within ' .. REACHES[#REACHES] .. ' tiles of spawn')
end

local function oil(entity)
    local fluid = entity.fluidbox[1]
    return fluid and fluid.amount or 0
end

-- empties the tank, pipes and turrets of a network
local function drain(surface, network)
    for _, entity in pairs(surface.find_entities_filtered {area = area_of(network), name = {OilNetwork.tank_name, OilNetwork.pipe_name, OilNetwork.pipe_to_ground_name, 'flamethrower-turret'}, force = 'enemy'}) do
        entity.fluidbox[1] = nil
    end
end

-- the pipes (or pipe-to-grounds) on the tank's connections
local function pipes_at_tank(surface, tank)
    local pipes = {}
    for _, connection in pairs(tank.fluidbox.get_pipe_connections(1)) do
        local pipe = surface.find_entities_filtered {position = connection.target_position, name = PIPES, force = 'enemy', limit = 1}[1]
        if pipe then
            pipes[#pipes + 1] = pipe
        end
    end
    return pipes
end

-- whether nothing could pipe oil to the turret: none of its connections meets a pipe or another
-- turret, and something stands on every tile they point at (a template can wall a turret in)
local function walled_in(surface, turret)
    for _, connection in pairs(turret.fluidbox.get_pipe_connections(1)) do
        if connection.target or surface.count_entities_filtered {position = connection.target_position} == 0 then
            return false
        end
    end
    return true
end

-- The flamethrower turrets of a network the tank doesn't feed although a way of free tiles leads
-- from one of their connections to a tile where a pipe would join the oil: next to one of its
-- pipes, or where the tank, one of its pipe-to-grounds or a fed turret connects. Its pipes are
-- those holding the tank's oil: an outpost can have pipes of its own, for crude oil, say. Tiles
-- another machine's connection points at don't count as free: a pipe there would mix its fluid in.
local function reachable_unfed(surface, network)
    local area = area_of(network)
    local segment = network.tank.fluidbox.get_fluid_segment_id(1)
    local function key(x, y)
        return x .. ',' .. y
    end

    local blocked, joins = {}, {}
    for _, entity in pairs(surface.find_entities_filtered {area = area}) do
        local name = entity.name
        local fluidbox = entity.fluidbox
        local ours = (name == OilNetwork.pipe_name or name == OilNetwork.pipe_to_ground_name or name == OilNetwork.tank_name) and fluidbox.get_fluid_segment_id(1) == segment
        if name == OilNetwork.pipe_name and ours then
            local p = entity.position
            for _, d in pairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
                joins[key(math.floor(p.x) + d[1], math.floor(p.y) + d[2])] = 'next to the pipe at ' .. p.x .. ',' .. p.y
            end
        elseif ours or (name == 'flamethrower-turret' and OilNetwork.is_fed(entity)) then
            for _, connection in pairs(fluidbox.get_pipe_connections(1)) do
                if connection.connection_type == 'normal' then
                    local p = entity.position
                    joins[key(math.floor(connection.target_position.x), math.floor(connection.target_position.y))] = 'at the ' .. name .. ' at ' .. p.x .. ',' .. p.y
                end
            end
        elseif name ~= 'flamethrower-turret' then
            for i = 1, #fluidbox do
                for _, connection in pairs(fluidbox.get_pipe_connections(i)) do
                    blocked[key(math.floor(connection.target_position.x), math.floor(connection.target_position.y))] = true
                end
            end
        end
    end

    local free = {}
    local function is_free(x, y)
        local k = key(x, y)
        if free[k] == nil then
            free[k] = not blocked[k] and x >= area[1][1] and y >= area[1][2] and x < area[2][1] and y < area[2][2] and surface.can_place_entity {name = OilNetwork.pipe_name, position = {x + 0.5, y + 0.5}, force = 'enemy'}
        end
        return free[k]
    end

    local reachable = {}
    for _, turret in pairs(network.turrets) do
        if not OilNetwork.is_fed(turret) then
            local queue, seen, found = {}, {}, nil
            for _, connection in pairs(turret.fluidbox.get_pipe_connections(1)) do
                local x, y = math.floor(connection.target_position.x), math.floor(connection.target_position.y)
                if is_free(x, y) then
                    queue[#queue + 1] = {x, y}
                    seen[key(x, y)] = true
                end
            end
            local head = 1
            while queue[head] and not found do
                local x, y = queue[head][1], queue[head][2]
                head = head + 1
                if joins[key(x, y)] then
                    found = x .. ',' .. y .. ' ' .. joins[key(x, y)]
                end
                for _, d in pairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
                    local nx, ny = x + d[1], y + d[2]
                    if not seen[key(nx, ny)] and is_free(nx, ny) then
                        seen[key(nx, ny)] = true
                        queue[#queue + 1] = {nx, ny}
                    end
                end
            end
            if found then
                reachable[#reachable + 1] = turret.position.x .. ',' .. turret.position.y .. ' (to ' .. found .. ')'
            end
        end
    end
    return reachable
end

local function at(surface, name, position)
    return surface.find_entity(name, position)
end

local function pipe_at(surface, position)
    return surface.find_entities_filtered {position = position, name = PIPES, force = 'enemy', limit = 1}[1]
end

Declare.module(
    {'map_gen', 'crash site', 'oil network'},
    function()
        Declare.test(
            'every flamethrower turret in an outpost with an oil tank shares its oil, unless walled in',
            function()
                -- Act
                local surface, network = find_network()

                -- Assert: a walled in turret is still filled directly
                local tank = network.tank
                local segment = tank.fluidbox.get_fluid_segment_id(1)
                local loose, walled = {}, {}
                for _, turret in pairs(surface.find_entities_filtered {area = area_of(network), name = 'flamethrower-turret', force = 'enemy'}) do
                    local at_turret = turret.position.x .. ',' .. turret.position.y
                    if walled_in(surface, turret) then
                        if OilNetwork.is_fed(turret) then
                            walled[#walled + 1] = at_turret
                        end
                    elseif turret.fluidbox.get_fluid_segment_id(1) ~= segment or not OilNetwork.is_fed(turret) then
                        loose[#loose + 1] = at_turret
                    end
                end
                Assert.equal(0, #loose, 'flamethrower turrets the tank at ' .. tank.position.x .. ',' .. tank.position.y .. ' does not feed: ' .. table.concat(loose, ' '))
                Assert.equal(0, #walled, 'walled in flamethrower turrets taken as fed by the tank: ' .. table.concat(walled, ' '))
                Assert.is_true(#pipes_at_tank(surface, tank) > 0, 'no pipe on the tank')
            end
        )

        Declare.test(
            'no flamethrower turret is left off its tank where a pipe could reach it',
            function()
                -- Act
                local r = REACHES[#REACHES]
                local surface = generate(r)

                -- Assert: in every finished outpost whose flamethrower turrets all stand, a turret
                -- the tank doesn't feed has no way of free tiles from its connections to the oil
                local missed, outposts = {}, 0
                for _, tank in pairs(surface.find_entities_filtered {area = {{-r, -r}, {r, r}}, name = OilNetwork.tank_name, force = 'enemy'}) do
                    local network = OilNetwork.get_network(tank)
                    if network and #OilNetwork.get_live_turrets(tank) == #network.turrets then
                        outposts = outposts + 1
                        for _, turret in pairs(reachable_unfed(surface, network)) do
                            missed[#missed + 1] = turret
                        end
                    end
                end
                Assert.is_true(outposts > 0, 'no finished outpost with an oil tank within ' .. r .. ' tiles of spawn')
                Assert.equal(0, #missed, 'flamethrower turrets free tiles lead from to the oil, left off the tank: ' .. table.concat(missed, ' '))
            end
        )

        Declare.test(
            'every pipe-to-ground in an oil network meets a pipe and its partner under ground',
            function()
                -- Act
                local r = REACHES[#REACHES]
                local surface = generate(r)

                -- Assert: a pipe-to-ground short of either is a gap in the line. Only outposts
                -- whose flamethrower turrets all stand: other tests destroy some, which leaves the
                -- pipes that fed them meeting nothing.
                local loose = {}
                for _, tank in pairs(surface.find_entities_filtered {area = {{-r, -r}, {r, r}}, name = OilNetwork.tank_name, force = 'enemy'}) do
                    local network = OilNetwork.get_network(tank)
                    if network and #OilNetwork.get_live_turrets(tank) == #network.turrets then
                        for _, pipe in pairs(surface.find_entities_filtered {area = area_of(network), name = OilNetwork.pipe_to_ground_name, force = 'enemy'}) do
                            local ends = {}
                            for _, connection in pairs(pipe.fluidbox.get_pipe_connections(1)) do
                                if connection.target then
                                    ends[connection.connection_type] = true
                                end
                            end
                            if not (ends.normal and ends.underground) then
                                loose[#loose + 1] = pipe.position.x .. ',' .. pipe.position.y
                            end
                        end
                    end
                end
                Assert.equal(0, #loose, 'pipe-to-grounds short of a connection: ' .. table.concat(loose, ' '))
            end
        )

        Declare.test(
            'an emptied oil tank is topped up again',
            function(context)
                -- Arrange
                local surface, network = find_network()
                local tank = network.tank

                -- Act
                drain(surface, network)

                -- Assert
                context:wait_until(120, function()
                    return oil(tank) > 0
                end, 'the tank at ' .. tank.position.x .. ',' .. tank.position.y .. ' was not topped up')
            end
        )

        Declare.test(
            'a destroyed oil tank leaves its turrets dry until it comes back a minute later',
            function(context)
                -- Arrange
                local surface, network = find_network()
                local position = network.tank.position
                local turret
                for _, t in pairs(network.turrets) do
                    if not turret and OilNetwork.is_fed(t) then
                        turret = t
                    end
                end

                -- Act
                network.tank.die()
                drain(surface, network)

                -- Assert: no oil reaches the turret without the tank, then the tank is back and
                -- feeds it again
                context:timeout(REFILL_TICKS, function()
                    Assert.equal(0, oil(turret), 'oil in the turret at ' .. turret.position.x .. ',' .. turret.position.y .. ' with its tank destroyed')
                end):wait_until(RESPAWN_TICKS - REFILL_TICKS + 60, function()
                    return at(surface, OilNetwork.tank_name, position) ~= nil
                end, 'the tank at ' .. position.x .. ',' .. position.y .. ' did not come back'):wait_until(120, function()
                    return oil(turret) > 0
                end, 'the tank that came back does not feed the turret')
            end
        )

        Declare.test(
            'a destroyed pipe on the oil tank comes back a minute later',
            function(context)
                -- Arrange: the pipe on the tank, which every turret on its branch draws through
                local surface, network = find_network()
                local pipe = pipes_at_tank(surface, network.tank)[1]
                local position = pipe.position

                -- Act
                pipe.die()

                -- Assert
                context:wait_until(RESPAWN_TICKS, function()
                    return pipe_at(surface, position) ~= nil
                end, 'the pipe at ' .. position.x .. ',' .. position.y .. ' did not come back')
            end
        )

        Declare.test(
            'a destroyed pipe stays gone once the turrets it fed are gone',
            function(context)
                -- Arrange: the pipe feeding the fewest turrets, and those turrets destroyed
                local surface, network = find_network()
                local pipe, turrets
                for _, p in pairs(surface.find_entities_filtered {area = area_of(network), name = PIPES, force = 'enemy'}) do
                    local fed = OilNetwork.get_live_turrets(p)
                    if #fed > 0 and (not turrets or #fed < #turrets) then
                        pipe, turrets = p, fed
                    end
                end
                Assert.valid(pipe, 'no pipe feeds a turret')
                Assert.is_true(#turrets < #network.turrets, 'the pipe at ' .. pipe.position.x .. ',' .. pipe.position.y .. ' feeds every turret')
                for _, turret in pairs(turrets) do
                    turret.destroy()
                end
                local position = pipe.position

                -- Act
                pipe.die()

                -- Assert
                context:timeout(RESPAWN_TICKS, function()
                    Assert.is_true(pipe_at(surface, position) == nil, 'the pipe at ' .. position.x .. ',' .. position.y .. ' came back with no turret to feed')
                end)
            end
        )
    end
)
