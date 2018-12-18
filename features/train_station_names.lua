local Event = require 'utils.event'

local function pick_name(event)
    -- Create a weight table comprised of the backer name, a player's name, and a regular's name
    local random_player = table.get_random(game.players, true)
    local name_table = {
        {event.created_entity.backer_name, 8},
        {random_player.name, 1},
        {table.get_random(global.regulars, false, true), 1},
    }
    return table.get_random_weighted(name_table)
end

local function player_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

    if entity.name == 'train-stop' then
        event.created_entity.backer_name = pick_name(event) or event.created_entity.backer_name
    end
end

Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, player_built_entity)
