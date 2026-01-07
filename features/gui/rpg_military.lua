local Command = require 'utils.command'
local Color = require 'resources.color_presets'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Ranks = require 'resources.ranks'
local Table = require 'utils.table'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Toast = require 'features.gui.toast'

local math_min = math.min
local math_max = math.max
local math_ceil = math.ceil
local math_floor = math.floor

local Manager = {}
local Interface = {}

-- LOCAL VARIABLES ============================================================

local auras = {}
local records = {}
local regens = {}
local regens_map = {}
local update_map = {}
local xp_data = {
    pool_count = 0,
}

Global.register({
    auras = auras,
    records = records,
    regens = regens,
    regens_map = regens_map,
    update_map = update_map,
    xp_data = xp_data,
}, function(tbl)
    auras = tbl.auras
    records = tbl.records
    regens = tbl.regens
    regens_map = tbl.regens_map
    update_map = tbl.update_map
    xp_data = tbl.xp_data
end)

local XP_BY_ACTION = {
    -- entity name -> xp
    ['small-biter']          = { value =   1, count =  15000 },
    ['small-spitter']        = { value =   1, count =   3000 },
    ['medium-biter']         = { value =   3, count =   5000 },
    ['medium-spitter']       = { value =   3, count =   3500 },
    ['big-biter']            = { value =   6, count =   8500 },
    ['big-spitter']          = { value =   6, count =   8500 },
    ['behemoth-biter']       = { value =  12, count =  22000 },
    ['behemoth-spitter']     = { value =  12, count =  22000 },
    ['small-worm-turret']    = { value =   5, count =   3500 },
    ['big-worm-turret']      = { value =   8, count =   7000 },
    ['medium-worm-turret']   = { value =  12, count =  12000 },
    ['behemoth-worm-turret'] = { value =  15, count =   7000 },
    ['biter-spawner']        = { value =  25, count =   1200 },
    ['spitter-spawner']      = { value =  25, count =   1200 },
    ['destroyer']            = { value =   1, count = 100000 },
    ['defender']             = { value =   1, count = 100000 },
    ['distractor']           = { value =   1, count =      0 },
    ['gun-turret']           = { value =  15, count =   7000 },
    ['flamethrower-turret']  = { value =  18, count =   2000 },
    ['laser-turret']         = { value =  12, count =  10000 },
    ['artillery-turret']     = { value =  25, count =    100 },
    ['outpost-upgrade']      = { value = 100, count =     25 }, -- custom
    ['outpost-capture']      = { value = 100, count =    100 }, -- custom
}

-- Share 20% of XP gained with other players
local XP_PUBLIC_SHARE = 0.2
local XP_PRIVATE_SHARE = 1 - XP_PUBLIC_SHARE

-- Level XP formula: fast early, slower later.
local MAX_LEVEL = 50

-- XP required to go from level L to L+1
local LEVEL_XP = {}

for lvl = 1, MAX_LEVEL - 1 do
    if lvl < 5 then
        LEVEL_XP[lvl] = 25 * lvl
    elseif lvl < 15 then
        LEVEL_XP[lvl] = 50 * lvl
    elseif lvl < 30 then
        LEVEL_XP[lvl] = 100 * (lvl - 10)
    elseif lvl < 40 then
        LEVEL_XP[lvl] = 200 * (lvl - 20)
    else
        LEVEL_XP[lvl] = 400 * (lvl - 30)
    end
end

-- Tier thresholds and names
local TIERS = {
    [1]  = 'Scavenger',
    [3]  = 'Survivor',
    [5]  = 'Militiaman',
    [7]  = 'Corporal',
    [9]  = 'Sergeant',
    [11] = 'Veteran',
    [13] = 'Lieutenant',
    [15] = 'Captain',
    [18] = 'Major',
    [20] = 'Commander',
    [23] = 'Colonel',
    [25] = 'Warlord',
    [28] = 'Liberator',
    [30] = 'General',
    [33] = 'Field Marshal',
    [35] = 'Champion',
    [38] = 'High Marshal',
    [40] = 'Planetary Commander',
    [45] = 'Paragon',
    [50] = 'Eternal Marshal',
}

local get_or_create_record = function(player_index)
    local record = records[player_index]
    if not record then
        record = {
            xp = 0,
            level = 1,
            rank = TIERS[1],
            buffs = {},
            bonuses = {
                character_crafting_speed_modifier = 0,
                character_inventory_slots_bonus = 0,
                character_health_bonus = 0,
                character_mining_speed_modifier = 0,
                character_build_distance_bonus = 0,
                character_reach_distance_bonus = 0,
                character_resource_reach_distance_bonus = 0,
                character_running_speed_modifier = 0,
            },
        }
        records[player_index] = record
    end
    return record
end

local SMALL_BUFFS = {
    aura      = { desc = 'Toughness [color=173,255,47]+%.1f%%[/color]',      value =   0.01, multiplier = 100 },
    crafting  = { desc = 'Crafting speed [color=173,255,47]+%.0f%%[/color]', value =   0.20, multiplier = 100 },
    inventory = { desc = 'Inventory [color=173,255,47]+%d[/color] slot',     value =   5   , multiplier =   1 },
    max_hp    = { desc = 'Max HP [color=173,255,47]+%d[/color]',             value =  50   , multiplier =   1 },
    mining    = { desc = 'Mining speed [color=173,255,47]+%.0f%%[/color]',   value =   0.50, multiplier = 100 },
    reach     = { desc = 'Reach [color=173,255,47]+%d[/color] tile',         value =   1   , multiplier =   1 },
    regen     = { desc = 'HP regen [color=173,255,47]+%.2f/s[/color]',       value =   0.20, multiplier =   1 },
    speed     = { desc = 'Running speed [color=173,255,47]+%.0f%%[/color]',  value =   0.10, multiplier = 100 },
}

local SMALL_BUFFS_LIST = Table.keys(SMALL_BUFFS)

local SMALL_BUFFS_ACTION = {
    ['aura'] = function(player, value)
        auras[player.index] = (auras[player.index] or 0) + value
    end,
    ['crafting'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_crafting_speed_modifier = bonuses.character_crafting_speed_modifier + value
        player.character_crafting_speed_modifier = bonuses.character_crafting_speed_modifier
    end,
    ['inventory'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_inventory_slots_bonus = bonuses.character_inventory_slots_bonus + value
        player.character_inventory_slots_bonus = bonuses.character_inventory_slots_bonus
    end,
    ['max_hp'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_health_bonus = bonuses.character_health_bonus + value
        player.character_health_bonus = bonuses.character_health_bonus
    end,
    ['mining'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_mining_speed_modifier = bonuses.character_mining_speed_modifier + value
        player.character_mining_speed_modifier = bonuses.character_mining_speed_modifier
    end,
    ['reach'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_build_distance_bonus = bonuses.character_build_distance_bonus + value
        bonuses.character_reach_distance_bonus = bonuses.character_reach_distance_bonus + value
        bonuses.character_resource_reach_distance_bonus = bonuses.character_resource_reach_distance_bonus + value
        player.character_build_distance_bonus = bonuses.character_build_distance_bonus
        player.character_reach_distance_bonus = bonuses.character_reach_distance_bonus
        player.character_resource_reach_distance_bonus = bonuses.character_resource_reach_distance_bonus
    end,
    ['regen'] = function(player, value)
        regens[player.index] = (regens[player.index] or 0) + value
    end,
    ['speed'] = function(player, value)
        local bonuses = get_or_create_record(player.index).bonuses
        bonuses.character_running_speed_modifier = bonuses.character_running_speed_modifier + value
        player.character_running_speed_modifier = bonuses.character_running_speed_modifier
    end,
}

local STATS_MAP = {
    character_crafting_speed_modifier = 'crafting',
    character_inventory_slots_bonus = 'inventory',
    character_health_bonus = 'max_hp',
    character_mining_speed_modifier = 'mining',
    character_reach_distance_bonus = 'reach',
    character_running_speed_modifier = 'speed',
}

-- Big buffs awarded at tier unlocks
local BIG_BUFFS = {
    [5]  = { type = 'speed',     value = 0.15 },
    [10] = { type = 'inventory', value = 20   },
    [15] = { type = 'max_hp',    value = 50   },
    [20] = { type = 'reach',     value = 1    },
    [25] = { type = 'regen',     value = 0.5  },
    [30] = { type = 'aura',      value = 0.05 },
    [35] = { type = 'speed',     value = 0.25 },
    [40] = { type = 'max_hp',    value = 100  },
    [45] = { type = 'reach',     value = 1    },
    [50] = { type = 'aura',      value = 0.25 },
}

local FX = {
    aura = function(player, amount)
        local character = player.character
        if not (character and character.valid) then
            return
        end
        if character.get_health_ratio() == 1 then
            return
        end
        character.health = character.health + amount
        if amount < 0.5 then
            return
        end
        player.create_local_flying_text{
            text = ('+[color=pink]%d[/color] [img=virtual-signal.signal-sun]'):format(math_ceil(amount)),
            position = { x = character.position.x, y = character.position.y - 1.4 },
            surface = character.surface,
            time_to_live = 60,
            speed = 1,
        }
    end,
    regen = function(player, amount)
        local character = player.character
        if not (character and character.valid) then
            return
        end
        if character.get_health_ratio() == 1 then
            regens_map[player.index] = nil
            return
        end
        character.health = character.health + amount
        if amount < 0.5 then
            return
        end
        player.create_local_flying_text{
            text = ('+[color=blue]%d[/color] [img=virtual-signal.signal-heart]'):format(math_ceil(amount)),
            position = { x = character.position.x, y = character.position.y - 1.8 },
            surface = character.surface,
            time_to_live = 120,
            speed = 2,
        }
    end,
    xp = function(player, amount)
        local record = get_or_create_record(player.index)
        record.xp = record.xp + amount
        if amount < 1 then
            return
        end
        update_map[player.index] = true
        local character = player.character
        if not (character and character.valid) then
            return
        end
        player.create_local_flying_text{
            text = ('+[color=green]%d[/color] [img=virtual-signal.signal-star]'):format(amount),
            position = { x = character.position.x, y = character.position.y - 1.0 },
            surface = character.surface,
            time_to_live = 80,
            speed = 1.5,
        }
    end,
}

local cause_by_type = {
    ['character'] = function(cause)
        return cause.player
    end,
    ['car'] = function(cause)
        local d = cause.get_driver()
        if d then
            return (d.object_name == 'LuaEntity') and d.player or d
        else
            return cause.last_user
        end
    end,
    ['spider-vehicle'] = function(cause)
        local d = cause.get_driver()
        if d then
            return (d.object_name == 'LuaEntity') and d.player or d
        else
            return cause.last_user
        end
    end,
    ['combat-robot'] = function(cause)
        return cause.last_user
    end,
    ['land-mine'] = function(cause)
        return cause.last_user
    end,
}

-- MANAGER ====================================================================

Manager.compute_stats = function()
    local enemy_xp = 0
    for _, v in pairs(XP_BY_ACTION) do
        enemy_xp = enemy_xp + (v.count * v.value)
    end

    local player_xp = 0
    for _, v in pairs(LEVEL_XP) do
        player_xp = player_xp + v
    end

    return ('Available XP: %d | Player XP: %d | Players feeded: %.2f'):format(enemy_xp, player_xp, (enemy_xp / player_xp))
end

Manager.award_xp = function(player, award)
    local xp = 0
    if type(award) == 'string' then
        xp = SMALL_BUFFS[award] and SMALL_BUFFS[award].value or nil
    elseif type(award) == 'number' then
        xp = math_floor(award)
    end
    if not (xp and type(xp) == 'number' and xp > 0) then
        return
    end

    xp_data.pool_count = xp_data.pool_count + XP_PUBLIC_SHARE * xp
    FX.xp(player, xp * XP_PRIVATE_SHARE)
end

Manager.pick_random_buff = function()
    return SMALL_BUFFS_LIST[math.random(#SMALL_BUFFS_LIST)]
end

Manager.apply_buff = function(player, buff_id, value)
    local action = SMALL_BUFFS_ACTION[buff_id]
    if not action then
        return
    end

    action(player, value)
    local msg = string.format(SMALL_BUFFS[buff_id].desc, value * SMALL_BUFFS[buff_id].multiplier)
    Toast.toast_player(player, 8, msg)

    local buffs = get_or_create_record(player.index).buffs
    buffs[#buffs + 1] = ('[font=default-small-semibold]L[color=128,204,240]%d[/color] -[/font] %s'):format(get_or_create_record(player.index).level, msg)
end

Manager.check_player_level = function(player)
    local record = get_or_create_record(player.index)
    if record.level < MAX_LEVEL and record.xp >= LEVEL_XP[record.level] then
        Manager.on_player_level_up(player)
        return true
    end
    return false
end

Manager.on_player_level_up = function(player)
    local record = get_or_create_record(player.index)
    if record.level == MAX_LEVEL then
        return
    end
    record.xp = math_max(0, record.xp - LEVEL_XP[record.level])

    record.level = record.level + 1
    local rank = TIERS[record.level]
    if rank then
        record.rank = rank
        Toast.toast_player(player, 12, 'Your new rank is: '..rank)
    else
        Toast.toast_player(player, 12, 'Level up!')
    end

    local id = Manager.pick_random_buff()
    Manager.apply_buff(player, id, SMALL_BUFFS[id].value)

    local perk = BIG_BUFFS[record.level]
    if perk then
        Manager.apply_buff(player, perk.type, perk.value)
    end
end

Manager.shield_with_aura = function(player_index, amount)
    local player = game.get_player(player_index)
    if not (player and player.valid) then
        return
    end

    if not amount or amount <= 0 then
        return
    end

    FX.aura(player, amount)
end

Manager.shield_with_aura_token = Token.register(function(params)
    Manager.shield_with_aura(params.player_index, params.amount)
end)

Manager.restore_health = function(player_index, amount)
    local player = game.get_player(player_index)
    if not (player and player.valid) then
        return
    end

    if not amount or amount <= 0 then
        return
    end

    FX.regen(player, amount)
end

Manager.pretty_player_stats = function(player)
    local player_index = player.index
    local record = get_or_create_record(player_index)
    local bonuses = record.bonuses
    local stats = {
        '[font=default-bold]' .. player.name .. '\' stats:[/font]',
        string.format('Rank: [color=orange]%s[/color]', record.rank),
        string.format('Level: [color=purple]%d / %d[/color]', record.level, MAX_LEVEL),
        string.format('XPs: [color=purple]%d / %s[/color]', record.xp, tostring(LEVEL_XP[record.level] or 'inf')),
        string.format(SMALL_BUFFS.aura.desc, (auras[player_index] or 0) * SMALL_BUFFS.aura.multiplier),
        string.format(SMALL_BUFFS.regen.desc, (regens[player_index] or 0) * SMALL_BUFFS.regen.multiplier),
    }
    for k, v in pairs(bonuses) do
        local id = STATS_MAP[k]
        if id then
            stats[#stats + 1] = string.format(SMALL_BUFFS[id].desc, v * SMALL_BUFFS[id].multiplier)
        end
    end
    return table.concat(stats, '\n')
end

Manager.reset_character_bonuses = function(player)
    if not player and player.valid then
        return
    end
    for k, v in pairs(get_or_create_record(player.index).bonuses) do
        player[k] = v
    end
end

Event.add(defines.events.on_entity_damaged, function(event)
    local entity = event.entity
    if not (entity.valid and entity.type == 'character') then
        return
    end

    local player_index = entity.player and entity.player.index
    if not player_index or event.final_damage_amount == 0 then
        return
    end

    if auras[player_index] then
        Task.set_timeout_in_ticks(1, Manager.shield_with_aura_token, {
            player_index = player_index,
            amount = event.final_damage_amount * math_min(1.0, auras[player_index])
        })
    end

    if regens[player_index] then
        regens_map[player_index] = true
    end
end)

Event.add(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity.valid and entity.force and entity.force.name == 'enemy') then
        return
    end

    local xp = XP_BY_ACTION[entity.name]
    if not xp then
        return
    end

    local cause = event.cause
    if not (cause and cause.valid and cause.force and cause.force.name == 'player') then
        return
    end

    local handler = cause_by_type[cause.type]
    local actor = handler and handler(cause)
    if not (actor and actor.valid) then
        return
    end

    Manager.award_xp(actor, xp.value)
end)

Event.add(defines.events.on_player_respawned, function(event)
    Manager.reset_character_bonuses(game.get_player(event.player_index))
end)

-- == USER INTERFACE ==========================================================

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

Event.add(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    local data = {}

    local frame = Gui.add_left_element(player, {
        type = 'frame',
        name = main_frame_name,
        direction = 'horizontal'
    })

    data.level = frame.add {
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'utility/empty_armor_slot',
        number = 1,
        style = 'frame_button'
    }
    Gui.set_style(data.level, { size = 48 })
    Gui.set_data(data.level, data)

    data.content = frame.add { type = 'flow', direction = 'vertical' }
    local content = data.content
    Gui.set_style(content, { natural_width = 180, maximal_width = 200 })

    data.rank = content.add { type = 'label', caption = 'Rank: ', style = 'tooltip_heading_label_category' }
    data.progress = content.add { type = 'progressbar', style = 'production_progressbar', value = 0 }
    Gui.set_style(data.progress, { natural_width = 198 })

    local regen = content.add { type = 'flow', direction = 'horizontal' }
    regen.add { type = 'label', style = 'semibold_caption_label', caption = 'Regen: ', tooltip = 'Health regeneration /s'}
    regen.add { type = 'label', caption = '---'}
    data.regen = regen

    local aura = content.add { type = 'flow', direction = 'horizontal' }
    aura.add { type = 'label', style = 'semibold_caption_label', caption = 'Aura: ', tooltip = 'Increased armor toughness %' }
    aura.add { type = 'label', caption = '---'}
    data.aura = aura

    local buffs = content.add { type = 'flow', direction = 'vertical' }
    buffs.add { type = 'label', style = 'semibold_caption_label', caption = 'Perks:' }
    local listbox = buffs.add { type = 'list-box', items = {} }
    Gui.set_style(listbox, { maximal_height = 90, maximal_width = 200 })
    data.buffs = buffs

    Gui.set_data(frame, data)
    Interface.update(player)
end)

Interface.toggle_main_button = function(event)
    local content = Gui.get_data(event.element).content
    content.visible = not content.visible
    Interface.update(event.player)
end

Interface.update = function(player)
    local record = get_or_create_record(player.index)
    local data = Gui.get_data(Gui.get_left_element(player, main_frame_name))
    data.level.number = record.level

    if not data.content.visible then
        if record.level < MAX_LEVEL then
            data.level.tooltip = ('[color=yellow]Rank[/color]: %s\n[color=green]XP[/color]: %d / %d for next level'):format(record.rank, record.xp, LEVEL_XP[record.level])
        else
            data.level.tooltip = ('[color=yellow]Rank[/color]: %s'):format(record.rank)
        end
        return
    else
        data.level.tooltip = nil
    end

    data.rank.caption = '[color=255,230,191]Rank:[/color] '..record.rank

    if record.level < MAX_LEVEL then
        data.progress.value = math_min(1, record.xp / LEVEL_XP[record.level])
        data.progress.tooltip = ('[color=green]XP[/color]: %d / %d for next level'):format(record.xp, LEVEL_XP[record.level])
    else
        data.progress.visible = false
    end

    local regen = regens[player.index]
    if not regen then
        data.regen.visible = false
    else
        data.regen.visible = true
        data.regen.children[2].caption = ('%.2f /s [img=virtual-signal.signal-heart]'):format(regen)
    end

    local aura = auras[player.index]
    if not aura then
        data.aura.visible = false
    else
        data.aura.visible = true
        data.aura.children[2].caption = ('+%.1f %% [img=virtual-signal.signal-sun]'):format(aura * 100)
    end

    local buffs = record.buffs
    if #buffs > 0 then
        data.buffs.visible = true
        local listbox = data.buffs.children[2]
        if #listbox.items ~= #buffs then
            listbox.items = buffs
            listbox.scroll_to_item(#buffs)
        end
    else
        data.buffs.visible = false
    end
end

Event.add(defines.events.on_tick, function()
    -- Handle Health restoration every 1sec
    if game.tick % 60 == 0 then
        for player_index in pairs(regens_map) do
            Manager.restore_health(player_index, regens[player_index])
        end
    end

    -- Distribute XP pool every 3min
    if game.tick % 10800 == 0 then
        local online_players = {}
        for _, player in pairs(game.connected_players) do
            -- Only consider players active at least 60% of the time
            if player.afk_time < 4320 then
                online_players[#online_players + 1] = player
            end
        end
        if #online_players > 0 then
            local player_share = xp_data.pool_count / #online_players
            xp_data.pool_count = 0
            for _, player in pairs(online_players) do
                FX.xp(player, player_share)
            end
        end
    end

    -- Check for levelups every 5sec
    if game.tick % 300 == 0 then
        for player_index in pairs(update_map) do
            local player = game.get_player(player_index)
            if player and player.valid then
                Manager.check_player_level(player)
                Interface.update(player)
            end
            update_map[player_index] = nil
        end
    end
end)

Gui.on_click(main_button_name, Interface.toggle_main_button)

-- ============================================================================

Command.add(
    'rpg-level-up',
    {
        description = '+1 RPG Level',
        allowed_by_server = false,
        log_command = false,
        debug_only = true,
        cheat_only = true,
    },
    function()
        Manager.on_player_level_up(game.player)
        Interface.update(game.player)
    end
)

Command.add(
    'rpg-level-up-all',
    {
        description = 'Sets RPG level to Max',
        allowed_by_server = false,
        log_command = false,
        debug_only = true,
        cheat_only = true,
    },
    function()
        for _ = 1, MAX_LEVEL do
            Manager.on_player_level_up(game.player)
        end
        Interface.update(game.player)
    end
)

Command.add(
    'rpg-stats',
    {
        description = {'command_description.rpg_stats'},
        allowed_by_server = false,
        log_command = false,
        arguments = { 'player' },
        default_values = { player = '' },
    },
    function(args, player)
        local target = (args.player and game.get_player(args.player)) or player
        player.print(Manager.pretty_player_stats(target))
    end
)

Command.add(
    'rpg-update',
    {
        description = {'command_description.rpg_update'},
        allowed_by_server = true,
        log_command = true,
        required_rank = Ranks.moderator,
        arguments = { 'player' },
        default_values = { player = '' },
    },
    function(args, player)
        local target = (args.player and game.get_player(args.player)) or player
        if target and target.valid then
            Game.player_print('Updating RPG module for ' .. target.name, Color.success, player)
            Manager.check_player_level(player)
            Manager.reset_character_bonuses(player)
            Interface.update(player)
        else
            Game.player_print('Invalid player name ' .. target.name, Color.fail, player)
        end
    end
)

Command.add(
    'rpg-leaderboard',
    {
        description = {'command_description.rpg_leaderboard'},
        allowed_by_server = true,
        log_command = false,
    },
    function(_, player)
        local scores = {}
        for player_index, record in pairs(records) do
            local p = game.get_player(player_index)
            table.insert(scores, { level = record.level, name = p.name })
        end
        table.sort(scores, function(a, b) return a.level > b.level end)

        local lines = { '[font=default-bold]RPG Leaderboard:[/font]' }
        for i, entry in ipairs(scores) do
            table.insert(lines, string.format('%d. (L%d) [color=orange]%s[/color]', i, entry.level, entry.name))
        end

        Game.player_print(table.concat(lines, '\n'), nil, player)
    end

)

return {
    manager = Manager,
    interface = Interface
}
