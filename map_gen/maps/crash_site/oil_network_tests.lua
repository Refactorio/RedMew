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
                local turret = network.turrets[1]

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
