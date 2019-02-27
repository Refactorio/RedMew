local Event = require 'utils.event'
local Rank = require 'features.rank_system'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Server = require 'features.server'
local Report = require 'features.report'
local Popup = require 'features.gui.popup'
local Ranks = require 'resources.ranks'

local format = string.format
local match = string.match

local players_warned = {}
local entities_allowed_to_bomb = {
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
}

Global.register(
    {
        players_warned = players_warned,
        entities_allowed_to_bomb = entities_allowed_to_bomb
    },
    function(tbl)
        players_warned = tbl.players_warned
        entities_allowed_to_bomb = tbl.entities_allowed_to_bomb
    end
)

local function is_trusted(player)
    return Rank.equal_or_greater_than(player.name, Ranks.auto_trusted)
end

local function ammo_changed(event)
    local player = Game.get_player_by_index(event.player_index)
    if is_trusted(player) then
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
    if is_trusted(player) then
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

    if not is_trusted(player) then
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

local train_to_manual =
    Token.register(
    function(train)
        if train.valid then
            train.manual_mode = true
        end
    end
)

local function on_entity_died(event)
    -- We only care if a train is killed by a member of its own force
    local entity = event.entity
    if (not entity or not entity.valid) or not entity.train or (event.force ~= entity.force) then
        return
    end
    -- Check that an entity did the killing
    local cause = event.cause
    if not cause or not cause.valid then
        return
    end
    -- Check that the entity was a train and in manual
    local train = cause.train
    if not train or not train.manual_mode then
        return
    end
    -- Check if the train has passengers
    local passengers = train.passengers
    local num_passengers = #passengers
    if num_passengers == 0 then
        train.manual_mode = false -- if the train is in manual and has no passengers, stop it
        Task.set_timeout_in_ticks(30, train_to_manual, train)
        return
    end

    -- Go through the passengers and punish any guests involved
    local player_punished
    local player_unpunished
    local name_list = {}
    for i = 1, num_passengers do
        local player = passengers[i]
        if player.valid then
            if is_trusted(player) then
                player_unpunished = true
                name_list[#name_list + 1] = player.name
            else
                -- If they aren't allowed to nuke, stop the train and act accordingly.
                player_punished = true
                name_list[#name_list + 1] = player.name
                player.driving = false
                train.manual_mode = false
                Task.set_timeout_in_ticks(30, train_to_manual, train)
                if players_warned[player.index] and num_passengers == 1 then -- jail for later offenses if they're solely guilty
                    Report.jail(player)
                    Utils.print_admins({'nuke_control.train_jailing', player.name})
                else -- warn for first offense or if there's someone else in the train
                    players_warned[player.index] = true
                    Utils.print_admins({'nuke_control.train_warning', player.name})
                    Popup.player(player, {'nuke_control.train_player_warning'})
                end
            end
        end
    end

    -- If there was a passenger who was unpunished along with a punished passenger, let the admins know
    if player_punished and player_unpunished then
        local name_string = table.concat(name_list, ', ')
        Utils.print_admins({'nuke_control.multiple_passengers', num_passengers, name_string})
    end
end

Event.add(defines.events.on_player_ammo_inventory_changed, ammo_changed)
Event.add(defines.events.on_player_joined_game, on_player_joined)
Event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
Event.add(defines.events.on_player_used_capsule, on_capsule_used)
Event.add(defines.events.on_entity_died, on_entity_died)
