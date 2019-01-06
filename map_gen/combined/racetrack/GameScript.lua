--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 16.11.2018 20:22 via IntelliJ IDEA
-- Many thanks to Linaori and the Diggy scenario for inspiring me coding like this
-- Also many thanks to Valansch and grilledham showing me how to use RedMew framework
-- And, of course, greetings to the whole RedMew community. It´s a pleasure <3
--

local ScenarioInfo = require 'features.gui.info'
local Event = require 'utils.event'

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'

local GameScript = {}

function GameScript.register(debug)

    local GameStart = require 'map_gen.combined.racetrack.GameStart'
    GameStart.register(GameConfig)
    if ('function' == type(GameStart.on_init)) then
        Event.on_init(GameStart.on_init)
    end

    local GameData = require 'map_gen.combined.racetrack.GameData'
    GameData.register(GameConfig)
    if ('function' == type(GameData.on_init)) then
        Event.on_init(GameData.on_init)
    end

    local Player = require 'map_gen.combined.racetrack.Player'
    Player.register(GameConfig)
    if ('function' == type(Player.on_init)) then
        Event.on_init(Player.on_init)
    end

    local PlayerCar = require 'map_gen.combined.racetrack.PlayerCar'
    PlayerCar.register(GameConfig)
    if ('function' == type(PlayerCar.on_init)) then
        Event.on_init(PlayerCar.on_init)
    end

    local Position = require 'map_gen.combined.racetrack.Position'
    Position.register(GameConfig)
    if ('function' == type(Position.on_init)) then
        Event.on_init(Position.on_init)
    end

    local Item = require 'map_gen.combined.racetrack.Item'
    Item.register(GameConfig)
    if ('function' == type(Item.on_init)) then
        Event.on_init(Item.on_init)
    end

    ScenarioInfo.set_map_name('Racetrack')
    ScenarioInfo.set_map_description('Play against others like in Mario Kart!')
    ScenarioInfo.set_map_extra_info('- Collect coins to to get entities.\n- Place entities to disturb other players.\n- Be the first who reaches the finish.')
end

return GameScript
