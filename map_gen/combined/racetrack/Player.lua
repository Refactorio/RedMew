--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 04.12.2018 17:13 via IntelliJ IDEA
--
-- Handles everything depending to the Player
--

local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'

local GameData = require 'map_gen.combined.racetrack.GameData'
local PlayerCar = require 'map_gen.combined.racetrack.PlayerCar'

local Player = {}

local player_data = {}

-- magic GLOBAL register for this module
Global.register({
    player_data = player_data
}, function(tbl)
    player_data = tbl.player_data
end)

-- local FUNCTIONs

-- ---------------------------------------------------------------------------------------------------------------------


-- FUNCTIONs
function Player.reset_player_data(player)
    -- reset complete player_data to default values (joining game, game finished)
    local player_id = player.name

    local player_data_table = player_data[player_id]
    if player_data_table then
        player_data_table['start'] = 0                      -- start time in game ticks since scenario was started on server/machine
        player_data_table['gend'] = 0                       -- end time (- start)
        player_data_table['rounds'] = 1                     -- rounds completely passed (for later game modes?)
        player_data_table['finished'] = false               -- all rounds finished?
        player_data_table['collected_coins'] = 0            -- collected coins during driving (for stats)
        player_data_table['driving_state'] = 'waiting'      -- waiting = waiting in playground till start; driving = driving on track
    else
        local data = {start = 0, gend = 0, rounds = 1, finished = false, collected_coins = 0, driving_state = 'waiting'}
        player_data[player_id] = data
    end

    -- zoom reset to normal
    player.zoom = 1.0
end

function Player.delete_player_data(player)
    -- delete player from player_data (wehn leaving game)
    local player_id = player.name

    player_data[player_id] = nil
end

function Player.set_value(player, atrribute, value)
    -- set a attribute of player_data with value
    local player_id = player.name

    player_data[player_id][atrribute] = value
end

function Player.get_value(player, atrribute)
    -- set a attribute of player_data with value
    local player_id = player.name

    return player_data[player_id][atrribute]
end
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTs
local function player_left(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('Player::player_left: event called by leaving player: ' .. player.name)

    -- decrease game_data[driving_players] by one if the driving state of disconnected player was driving
    if Player.get_value(player, 'driving_state') == 'driving' then
        local driving_players = GameData.get_value('driving_players')
        GameData.set_value('driving_players', driving_players - 1)
    end

    -- now delete player from player_data
    Player.delete_player_data(player)

    -- merge the players force with the neutral force -> players force will then be destroyed
    -- https://lua-api.factorio.com/latest/LuaGameScript.html#LuaGameScript.merge_forces
    local force = player.force
    game.merge_forces(force, 'neutral')
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('Player::player_joined: event called by joining player: ' .. player.name)

    Player.reset_player_data(player)

    -- Disable the god mode spotlight.
    player.disable_flashlight()
    -- enable bigger toolbar
    player.force.technologies['toolbelt'].researched = true
    -- disable minimap
    player.game_view_settings.show_minimap = false
    -- disable research
    player.game_view_settings.show_research_info = false
    -- disable alerts
    player.game_view_settings.show_alert_gui = false
end

local function driving_state_changed(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('Player::driving_state_changed: event called by player: ' .. player.name)

    -- when a player is leaving the game the driving_state_changed event is also called; so only run the code if the player is on server
    if player_data[player.name] ~= nil then

        -- decrease game_data[driving_players] by one if the driving state of died player was driving
        if player.vehicle == nil and Player.get_value(player, 'driving_state') == 'driving' then
            local driving_players = GameData.get_value('driving_players')
            GameData.set_value('driving_players', driving_players - 1)
        end

        if player.vehicle == nil and Player.get_value(player, 'finished') == false then
            player.print('o.O    GAME OVER, ' .. player.name .. '! Your vehicle was destroyed!')
            game.print('-.-    GAME OVER for ' .. player.name .. '!')
            PlayerCar.transfer_body_to_character(player)
        end

        Player.reset_player_data(player)
    end
end
-- ---------------------------------------------------------------------------------------------------------------------


function Player.register(config)
    Event.add(defines.events.on_player_joined_game, player_joined)
    Event.add(defines.events.on_player_left_game, player_left)
    Event.add(defines.events.on_player_driving_changed_state, driving_state_changed)
end

return Player
