local Event = require 'utils.event'
local Game = require 'utils.game'

local function preserve_bot(event)
    local player = Game.get_player_by_index(event.player_index)
    local entity = player.selected

    if entity == nil or not entity.valid then
        return
    end

    if entity.name == 'construction-robot' then
        local logistic_cell = entity.logistic_network.cells[1]

        --Checks if construction-robot is part of a mobile logistic network
        if logistic_cell.owner.name ~= 'player' then
            return
        end

        --checks if construction-robot is owned by the player that has selected it
        if logistic_cell.owner.player.name == player.name then
            entity.minable = true
            return
        end

        entity.minable = false
    end
end

Event.add(defines.events.on_selected_entity_changed, preserve_bot)
