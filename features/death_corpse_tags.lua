local Event = require 'utils.event'
local CorpseUtil = require 'features.corpse_util'

local Public = {}

local function player_died(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)

    if not player or not player.valid then
        return
    end

    local pos = player.physical_position
    local entities = player.physical_surface.find_entities_filtered {
        area = {{pos.x - 0.5, pos.y - 0.5}, {pos.x + 0.5, pos.y + 0.5}},
        name = 'character-corpse'
    }

    local tick = game.tick
    local entity
    for _, e in ipairs(entities) do
        if e.character_corpse_player_index == event.player_index and e.character_corpse_tick_of_death == tick then
            entity = e
            break
        end
    end

    if not entity or not entity.valid then
        return
    end

    local inv_corpse = entity.get_inventory(defines.inventory.character_corpse)
    if not inv_corpse or not inv_corpse.valid then
        return
    end

    if inv_corpse.is_empty() then
        entity.destroy()
        player.print({'death_corpse_tags.empty_corpse'})
        return
    end

    local text = player.name .. "'s corpse"
    local position = entity.position
    local tag = player.force.add_chart_tag(player.surface, {
        icon = {type = 'item', name = 'power-armor-mk2'},
        position = position,
        text = text
    })

    if not tag then
        return
    end

    CorpseUtil.add_tag(tag, player_index, tick, true)
end

Event.add(defines.events.on_player_died, player_died)

Public._player_died = player_died

return Public
