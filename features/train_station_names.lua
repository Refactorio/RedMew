local Event = require 'utils.event'

local function player_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

    if entity.name == 'train-stop' then
        local y = math.random(1, 3)
        if y ~= 1 then
            local player = table.get_random(game.players, true)
            event.created_entity.backer_name = player.name
        end
    end
end

Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, player_built_entity)
