local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

local insert = table.insert

local function get_mins(entities, tiles)
    local min_x, min_y = math.huge, math.huge

    for _, e in ipairs(entities) do
        local p = e.position
        local x, y = p.x, p.y

        if x < min_x then
            min_x = x
        end
        if y < min_y then
            min_y = y
        end
    end

    for _, e in ipairs(tiles) do
        local p = e.position
        local x, y = p.x, p.y

        if x < min_x then
            min_x = x
        end
        if y < min_y then
            min_y = y
        end
    end

    return min_x, min_y
end

local function output(result, prepend, size, player)
    local str = {prepend}
    insert(str, '{\npart_size = ')
    insert(str, size)
    insert(str, ',\n')

    for i, entry in pairs(result) do
        insert(str, '[')
        insert(str, i)
        insert(str, '] = {')

        local e = entry.entity
        if e then
            insert(str, 'entity = {')

            insert(str, "name = '")
            insert(str, e.name)
            insert(str, "'")

            local dir = e.direction
            if dir then
                insert(str, ', direction = ')
                insert(str, dir)
            end

            local offset = e.offset
            if offset then
                insert(str, ', offset = ')
                insert(str, offset)
            end

            insert(str, '}')
        end

        local t = entry.tile
        if t then
            if e then
                insert(str, ', ')
            end
            insert(str, "tile = '")
            insert(str, t.name)
            insert(str, "'")
        end

        insert(str, '}')
        insert(str, ',\n')
    end
    table.remove(str)

    insert(str, '\n}')

    str = table.concat(str)

    game.write_file('bp.lua', str, false, player.index)
    player.print('bp.lua written')
end

local function extract1(args, player)
    local size = args.size
    local cs = player.cursor_stack

    if not (cs.valid_for_read and cs.name == 'blueprint' and cs.is_blueprint_setup()) then
        player.print('invalid blueprint')
        return
    end

    size = size or 6

    local es = cs.get_blueprint_entities() or {}
    local ts = cs.get_blueprint_tiles() or {}

    local min_x, min_y = get_mins(es, ts)

    min_x = 1 - math.ceil(min_x)
    min_y = 1 - math.ceil(min_y)

    local result = {}
    for _, e in ipairs(es) do
        local p = e.position
        local x, y = p.x + min_x, p.y + min_y
        local x2, y2 = math.ceil(x), math.ceil(y)
        local i = (y2 - 1) * size + x2

        local entry = result[i]
        if not entry then
            entry = {}
            result[i] = entry
        end

        entry.entity = e
    end

    for _, e in ipairs(ts) do
        local p = e.position
        local x, y = p.x + min_x, p.y + min_y
        x, y = math.ceil(x), math.ceil(y)
        local i = (y - 1) * size + x

        local entry = result[i]
        if not entry then
            entry = {}
            result[i] = entry
        end

        entry.tile = e
    end
    output(result, 'ob.make_1_way', size, player)
end

local function extract4(args, player)
    local size = args.size
    local cs = player.cursor_stack

    if not (cs.valid_for_read and cs.name == 'blueprint' and cs.is_blueprint_setup()) then
        player.print('invalid blueprint')
        return
    end

    size = size or 6

    local es = cs.get_blueprint_entities() or {}
    local ts = cs.get_blueprint_tiles() or {}

    local min_x, min_y = get_mins(es, ts)

    min_x = 1 - math.floor(min_x)
    min_y = 1 - math.floor(min_y)

    local result = {}
    for _, e in ipairs(es) do
        local p = e.position
        local x, y = p.x + min_x, p.y + min_y
        local x2, y2 = math.floor(x), math.floor(y)
        local i = (y2 - 1) * size + x2

        local offset = 0
        if x2 ~= x then
            offset = offset + 1
        end
        if y2 ~= y then
            offset = offset + 2
        end

        if offset ~= 0 then
            e.offset = offset
        end

        local entry = result[i]
        if not entry then
            entry = {}
            result[i] = entry
        end

        entry.entity = e
    end

    for _, t in ipairs(ts) do
        local p = t.position
        local x, y = p.x + min_x, p.y + min_y
        x, y = math.ceil(x), math.ceil(y)
        local i = (y - 1) * size + x

        local entry = result[i]
        if not entry then
            entry = {}
            result[i] = entry
        end

        entry.tile = t
    end
    output(result, 'ob.make_4_way', size, player)
end

Command.add(
    'crash-site-extract1',
    {
        arguments = {'size'},
        default_values = {size = 6},
        required_rank = Ranks.admin
    },
    extract1
)
Command.add(
    'crash-site-extract4',
    {
        arguments = {'size'},
        default_values = {size = 6},
        required_rank = Ranks.admin
    },
    extract4
)
