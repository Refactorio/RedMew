local Event = require 'utils.event'
local Game = require 'utils.game'

local function preserve_bot(event)
    local player = Game.get_player_by_index(event.player_index)
    local entity = player.selected

    if entity == nil or not entity.valid then
        return
    end

    if entity.name ~= 'construction-robot' then
        return
    end
    local logistic_network = entity.logistic_network

    if logistic_network == nil or not logistic_network.valid then
        --prevents an orphan bot from being unremovable
        entity.minable = false
        return
    end

    -- All valid logistic networks should have at least one cell
    local cell = logistic_network.cells[1]
    local owner = cell.owner

    --checks if construction-robot is part of a mobile logistic network
    if owner.name ~= 'player' then
        return
    end

    --checks if construction-robot is owned by the player that has selected it
    if owner.player.name == player.name then
        entity.minable = true
        return
    end

    entity.minable = false
end

Event.add(defines.events.on_selected_entity_changed, preserve_bot)
