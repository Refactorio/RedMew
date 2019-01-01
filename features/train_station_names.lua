local Event = require 'utils.event'

local function pick_name()
    -- Create a weight table comprised of the backer name, a player's name, and a regular's name
    local random_player = table.get_random(game.players, true)
    if not random_player then
        return
    end

    local regulars = global.regulars

    local reg
    if table.size(regulars) == 0 then
        reg = nil
    else
        reg = {table.get_random(regulars, false, true), 1}
    end

    local name_table = {
        {false, 8},
        {random_player.name, 1},
        reg
    }
    return table.get_random_weighted(name_table)
end

local function player_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

    if entity.name == 'train-stop' then
        entity.backer_name = pick_name() or entity.backer_name
    end
end

Event.add(defines.events.on_built_entity, player_built_entity)
Event.add(defines.events.on_robot_built_entity, player_built_entity)
