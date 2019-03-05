-- dependencies
local Task = require 'utils.task'
local Token = require 'utils.token'
local Event = require 'utils.event'
local min = math.min
local ceil = math.ceil
local raise_event = script.raise_event
local queue_task = Task.queue_task
local pairs = pairs
local pcall = pcall

-- this
local Template = {}

local tiles_per_call = 8 --how many tiles are inserted with each call of insert_action
local entities_per_call = 8 --how many entities are inserted with each call of insert_action

Template.events = {
    --[[--
        When an entity is placed via the template function.
         - event.entity LuaEntity
    ]]
    on_placed_entity = Event.generate_event_name('on_placed_entity'),

    --[[--
        Triggers when an 'out-of-map' tile is replaced by something else.

        {surface, old_tile={name, position={x, y}}}
    ]]
    on_void_removed = Event.generate_event_name('on_void_removed'),
}

local on_void_removed = Template.events.on_void_removed
local on_placed_entity = Template.events.on_placed_entity

local function insert_next_tiles(data)
    local void_removed = {}
    local void_removed_count = 0
    local surface = data.surface
    local get_tile = surface.get_tile
    local tiles = {}
    local tile_count = 0
    local tile_iterator = data.tile_iterator

    pcall(function()
        --use pcall to assure tile_iterator is always incremented, to avoid endless loops
        for i = tile_iterator, min(tile_iterator + tiles_per_call - 1, data.tiles_n) do
            local new_tile = data.tiles[i]
            tile_count = tile_count + 1
            tiles[tile_count] = new_tile

            if new_tile.name ~= 'out-of-map' then
                local current_tile = get_tile(new_tile.position.x, new_tile.position.y)
                if current_tile.name == 'out-of-map' then
                    void_removed_count = void_removed_count + 1
                    void_removed[void_removed_count] = {surface = surface, position = current_tile.position}
                end
            end
        end
    end)

    data.tile_iterator = tile_iterator + tiles_per_call

    surface.set_tiles(tiles)

    for i = 1, void_removed_count do
        raise_event(on_void_removed, void_removed[i])
    end
end

local function insert_next_entities(data)
    local created_entities = {}
    local created_entities_count = 0
    local surface = data.surface
    local create_entity = surface.create_entity

    pcall(function()
        --use pcall to assure tile_iterator is always incremented, to avoid endless loops
        for i = data.entity_iterator, min(data.entity_iterator + entities_per_call - 1, data.entities_n) do
            created_entities_count = created_entities_count + 1
            created_entities[created_entities_count] = create_entity(data.entities[i])
        end
    end)

    data.entity_iterator = data.entity_iterator + entities_per_call

    for i = 1, created_entities_count do
        raise_event(on_placed_entity, {entity = created_entities[i]})
    end

    return data.entity_iterator <= data.entities_n
end

local function insert_action(data)
    if data.tile_iterator <= data.tiles_n then
        insert_next_tiles(data)
        return true
    end

    return insert_next_entities(data)
end

local insert_token = Token.register(insert_action)

--[[--
    Inserts a batch of tiles and then entities.

    @see LuaSurface.set_tiles
    @see LuaSurface.entity

    @param surface LuaSurface to put the tiles and entities on
    @param tiles table of tiles as required by set_tiles
    @param entities table of entities as required by create_entity
]]
function Template.insert(surface, tiles, entities)
    tiles = tiles or {}
    entities = entities or {}

    local tiles_n = #tiles
    local entities_n = #entities
    local total_calls = ceil(tiles_n / tiles_per_call) + (entities_n / entities_per_call)
    local data = {
        tiles_n = tiles_n,
        tile_iterator = 1,
        entities_n = entities_n,
        entity_iterator = 1,
        surface = surface,
        tiles = tiles,
        entities = entities
    }

    local continue = true
    for _ = 1, 4 do
        continue = insert_action(data)
        if not continue then
            return
        end
    end

    if continue then
        queue_task(insert_token, data, total_calls - 4)
    end
end

--[[--
    Designed to spawn resources.

    @see LuaSurface.entity

    @param surface LuaSurface to put the tiles and entities on
    @param resources table of entities as required by create_entity
]]
function Template.resources(surface, resources)
    local create_entity = surface.create_entity
    for _, entity in pairs(resources) do
        create_entity(entity)
    end
end

Template.diggy_rocks = {'sand-rock-big', 'rock-big', 'rock-huge'}

---Returns true if the entity name is that of a diggy rock.
---@param entity_name string
function Template.is_diggy_rock(entity_name)
    return entity_name == 'sand-rock-big' or entity_name == 'rock-big' or entity_name == 'rock-huge'
end

return Template
