local Event = require 'utils.event'
local Game = require 'utils.game'

local function player_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then return end

    if entity.name == 'train-stop' then
        local y = math.random(1, 3)
        if y ~= 1 then
            local x = math.random(1, #Game.players)
            local player = Game.get_player_by_index(x)
            event.created_entity.backer_name = player.name
        end
    end
end

Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, player_built_entity)
