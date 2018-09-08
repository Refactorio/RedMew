-- this
local Template = {}

Template.events = {
    on_entity_placed = script.generate_event_name()
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
        surface.create_entity(entity)

        script.raise_event(Template.events.on_entity_placed, {entity = entity})
    end
end

return Template
