--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 04.12.2018 19:05 via IntelliJ IDEA
--
-- Handles everything depending to game and gamestate
--

local Event = require 'utils.event'
local Global = require 'utils.global'
local Game = require 'utils.game'

local GameData = {}

local game_data = {}

-- magic GLOBAL register for this module
Global.register({
    game_data = game_data
}, function(tbl)
    game_data = tbl.game_data
end)


-- FUNCTIONs
function GameData.reset_game_data()
    -- set default values for game_data
    game_data['started'] = false
    game_data['finished'] = false
    game_data['restart'] = true
    game_data['driving_players'] = 0
end

function GameData.set_value(atrribute, value)
    -- set a attribute of game_data with value
    game_data[atrribute] = value
end

function GameData.get_value(atrribute)
    -- set a attribute of game_data with value
    return game_data[atrribute]
end
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTs
local function player_left(event)
    -- IMPORTANT NOTE: decreasing "driving_players" is done via Player.lua::player_left - decreasing just done when player left while "driving_state" = "driving"
end

local function driving_state_changed(event)
    -- IMPORTANT NOTE: decreasing "driving_players" is done via Player.lua::driving_state_changed - decreasing just done when player left vehicle (= player died) while "driving_state" = "driving"
end
-- ---------------------------------------------------------------------------------------------------------------------


function GameData.register(config)
    Event.add(defines.events.on_player_left_game, player_left)
    Event.add(defines.events.on_player_driving_changed_state, driving_state_changed)
end

return GameData