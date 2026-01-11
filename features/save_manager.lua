local Event = require 'utils.event'
local config = require 'config'.save_manager

local DEFAULT_INACTIVE_INTERVAL = 60 * 60 * 60 * 24 * 30 -- a month

local function remove_player_data(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    game.print({ 'save_manager.remove_player', player.name })
    game.remove_offline_players({ player.index })
end

Event.add(defines.events.on_player_banned, remove_player_data)

Event.on_nth_tick(config.inactive_interval or DEFAULT_INACTIVE_INTERVAL, function()
    local idx_to_remove = {}
    local deadline = game.tick - (config.inactive_interval or DEFAULT_INACTIVE_INTERVAL)

    for index, player in pairs(game.players) do
        if player.last_online < deadline then
            table.insert(idx_to_remove, index)
        end
    end

    if #idx_to_remove > 0 then
        game.print({ 'save_manager.cleanup', #idx_to_remove })
        game.remove_offline_players(idx_to_remove)
    end
end)
