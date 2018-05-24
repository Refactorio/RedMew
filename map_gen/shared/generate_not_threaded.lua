local Token = require 'utils.global_token'
local Event = require 'utils.event'

local shape
local regen_decoratives

local function do_row(row, data)
    local function do_tile(tile, pos)
        if not tile then
            table.insert(data.tiles, {name = 'out-of-map', position = pos})
        elseif type(tile) == 'string' then
            table.insert(data.tiles, {name = tile, position = pos})
        end
    end

    local y = data.top_y + row
    local top_x = data.top_x

    data.y = y

    for x = top_x, top_x + 31 do
        data.x = x
        local pos = {data.x, data.y}

        -- local coords need to be 'centered' to allow for correct rotation and scaling.
        local tile = shape(x + 0.5, y + 0.5, data)

        if type(tile) == 'table' then
            do_tile(tile.tile, pos)

            local entities = tile.entities
            if entities then
                for _, entity in ipairs(entities) do
                    if not entity.position then
                        entity.position = pos
                    end
                    table.insert(data.entities, entity)
                end
            end

            local decoratives = tile.decoratives
            if decoratives then
                for _, decorative in ipairs(decoratives) do
                    table.insert(data.decoratives, decorative)
                end
            end
        else
            do_tile(tile, pos)
        end
    end
end

local function do_place_tiles(data)
    data.surface.set_tiles(data.tiles, true)
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
        if surface.can_place_entity(e) then
            local entity = surface.create_entity(e)
            if e.callback then
                local callback = Token.get(e.callback)
                callback(entity)
            end
        end
    end
end

local function on_chunk(event)
    local area = event.area

    local data = {
        area = area,
        top_x = area.left_top.x,
        top_y = area.left_top.y,
        surface = event.surface,
        tiles = {},
        entities = {},
        decoratives = {}
    }

    for row = 0, 31 do
        do_row(row, data)
    end

    do_place_tiles(data)
    do_place_entities(data)
    do_place_decoratives(data)
end

local function init(args)
    shape = args.shape
    regen_decoratives = args.regen_decoratives

    Event.add(defines.events.on_chunk_generated, on_chunk)
end

return init
