local Event = require 'utils.event'
local Rank = require 'features.rank_system'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local format = string.format
local match = string.match

local function allowed_to_nuke(player)
    return Rank.equal_or_greater_than(player.name, Ranks.auto_trusted)
end

local function ammo_changed(event)
    local player = Game.get_player_by_index(event.player_index)
    if allowed_to_nuke(player) then
        return
    end
    local nukes = player.remove_item({name = 'atomic-bomb', count = 1000})
    if nukes > 0 then
        Utils.action_warning('[Nuke]', player.name .. ' tried to use a nuke, but instead dropped it on his foot.')

        local character = player.character
        if character and character.valid then
            for _, p in ipairs(game.connected_players) do
                if p ~= player then
                    p.add_custom_alert(character, {type = 'item', name = 'atomic-bomb'}, player.name, true)
                end
            end
        end
        player.character.health = 0
    end
end

local function on_player_deconstructed_area(event)
    local player = Game.get_player_by_index(event.player_index)
    if allowed_to_nuke(player) then
        return
    end
    player.remove_item({name = 'deconstruction-planner', count = 1000})

    --Make them think they arent noticed
    Utils.silent_action_warning('[Deconstruct]', player.name .. ' tried to deconstruct something, but instead deconstructed themself.', player)
    player.print('Only regulars can mark things for deconstruction, if you want to deconstruct something you may ask an admin to promote you.')

    local character = player.character
    if character and character.valid then
        for _, p in ipairs(game.connected_players) do
            if p ~= player then
                p.add_custom_alert(character, {type = 'item', name = 'deconstruction-planner'}, player.name, true)
            end
        end
    end
    character.health = 0

    local area = event.area
    local left_top, right_bottom = area.left_top, area.right_bottom
    if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
        return
    end

    local entities = player.surface.find_entities_filtered {area = area, force = player.force}
    if #entities > 1000 then
        Utils.print_admins('Warning! ' .. player.name .. ' just tried to deconstruct ' .. tostring(#entities) .. ' entities!', nil)
    end
    for _, entity in pairs(entities) do
        if entity.valid and entity.to_be_deconstructed(Game.get_player_by_index(event.player_index).force) then
            entity.cancel_deconstruction(Game.get_player_by_index(event.player_index).force)
        end
    end
end

local function item_not_sanctioned(item)
    local name = item.name
    return (name:find('capsule') or name == 'cliff-explosives' or name == 'raw-fish' or name == 'discharge-defense-remote')
end

global.nuke_control = {
    entities_allowed_to_bomb = {
        ['stone-wall'] = true,
        ['transport-belt'] = true,
        ['fast-transport-belt'] = true,
        ['express-transport-belt'] = true,
        ['construction-robot'] = true,
        ['player'] = true,
        ['gun-turret'] = true,
        ['laser-turret'] = true,
        ['flamethrower-turret'] = true,
        ['rail'] = true,
        ['rail-chain-signal'] = true,
        ['rail-signal'] = true,
        ['tile-ghost'] = true,
        ['entity-ghost'] = true,
        ['gate'] = true,
        ['electric-pole'] = true,
        ['small-electric-pole'] = true,
        ['medium-electric-pole'] = true,
        ['big-electric-pole'] = true,
        ['logistic-robot'] = true,
        ['defender'] = true,
        ['destroyer'] = true,
        ['distractor'] = true
    },
    players_warned = {}
}
local entities_allowed_to_bomb = global.nuke_control.entities_allowed_to_bomb
local players_warned = global.nuke_control.players_warned

local function entity_allowed_to_bomb(entity)
    return entities_allowed_to_bomb[entity.name]
end

local function on_capsule_used(event)
    local item = event.item
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    if item.name == 'artillery-targeting-remote' then
        player.surface.create_entity {
            name = 'flying-text',
            text = player.name,
            color = player.color,
            position = event.position
        }
    end

    local nuke_control = global.config.nuke_control
    if not nuke_control.enable_autokick and not nuke_control.enable_autoban then
        return
    end

    if item_not_sanctioned(item) then
        return
    end

    if not allowed_to_nuke(player) then
        local area = {{event.position.x - 5, event.position.y - 5}, {event.position.x + 5, event.position.y + 5}}
        local count = 0
        local entities = player.surface.find_entities_filtered {force = player.force, area = area}
        for _, e in pairs(entities) do
            if not entity_allowed_to_bomb(e) then
                count = count + 1
            end
        end
        if count > 8 then
            if players_warned[event.player_index] then
                if nuke_control.enable_autoban then
                    Server.ban_sync(player.name, format('Damaged %i entities with %s. This action was performed automatically. If you want to contest this ban please visit redmew.com/discord.', count, item.name), '<script>')
                end
            else
                players_warned[event.player_index] = true
                if nuke_control.enable_autokick then
                    game.kick_player(player, format('Damaged %i entities with %s -Antigrief', count, item.name))
                end
            end
        end
    end
end

local function on_player_joined(event)
    local player = game.players[event.player_index]
    if match(player.name, '^[Ili1|]+$') then
        Server.ban_sync(player.name, '', '<script>') --No reason given, to not give them any hints to change their name
    end
end

Event.add(defines.events.on_player_ammo_inventory_changed, ammo_changed)
Event.add(defines.events.on_player_joined_game, on_player_joined)
Event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
--Event.add(defines.events.on_player_mined_entity, on_player_mined_item)
Event.add(defines.events.on_player_used_capsule, on_capsule_used)
