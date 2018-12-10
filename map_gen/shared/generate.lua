local Task = require 'utils.schedule'
local Token = require 'utils.token'
local Event = require 'utils.event'

local insert = table.insert

local tiles_per_tick
local regen_decoratives
local surfaces

local total_calls

local function do_tile(y, x, data, shape)
    local function do_tile_inner(tile, pos)
        if not tile then
            insert(data.tiles, {name = 'out-of-map', position = pos})
        elseif type(tile) == 'string' then
            insert(data.tiles, {name = tile, position = pos})
        end
    end

    local pos = {x, y}

    -- local coords need to be 'centered' to allow for correct rotation and scaling.
    local tile = shape(x + 0.5, y + 0.5, data)

    if type(tile) == 'table' then
        do_tile_inner(tile.tile, pos)

        local hidden_tile = tile.hidden_tile
        if hidden_tile then
            insert(data.hidden_tiles, {tile = hidden_tile, position = pos})
        end

        local entities = tile.entities
        if entities then
            for _, entity in ipairs(entities) do
                if not entity.position then
                    entity.position = pos
                end
                insert(data.entities, entity)
            end
        end

        local decoratives = tile.decoratives
        if decoratives then
            for _, decorative in ipairs(decoratives) do
                insert(data.decoratives, decorative)
            end
        end
    else
        do_tile_inner(tile, pos)
    end
end

local function do_place_tiles(data)
    data.surface.set_tiles(data.tiles, true)
end

local function do_place_hidden_tiles(data)
    local surface = data.surface
    for _, t in ipairs(data.hidden_tiles) do
        surface.set_hidden_tile(t.position, t.tile)
    end
end

local decoratives = {
    'brown-asterisk',
    'brown-carpet-grass',
    'brown-fluff',
    'brown-fluff-dry',
    'brown-hairy-grass',
    'garballo',
    'garballo-mini-dry',
    'green-asterisk',
    'green-bush-mini',
    'green-carpet-grass',
    'green-hairy-grass',
    'green-pita',
    'green-pita-mini',
    'green-small-grass',
    'red-asterisk'
}

local function do_place_decoratives(data)
    if regen_decoratives then
        data.surface.regenerate_decorative(decoratives, {{data.top_x / 32, data.top_y / 32}})
    end

    local dec = data.decoratives
    if #dec > 0 then
        data.surface.create_decoratives({check_collision = true, decoratives = dec})
    end
end

local function do_place_entities(data)
    local surface = data.surface
    for _, e in ipairs(data.entities) do
        if e.always_place or surface.can_place_entity(e) then
            local entity = surface.create_entity(e)
            if entity and e.callback then
                local callback = Token.get(e.callback)
                callback(entity, e.data)
            end
        end
    end
end

local function run_chart_update(data)
    local x = data.top_x / 32
    local y = data.top_y / 32
    if game.forces.player.is_chunk_charted(data.surface, {x, y}) then
        -- Don't use full area, otherwise adjacent chunks get charted
        game.forces.player.chart(
            data.surface,
            {
                {data.top_x, data.top_y},
                {data.top_x + 1, data.top_y + 1}
            }
        )
    end
end

local function map_gen_action(data)
    local state = data.y

    if state < 32 then
        local shape = surfaces[data.surface.name]
        if shape == nil then
            return false
        end

        local count = tiles_per_tick

        local y = state + data.top_y
        local x = data.x

        local max_x = data.top_x + 32

        data.y = y

        repeat
            count = count - 1
            do_tile(y, x, data, shape)

            x = x + 1
            if x == max_x then
                y = y + 1
                if y == data.top_y + 32 then
                    break
                end
                x = data.top_x
                data.y = y
            end

            data.x = x
        until count == 0

        data.y = y - data.top_y
        return true
    elseif state == 32 then
        do_place_tiles(data)
        data.y = 33
        return true
    elseif state == 33 then
        do_place_hidden_tiles(data)
        data.y = 34
        return true
    elseif state == 34 then
        do_place_entities(data)
        data.y = 35
        return true
    elseif state == 35 then
        do_place_decoratives(data)
        data.y = 36
        return true
    elseif state == 36 then
        run_chart_update(data)
        return false
    end
end

local map_gen_action_token = Token.register(map_gen_action)

local function on_chunk(event)
    local surface = event.surface
    local shape = surfaces[surface.name]

    if not shape then
        return
    end

    local area = event.area

    local data = {
        y = 0,
        x = area.left_top.x,
        area = area,
        top_x = area.left_top.x,
        top_y = area.left_top.y,
        surface = surface,
        tiles = {},
        hidden_tiles = {},
        entities = {},
        decoratives = {}
    }

    Task.queue_task(map_gen_action_token, data, total_calls)
end

local function init(args)
    tiles_per_tick = args.tiles_per_tick or 32
    regen_decoratives = args.regen_decoratives or false
    surfaces = args.surfaces or {}

    total_calls = math.ceil(1024 / tiles_per_tick) + 5

    Event.add(defines.events.on_chunk_generated, on_chunk)
end

return init
