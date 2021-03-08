local Event = require 'utils.event'
local Settings = require 'utils.redmew_settings'
local CorpseUtil = require 'features.corpse_util'

local Public = {}

local ping_own_death_name = 'death_corpse_tags.ping_own_death'
local ping_other_death_name = 'death_corpse_tags.ping_other_death'

Public.ping_own_death_name = ping_own_death_name
Public.ping_other_death_name = ping_other_death_name

Settings.register(ping_own_death_name, Settings.types.boolean, true, 'death_corpse_tags.ping_own_death')
Settings.register(ping_other_death_name, Settings.types.boolean, false, 'death_corpse_tags.ping_other_death')

local function player_died(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)

    if not player or not player.valid then
        return
    end

    local pos = player.position
    local entities = player.surface.find_entities_filtered {
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

    if Settings.get(player_index, ping_own_death_name) then
        player.print({
            'death_corpse_tags.own_corpse_location',
            string.format('%.1f', position.x),
            string.format('%.1f', position.y),
            player.surface.name
        })
    end

    for _, other_player in pairs(player.force.players) do
        if other_player ~= player and Settings.get(other_player.index, ping_other_death_name) then
            other_player.print({
                'death_corpse_tags.other_corpse_location',
                player.name,
                string.format('%.1f', position.x),
                string.format('%.1f', position.y),
                player.surface.name
            })
        end
    end

    CorpseUtil.add_tag(tag, player_index, tick, true)
end

Event.add(defines.events.on_player_died, player_died)

Public._player_died = player_died

return Public
