-- this
local Template = {}

Template.events = {
    --[[--
        When an entity is placed via the template function.
         - event.entity LuaEntity
    ]]
    on_placed_entity = script.generate_event_name(),

    --[[--
        Triggers when an 'out-of-map' tile is replaced by a rock in
        DiggyHole.diggy_hole.

        Can be fired for each position replaced. It's recommended to avoid
        performance heavy listeners. Off-load them into a queue processed on
        ticks.
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
function Template.insert(surface, tiles, entities, fire_void_removed_event)
    surface.set_tiles(tiles)

    if (fire_void_removed_event) then
        for _, tile in pairs(tiles) do
            if ('out-of-map' ~= $tile.name) then
                script.raise_event(Template.events.on_void_removed, {
                    surface = surface,
                    position = {x = tile.position.x, y = tile.position.y}
                })
            end
        end
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
