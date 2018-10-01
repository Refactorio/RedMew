-- dependencies
local Task = require 'utils.Task'
local Token = require 'utils.global_token'
local Debug = require 'map_gen.Diggy.Debug'

-- this
local Template = {}

local tiles_per_call = 5 --how many tiles are inserted with each call of insert_action
local entities_per_call = 5  --how many entities are inserted with each call of insert_action

Template.events = {
    --[[--
        When an entity is placed via the template function.
         - event.entity LuaEntity
    ]]
    on_placed_entity = script.generate_event_name(),

    --[[--
        Triggers when an 'out-of-map' tile is placed on something else.

        {surface, old_tile={name, position={x, y}}}
    ]]
    on_void_added = script.generate_event_name(),

    --[[--
        Triggers when an 'out-of-map' tile is replaced by something else.

        {surface, old_tile={name, position={x, y}}}
    ]]
    on_void_removed = script.generate_event_name(),
}

local function min(a,b)
    if a < b then return a end
    return b
end

local function insert_next_tiles(data)
    local void_removed = {}
    local void_added = {}
    local surface = data.surface
    local tiles = {}

    pcall(function() --use pcall to assure tile_iterator is always incremented, to avoid endless loops
        for i = data.tile_iterator, math.min(data.tile_iterator + tiles_per_call - 1, data.tiles_n)   do
            local new_tile = data.tiles[i]
            table.insert(tiles, new_tile)
            local current_tile = surface.get_tile(new_tile.position.x, new_tile.position.y)
            local current_is_void = current_tile.name == 'out-of-map'
            local new_is_void = new_tile.name == 'out-of-map'

            if (current_is_void and not new_is_void) then
                table.insert(void_removed, {surface = surface, old_tile = {name = current_tile.name, position = current_tile.position}})
            end

            if (new_is_void and not current_is_void) then
                table.insert(void_added, {surface = surface, old_tile = {name = current_tile.name, position = current_tile.position}})
            end
        end
    end)

    data.tile_iterator = data.tile_iterator + tiles_per_call

    surface.set_tiles(tiles)

    for _, event in pairs(void_removed) do
        script.raise_event(Template.events.on_void_removed, event)
    end

    for _, event in pairs(void_added) do
        script.raise_event(Template.events.on_void_added, event)
    end
end

local function insert_next_entities(data)
    local created_entities = {}
    local surface = data.surface

    pcall(function() --use pcall to assure tile_iterator is always incremented, to avoid endless loops
        for i = data.entity_iterator, math.min(data.entity_iterator + entities_per_call - 1, data.entities_n)   do
            local entity = data.entities[i]
            created_entity = surface.create_entity(entity)
            if (nil == created_entity) then
                error('Failed creating entity ' .. entity.name .. ' on surface.')
            end

            if ('sand-rock-big' == created_entity.name) then
                created_entity.destructible = false
            end

            table.insert(created_entities, created_entity)
        end
    end)

    data.entity_iterator = data.entity_iterator + entities_per_call

    for _, entity in pairs(created_entities) do
        script.raise_event(Template.events.on_placed_entity, {entity = entity})
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
    local total_calls = math.ceil(tiles_n / tiles_per_call) + (entities_n / entities_per_call)
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
    for i=1,4 do
      continue = insert_action(data)
      if not continue  then
          return
      end
    end
    if continue then
        Task.queue_task(insert_token, data, total_calls - 4)
    end
end

--[[--
    Designed to spawn aliens, uses find_non_colliding_position.

    @see LuaSurface.entity

    @param surface LuaSurface to put the tiles and entities on
    @param units table of entities as required by create_entity
]]
function Template.units(surface, units)
    for _, entity in pairs(units) do
        local position = surface.find_non_colliding_position(entity.name, entity.position, 2, 1)

        if (nil ~= position) then
            entity.position = position
            surface.create_entity(entity)
        else
            Debug.print('Failed to spawn \'' .. entity.name .. '\' at \'' .. serpent.line(entity.position) .. '\'')
        end
    end
end

--[[--
    Designed to spawn resources.

    @see LuaSurface.entity

    @param surface LuaSurface to put the tiles and entities on
    @param resources table of entities as required by create_entity
]]
function Template.resources(surface, resources)
    for _, entity in pairs(resources) do
        surface.create_entity(entity)
    end
end

return Template
