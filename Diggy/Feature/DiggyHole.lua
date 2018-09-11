--[[-- info
    Provides the ability to "mine" through out-of-map tiles by destroying or
    mining rocks next to it.
]]

-- dependencies
local Event = require 'utils.event'
local Scanner = require 'Diggy.Scanner'
local Template = require 'Diggy.Template'

-- this
local DiggyHole = {}

-- list of all possible events to subscribe to
DiggyHole.events = {
    --[[--
        Triggers when an 'out-of-map' tile is replaced by a rock in
        DiggyHole.diggy_hole.

        Can be fired for each position replaced. It's recommended to avoid
        performance heavy listeners. Off-load them into a queue processed on
        ticks.
    ]]
    on_out_of_map_removed = script.generate_event_name(),
}

--[[--
    Triggers a diggy diggy hole for a given sand-rock-big.

    Will return true even if the tile behind it is immune.

    @param entity LuaEntity
    @param temporary_inventory LuaInventory
]]
local function diggy_hole(entity, temporary_inventory)
    if (entity.name ~= 'sand-rock-big') then
        return
    end

    -- prevent the mined ore from reaching the inventory
    if (nil ~= temporary_inventory) then
        temporary_inventory.clear()
    end

    local tiles = {}
    local rocks = {}

    local out_of_map_found = Scanner.scan_around_position(entity.surface, entity.position, 'out-of-map');

    for _, position in pairs(out_of_map_found) do
        table.insert(tiles, {name = 'dirt-' .. math.random(1, 7), position = {x = position.x, y = position.y}})
        table.insert(rocks, {name = 'sand-rock-big', position = {x = position.x, y = position.y}})
    end

    Template.insert(entity.surface, tiles, rocks)

    for _, position in pairs(out_of_map_found) do
        script.raise_event(DiggyHole.events.on_out_of_map_removed, {
            surface = entity.surface,
            position = {x = position.x, y = position.y}
        })
    end
end

--[[--
    Registers all event handlers.
]]
function DiggyHole.register(config)
    Event.add(defines.events.on_entity_died, function (event)
        diggy_hole(event.entity)
    end)

    Event.add(defines.events.on_player_mined_entity, function (event)
        diggy_hole(event.entity, event.buffer)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function DiggyHole.initialize(config)

end

return DiggyHole
