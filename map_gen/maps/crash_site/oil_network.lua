-- Each Crash Site outpost with flamethrower turrets gets one light oil tank that feeds them all.
-- Once every chunk the outpost covers has been generated, a storage tank is placed near its
-- middle and pipes are laid from the tank to each flamethrower turret along the shortest free
-- path, joining the pipes laid before them, so the turrets read as fed by one pipe network.
--
-- The script tops up the tank rather than the turrets: a turret the tank feeds gets no oil of its
-- own, so cutting a pipe or destroying the tank starves the turrets behind it until events.lua
-- brings the pipe or tank back, the way it does the power poles. A turret the pipes can't reach
-- is filled directly, as before.
local Event = require 'utils.event'
local Generate = require 'map_gen.shared.generate'
local Global = require 'utils.global'
local Token = require 'utils.token'

local floor = math.floor
local max = math.max
local abs = math.abs

local Public = {}

local TANK = 'storage-tank'
local PIPE = 'pipe'
local PIPE_TO_GROUND = 'pipe-to-ground'
local TURRET = 'flamethrower-turret'
local OIL = 'light-oil'
-- the tank is topped up to this every second
local TANK_FILL = 2000

Public.tank_name = TANK
Public.pipe_name = PIPE
Public.pipe_to_ground_name = PIPE_TO_GROUND
Public.tank_fill = TANK_FILL

local enabled = true
-- outpost_id -> network: the outpost's tile area, the chunks still to generate, its flamethrower
-- turrets and, once built, its tank
local networks = {}
-- chunk key -> ids of the outposts whose area reaches into that chunk
local chunk_outposts = {}
-- unit number of a flamethrower turret the tank feeds -> true
local fed = {}

Global.register(
    {networks = networks, chunk_outposts = chunk_outposts, fed = fed},
    function(tbl)
        networks = tbl.networks
        chunk_outposts = tbl.chunk_outposts
        fed = tbl.fed
    end
)

--- Turns the oil networks on or off; on unless a preset says otherwise.
function Public.set_enabled(value)
    enabled = value ~= false
end

local function chunk_key(x, y)
    return x .. ',' .. y
end

--- Notes where an outpost lies, from the first of its tiles to be generated: `x` and `y` are that
-- tile's position within the outpost (0 to size - 1) and `world` its position on the map.
function Public.record_area(outpost_id, world, x, y, size)
    if not enabled or networks[outpost_id] then
        return
    end

    local left, top = world.x - x, world.y - y
    local network = {
        left = left,
        top = top,
        size = size,
        surface_index = world.surface.index,
        chunks_left = 0,
        turrets = {}
    }
    networks[outpost_id] = network

    for cx = floor(left / 32), floor((left + size - 1) / 32) do
        for cy = floor(top / 32), floor((top + size - 1) / 32) do
            local key = chunk_key(cx, cy)
            local ids = chunk_outposts[key]
            if not ids then
                ids = {}
                chunk_outposts[key] = ids
            end
            ids[#ids + 1] = outpost_id
            network.chunks_left = network.chunks_left + 1
        end
    end
end

--- Adds a flamethrower turret to its outpost's network, to be piped to once the outpost is done.
function Public.add_turret(outpost_id, turret)
    local network = networks[outpost_id]
    if network and not network.built then
        network.turrets[#network.turrets + 1] = turret
    end
end

--- Whether the turret gets its oil from a tank, and so mustn't be filled directly.
function Public.is_fed(turret)
    return fed[turret.unit_number] == true
end

local function live_turrets(network)
    local turrets = {}
    for _, turret in pairs(network.turrets) do
        if turret.valid then
            turrets[#turrets + 1] = turret
        end
    end
    return turrets
end

--- The network whose outpost `entity` stands in, if it has one.
function Public.get_network(entity)
    local position = entity.position
    local x, y = position.x, position.y
    local surface_index = entity.surface.index
    for _, network in pairs(networks) do
        if network.built and network.surface_index == surface_index then
            local left, top, size = network.left, network.top, network.size
            if x >= left and y >= top and x < left + size and y < top + size then
                return network
            end
        end
    end
end

--- The flamethrower turrets still standing that an oil pipe or tank feeds: the tank feeds them
-- all, a pipe those beyond it. While there are any, a destroyed pipe or tank comes back.
function Public.get_live_turrets(entity)
    local network = Public.get_network(entity)
    if not network then
        return {}
    end
    if entity.name == TANK then
        return live_turrets(network)
    end

    local position = entity.position
    local x, y = floor(position.x) - network.left, floor(position.y) - network.top
    local turrets = {}
    for _, turret in pairs(network.serves[y * network.size + x + 1] or {}) do
        if turret.valid then
            turrets[#turrets + 1] = turret
        end
    end
    return turrets
end

--- Called with an oil pipe or tank events.lua has brought back.
Public.respawned =
    Token.register(
    function(entity)
        if entity.name ~= TANK then
            return
        end
        local network = Public.get_network(entity)
        if network then
            network.tank = entity
        end
    end
)

-- east, south, west, north, as steps, as defines.direction and the other way round
local DX = {1, 0, -1, 0}
local DY = {0, 1, 0, -1}
local DIRECTIONS = {defines.direction.east, defines.direction.south, defines.direction.west, defines.direction.north}
local OPPOSITE = {3, 4, 1, 2}
local DIRECTION_INDEX = {['1,0'] = 1, ['0,1'] = 2, ['-1,0'] = 3, ['0,-1'] = 4}

local function build(network)
    network.built = true

    local turrets = live_turrets(network)
    network.turrets = turrets
    local surface = game.get_surface(network.surface_index)
    if #turrets == 0 or not surface then
        return
    end

    local left, top, size = network.left, network.top, network.size

    -- tiles are numbered row by row from the outpost's top left, from 1
    local function index(x, y)
        x, y = x - left, y - top
        if x < 0 or y < 0 or x >= size or y >= size then
            return nil
        end
        return y * size + x + 1
    end

    local function coords(k)
        k = k - 1
        return left + k % size, top + floor(k / size)
    end

    local function tile_of(position)
        local x, y = floor(position.x), floor(position.y)
        return index(x, y), x, y
    end

    -- tiles another machine's pipe connection points at: a pipe there would mix its fluid in
    local blocked = {}
    local area = {{left, top}, {left + size, top + size}}
    for _, entity in pairs(surface.find_entities_filtered {area = area}) do
        if entity.name ~= TURRET then
            local fluidbox = entity.fluidbox
            for i = 1, #fluidbox do
                for _, connection in pairs(fluidbox.get_pipe_connections(i)) do
                    local k = tile_of(connection.target_position)
                    if k then
                        blocked[k] = true
                    end
                end
            end
        end
    end

    local free = {}
    local pipe_spec = {name = PIPE, position = nil, force = 'enemy'}
    local function is_free(k, x, y)
        local f = free[k]
        if f == nil then
            pipe_spec.position = {x + 0.5, y + 0.5}
            f = not blocked[k] and surface.can_place_entity(pipe_spec)
            free[k] = f
        end
        return f
    end

    -- the tiles the turrets' pipe connections point at, which the tank mustn't cover
    local ports = {}
    for _, turret in pairs(turrets) do
        for _, connection in pairs(turret.fluidbox.get_pipe_connections(1)) do
            local k = tile_of(connection.target_position)
            if k then
                ports[k] = true
            end
        end
    end

    local tank_spec = {name = TANK, position = nil, force = 'enemy'}
    local function tank_fits(x, y)
        for tx = x - 1, x + 1 do
            for ty = y - 1, y + 1 do
                local k = index(tx, ty)
                if not k or ports[k] then
                    return false
                end
            end
        end
        tank_spec.position = {x + 0.5, y + 0.5}
        return surface.can_place_entity(tank_spec)
    end

    -- the tank goes as near the middle as it fits, where none of its connections meets a machine
    local tank
    local cx, cy = left + floor(size / 2), top + floor(size / 2)
    for r = 0, floor(size / 2) - 2 do
        for dx = -r, r do
            for dy = -r, r do
                if not tank and max(abs(dx), abs(dy)) == r and tank_fits(cx + dx, cy + dy) then
                    local candidate = surface.create_entity(tank_spec)
                    if candidate then
                        for _, connection in pairs(candidate.fluidbox.get_pipe_connections(1)) do
                            if connection.target then
                                candidate.destroy()
                                break
                            end
                        end
                    end
                    if candidate and candidate.valid then
                        tank = candidate
                    end
                end
            end
        end
        if tank then
            break
        end
    end
    if not tank then
        return
    end

    -- tiles a pipe joins the oil on: the tank's connections, then every pipe laid
    local joins = {}
    local piped = {}
    -- tiles with a pipe-to-ground, or that a pair of them passes under: no other pipe-to-ground
    -- goes there, or it would pair with the wrong one
    local underground = {}
    for _, connection in pairs(tank.fluidbox.get_pipe_connections(1)) do
        local k, x, y = tile_of(connection.target_position)
        if k and is_free(k, x, y) then
            joins[k] = true
        end
    end

    local function step(k, d)
        local x, y = coords(k)
        x, y = x + DX[d], y + DY[d]
        return index(x, y), x, y
    end

    local function open(k, x, y)
        return joins[k] or is_free(k, x, y)
    end

    -- Breadth first from a turret's free connections to the nearest tile that joins the oil. A
    -- state is a tile, the direction it was entered in (0 for a start) and whether it is where a
    -- pipe-to-ground comes up, which only carries on straight ahead. With `jumps`, where the way
    -- ahead is blocked, a pipe-to-ground goes down and comes up at the next free tile, up to 10 on.
    -- Each tile is used once, so a path never crosses itself.
    local function route(starts, jumps)
        local previous, jumped, seen = {}, {}, {}
        local queue, head = {}, 1

        local function push(k, d, up, from, jump)
            local state = (k * 5 + d) * 2 + (up and 1 or 0)
            if not seen[k] then
                seen[k] = true
                previous[state] = from
                jumped[state] = jump
                queue[#queue + 1] = state
            end
        end

        for _, start in pairs(starts) do
            push(start[1], start[2], false, 0, false)
        end

        while queue[head] do
            local state = queue[head]
            head = head + 1
            local up = state % 2 == 1
            local t = (state - state % 2) / 2
            local d = t % 5
            local k = (t - d) / 5

            if joins[k] and not up then
                -- the path, from the tile it joins at back to the turret
                local path = {}
                while state ~= 0 do
                    t = (state - state % 2) / 2
                    d = t % 5
                    k = (t - d) / 5
                    local entry = {k = k}
                    if jumped[state] then
                        entry.direction = DIRECTIONS[d]
                        entry.comes_up = true
                        path[#path + 1] = entry
                        state = previous[state]
                        t = (state - state % 2) / 2
                        path[#path + 1] = {k = (t - t % 5) / 5, direction = DIRECTIONS[OPPOSITE[d]]}
                    else
                        path[#path + 1] = entry
                    end
                    state = previous[state]
                end
                return path
            end

            for e = 1, 4 do
                if not up or e == d then
                    local nk, nx, ny = step(k, e)
                    if nk and open(nk, nx, ny) then
                        push(nk, e, false, state, false)
                    end
                end
            end

            local ahead, ax, ay = step(k, d ~= 0 and d or 1)
            if jumps and d ~= 0 and not up and not underground[k] and ahead and not open(ahead, ax, ay) then
                local nk = ahead
                for _ = 2, 10 do
                    if not nk or underground[nk] then
                        break
                    end
                    nk, ax, ay = step(nk, d)
                    if nk and not underground[nk] and is_free(nk, ax, ay) and not joins[nk] then
                        local after, bx, by = step(nk, d)
                        if after and open(after, bx, by) then
                            push(nk, d, true, state, true)
                        end
                        break
                    end
                end
            end
        end
    end

    local pipes = {}
    -- each pipe's tile -> the next tile towards the tank (0 for a pipe on the tank's connection)
    local towards_tank = {}
    -- each turret -> the tile of the pipe it draws from
    local feeds_from = {}
    local tank_position = tank.position
    table.sort(
        turrets,
        function(a, b)
            local pa, pb = a.position, b.position
            return (pa.x - tank_position.x) ^ 2 + (pa.y - tank_position.y) ^ 2 < (pb.x - tank_position.x) ^ 2 + (pb.y - tank_position.y) ^ 2
        end
    )
    for _, turret in pairs(turrets) do
        local starts = {}
        local joined = false
        for _, connection in pairs(turret.fluidbox.get_pipe_connections(1)) do
            local k, x, y = tile_of(connection.target_position)
            if k then
                if piped[k] then
                    joined = joined or joins[k]
                    feeds_from[turret] = k
                elseif is_free(k, x, y) then
                    local from = connection.position
                    local d = DIRECTION_INDEX[(x - floor(from.x)) .. ',' .. (y - floor(from.y))]
                    starts[#starts + 1] = {k, d or 0}
                end
            end
        end
        -- a turret with no free connection may still join through the turret beside it
        if not joined and #starts > 0 then
            -- under ground only where there is no way round
            local path = route(starts, false) or route(starts, true)
            if path then
                for i, entry in pairs(path) do
                    local k = entry.k
                    local x, y = coords(k)
                    if not piped[k] then
                        local spec = {name = PIPE, position = {x + 0.5, y + 0.5}, force = 'enemy'}
                        if entry.direction then
                            spec.name = PIPE_TO_GROUND
                            spec.direction = entry.direction
                        end
                        local pipe = surface.create_entity(spec)
                        if pipe then
                            pipes[#pipes + 1] = pipe
                            piped[k] = true
                            towards_tank[k] = path[i - 1] and path[i - 1].k or 0
                            if entry.direction then
                                underground[k] = true
                            else
                                joins[k] = true
                            end
                        end
                    end
                    -- the tiles a pair of pipe-to-grounds passes under
                    local below = path[i + 1]
                    if entry.comes_up then
                        local bx, by = coords(below.k)
                        local sx, sy = (bx > x and 1) or (bx < x and -1) or 0, (by > y and 1) or (by < y and -1) or 0
                        local gx, gy = x + sx, y + sy
                        while gx ~= bx or gy ~= by do
                            underground[index(gx, gy)] = true
                            gx, gy = gx + sx, gy + sy
                        end
                    end
                end
                feeds_from[turret] = path[#path].k
            end
        end
    end

    tank.fluidbox[1] = {name = OIL, amount = TANK_FILL}
    local segment = tank.fluidbox.get_fluid_segment_id(1)
    local any = false
    for _, turret in pairs(turrets) do
        if segment and turret.fluidbox.get_fluid_segment_id(1) == segment then
            fed[turret.unit_number] = true
            any = true
        end
    end

    if not any then
        tank.destroy()
        for _, pipe in pairs(pipes) do
            pipe.destroy()
        end
        return
    end

    -- a turret with no pipe of its own draws from the pipe of the turret beside it
    for _ = 1, #turrets do
        local changed = false
        for _, turret in pairs(turrets) do
            if not feeds_from[turret] and fed[turret.unit_number] then
                for _, connection in pairs(turret.fluidbox.get_pipe_connections(1)) do
                    local beside = surface.find_entity(TURRET, connection.target_position)
                    if beside and feeds_from[beside] then
                        feeds_from[turret] = feeds_from[beside]
                        changed = true
                        break
                    end
                end
            end
        end
        if not changed then
            break
        end
    end

    -- what each pipe feeds: the turrets whose way to the tank runs through it
    local serves = {}
    for turret, k in pairs(feeds_from) do
        if fed[turret.unit_number] then
            while k and k ~= 0 do
                local list = serves[k]
                if not list then
                    list = {}
                    serves[k] = list
                end
                list[#list + 1] = turret
                k = towards_tank[k]
            end
        end
    end

    network.tank = tank
    network.serves = serves
end

Event.add(
    Generate.events.on_chunk_generated,
    function(event)
        local position = event.position
        local key = chunk_key(position.x, position.y)
        local ids = chunk_outposts[key]
        if not ids then
            return
        end
        chunk_outposts[key] = nil

        for _, outpost_id in pairs(ids) do
            local network = networks[outpost_id]
            if network and not network.built then
                network.chunks_left = network.chunks_left - 1
                if network.chunks_left <= 0 then
                    if #network.turrets > 0 then
                        build(network)
                    else
                        networks[outpost_id] = nil
                    end
                end
            end
        end
    end
)

Event.on_nth_tick(
    60,
    function()
        for _, network in pairs(networks) do
            local tank = network.tank
            if tank and tank.valid then
                local fluid = tank.fluidbox[1]
                if not fluid or fluid.amount < TANK_FILL then
                    tank.fluidbox[1] = {name = OIL, amount = TANK_FILL}
                end
            end
        end
    end
)

return Public
