-- this
local Template = {}

Template.events = {
    --[[--
        When an entity is placed via the template function.
         - event.entity LuaEntity
    ]]
    on_placed_entity = script.generate_event_name(),

    --[[--
        Triggers when an 'out-of-map' tile is placed on something else.
    ]]
    on_void_added = script.generate_event_name(),

    --[[--
        Triggers when an 'out-of-map' tile is replaced by something else.
    ]]
    on_void_removed = script.generate_event_name(),
}

--[[--
    Inserts a batch of tiles and then entities.

    @see LuaSurface.set_tiles
    @see LuaSurface.entity

    @param surface LuaSurface to put the tiles and entities on
    @param tiles table of tiles as required by set_tiles
    @param entities table of entities as required by create_entity
]]
function Template.insert(surface, tiles, entities)
    local void_removed = {}
    local void_added = {}

    for _, new_tile in pairs(tiles) do
        local current_tile = surface.get_tile(new_tile.position.x, new_tile.position.y)
        local current_is_void = current_tile.name == 'out-of-map'
        local new_is_void = new_tile.name == 'out-of-map'

        if (current_is_void and not new_is_void) then
            table.insert(void_removed, {surface = surface, old_tile = {name = current_tile.name, position = current_tile.position}})
        end

        if (new_is_void and not current_is_void) then
            table.insert(void_added, {surface = surface, old_tile = {name = current_tile.name, position = current_tile.position})
        end
    end

    surface.set_tiles(tiles)

    for _, event in pairs(void_removed) do
        script.raise_event(Template.events.on_void_removed, event)
    end

    for _, event in pairs(void_added) do
        script.raise_event(Template.events.on_void_added, event)
    end

    local created_entities = {}

    for _, entity in pairs(entities) do
        created_entity = surface.create_entity(entity)
        if (nil == created_entity) then
            error('Failed creating entity ' .. entity.name .. ' on surface.')
        end

        table.insert(created_entities, created_entity)
    end

    for _, entity in pairs(created_entities) do
        script.raise_event(Template.events.on_placed_entity, {entity = entity})
    end
end

return Template
