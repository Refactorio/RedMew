local Color = require 'resources.color_presets'
local table = require 'utils.table'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Info = require 'features.gui.info'
local pairs = pairs

local get_random_weighted = table.get_random_weighted

local Public = {}

function Public.show_start_up(player)
    local config = storage.config.player_create
    local p = player.print
    for _, message in pairs(config.join_messages) do
        p(message)
    end

    local random_messages = config.random_join_message_set
    if #random_messages > 0 then
        p(get_random_weighted(random_messages))
    end

    if config.show_info_at_start and not _DEBUG then
        if Info ~= nil then
            Info.show_info(player)
        end
    end

    if _DEBUG and game.is_multiplayer() then
        game.print('THIS MULTIPLAYER MAP IS IN DEBUG!!!', {color = Color.warning})
    elseif _DEBUG then
        game.print("DON'T LAUNCH THIS MAP! DEBUG MODE IS ENABLED!!!", {color = Color.warning})
    elseif not _DEBUG and not game.is_multiplayer() then
        player.print('To change your name in single-player, open chat and type the following /c game.player.name = "your_name"', {color = Color.info})
    end
end

local function player_created(event)
    local config = storage.config.player_create
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    if not config.cutscene then
        Public.show_start_up(player)
    end

    local character = player.character
    if not character or not character.valid then
        return
    end

    local player_insert = player.insert

    for _, item in pairs(config.starting_items) do
        if prototypes.item[item.name] then
            player_insert(item)
        end
    end
end

Event.add(defines.events.on_player_created, player_created)

if _CHEATS then
    local memory = {
        forces_initialized = {
            player = false -- default force for everyone
        }
    }

    Global.register(
        {
            memory = memory
        },
        function(tbl)
            memory = tbl.memory
        end
    )

    local function player_created_cheat_mode(event)
        local config = storage.config.player_create
        local player = game.get_player(event.player_index)

        if not player or not player.valid then
            return
        end

        local force = player.force

        player.cheat_mode = true
        local cheats = config.cheats

        if not memory.forces_initialized[force.name] then
            force.manual_mining_speed_modifier = cheats.manual_mining_speed_modifier
            force.character_inventory_slots_bonus = cheats.character_inventory_slots_bonus
            force.character_running_speed_modifier = cheats.character_running_speed_modifier
            force.character_health_bonus = cheats.character_health_bonus
        end

        memory.forces_initialized[force.name] = true

        local character = player.character
        if not character or not character.valid then
            return
        end

        local player_insert = player.insert

        if cheats.start_with_power_armor then
            player_insert({name = 'power-armor-mk2', count = 1})
            local armor_put = player.get_inventory(5)[1].grid.put
            armor_put({name = 'fission-reactor-equipment'})
            armor_put({name = 'fission-reactor-equipment'})
            armor_put({name = 'fission-reactor-equipment'})
            armor_put({name = 'fission-reactor-equipment'})
            armor_put({name = 'personal-roboport-mk2-equipment'})
            armor_put({name = 'personal-roboport-mk2-equipment'})
            armor_put({name = 'personal-laser-defense-equipment'})
            armor_put({name = 'personal-laser-defense-equipment'})
            armor_put({name = 'energy-shield-mk2-equipment'})
            armor_put({name = 'energy-shield-mk2-equipment'})
            armor_put({name = 'night-vision-equipment'})
            armor_put({name = 'battery-mk2-equipment'})
            armor_put({name = 'battery-mk2-equipment'})
            armor_put({name = 'battery-mk2-equipment'})
            armor_put({name = 'belt-immunity-equipment'})
            armor_put({name = 'solar-panel-equipment'})
        end
        for _, item in pairs(cheats.starting_items) do
            player_insert(item)
        end
    end

    Event.add(defines.events.on_player_created, player_created_cheat_mode)
end

return Public
