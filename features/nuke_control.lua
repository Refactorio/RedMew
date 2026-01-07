local Event = require 'utils.event'
local Rank = require 'features.rank_system'
local Utils = require 'utils.core'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Report = require 'features.report'
local Popup = require 'features.gui.popup'
local Ranks = require 'resources.ranks'

local format = string.format

-- capsule antigreif player entities threshold.
local capsule_bomb_threshold = 8

local players_warned = {}
local entities_allowed_to_bomb = {
    ['stone-wall'] = true,
    ['transport-belt'] = true,
    ['fast-transport-belt'] = true,
    ['express-transport-belt'] = true,
    ['construction-robot'] = true,
    ['character'] = true,
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
    ['distractor'] = true,
    ['artillery-flare'] = true,
    ['poison-cloud'] = true,
    ['poison-cloud-visual-dummy'] = true
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
    local player = game.get_player(event.player_index)
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

local function is_allowed_deconstruction_planner(cursor_stack)
    if not cursor_stack or not cursor_stack.valid or not cursor_stack.valid_for_read then
        return false
    end

    if cursor_stack.tile_selection_mode ~= defines.deconstruction_item.tile_selection_mode.never then
        return false
    end

    local filters = cursor_stack.entity_filters
    if #filters ~= 1 or filters[1] ~= 'big-rock' then
        return false
    end

    return true
end

local function on_player_deconstructed_area(event)
    local player = game.get_player(event.player_index)
    if is_trusted(player) then
        return
    end

    -- Added to allow guests to use the decon planner as a targetting remote for crash site air strike or barrage commands
    -- see crash_site.features.deconstruction_targetting.lua
    if is_allowed_deconstruction_planner(player.cursor_stack) then
        return
    end

    --Make them think they arent noticed
    Utils.silent_action_warning(
        '[Deconstruct]',
        player.name .. ' tried to deconstruct something, but instead deconstructed themself.',
        player
    )
    player.print(
        'Only regulars can mark things for deconstruction, if you want to deconstruct something you may ask an admin to promote you.'
    )

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
        Utils.print_admins(
            'Warning! ' .. player.name .. ' just tried to deconstruct ' .. tostring(#entities) .. ' entities!',
            nil
        )
    end
    for _, entity in pairs(entities) do
        if entity.valid and entity.to_be_deconstructed(game.get_player(event.player_index).force) then
            entity.cancel_deconstruction(game.get_player(event.player_index).force)
        end
    end
end

local function item_not_sanctioned(item)
    local name = item.name
    if name:find('capsule') or name == 'cliff-explosives' or name == 'discharge-defense-remote' or name:find('medpack') then
        return true
    end

    local capsule_action = item.capsule_action
    if capsule_action and capsule_action.type == 'use-on-self' then
        return true
    end

    return false
end

local function entity_allowed_to_bomb(entity_name)
    return entities_allowed_to_bomb[entity_name]
end

local function list_damaged_entities(item_name, entities)
    local set = {}
    for i = 1, #entities do
        local e = entities[i]
        local name = e.name

        if name ~= item_name then
            local count = set[name]
            if count then
                set[name] = count + 1
            else
                set[name] = 1
            end
        end
    end

    local list = {}
    local i = 1
    for k, v in pairs(set) do
        list[i] = k
        i = i + 1
        list[i] = '('
        i = i + 1
        list[i] = v
        i = i + 1
        list[i] = ')'
        i = i + 1
        list[i] = ', '
        i = i + 1
    end
    list[i - 1] = nil

    return table.concat(list)
end

local function on_capsule_used(event)
    local item = event.item
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    if item.name == 'artillery-targeting-remote' then
        Game.create_local_flying_text {
            surface = player.surface,
            text = player.name,
            color = player.color,
            position = event.position
        }
    end

    local nuke_control = storage.config.nuke_control
    if not nuke_control.enable_autokick and not nuke_control.enable_autoban then
        return
    end

    if is_trusted(player) or item_not_sanctioned(item) then
        return
    end

    local position = event.position
    local x, y = position.x, position.y
    local surface = player.surface

    if surface.count_entities_filtered({force = 'enemy', area = {{x - 10, y - 10}, {x + 10, y + 10}}, limit = 1}) > 0 then
        return
    end

    local count = 0
    local entities =
        player.surface.find_entities_filtered {force = player.force, area = {{x - 5, y - 5}, {x + 5, y + 5}}}

    local item_name = item.name
    for i = 1, #entities do
        local e = entities[i]
        local entity_name = e.name
        if entity_name ~= item_name and not entity_allowed_to_bomb(entity_name) then
            count = count + 1
        end
    end

    if count <= capsule_bomb_threshold then
        return
    end

    if players_warned[event.player_index] then
        if nuke_control.enable_autoban then
            local reason = format(
                'Damaged entities: %s with %s. This action was performed automatically. If you want to contest this ban please visit refactorio.de/discord',
                list_damaged_entities(item_name, entities),
                item_name
            )
            Report.ban_player(player, reason)
        end
    else
        players_warned[event.player_index] = true
        if nuke_control.enable_autokick then
            local reason = format('Damaged entities: %s with %s -Antigrief', list_damaged_entities(item_name, entities), item_name)
            Report.kick_player(player, reason)
        end
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
                    Report.jail(player, '<script>')
                    Report.report(nil, player, player.name .. ' used a train to destroy another train and has been jailed.')
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
Event.add(defines.events.on_player_deconstructed_area, on_player_deconstructed_area)
Event.add(defines.events.on_player_used_capsule, on_capsule_used)
Event.add(defines.events.on_entity_died, on_entity_died)
