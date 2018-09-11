-- this
local Template = {}

Template.events = {
    --[[--
        When an entity is placed via the template function.
         - event.entity LuaEntity
    ]]
    on_placed_entity = script.generate_event_name(),
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
    if (nil == entities) then
        entities = {}
    end

    surface.set_tiles(tiles)

    for _, entity in pairs(entities) do
        entity = surface.create_entity(entity)
        if (nil == entity) then
            error('Failed creating entity ' .. entity.name .. ' on surface.')
        end
        script.raise_event(Template.events.on_placed_entity, {entity = entity})
    end
end

return Template
