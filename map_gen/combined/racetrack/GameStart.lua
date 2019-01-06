--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 27.11.2018 16:11 via IntelliJ IDEA
--

local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Gui = require 'utils.gui'

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'
local MapData = require ('map_gen.combined.racetrack.tracks.' .. GameConfig.track)
local PlayerCar = require 'map_gen.combined.racetrack.PlayerCar'
local Player = require 'map_gen.combined.racetrack.Player'
local GameData = require 'map_gen.combined.racetrack.GameData'

local GameStart = {}

local countdown = {}

local game_start_info = [[
Hello, my name is Niki L. and I am happy to see you here! I am sure you will have a good time
and much fun.
Can you see the countdown? When the counter reaches 0, you will transferred into your car and
the game starts immediately. But take care to drive into the correct direction. Sometimes
the guys of your team are a bit drunken and they will set your car into the wrong direction.
The correct direction for this track is counterclockwise!
So, take a deep breath, stretch yourself one last time and then get ready for the match!
    ]]

local game_running_info = [[
There is currently a game running. Please stand by until the game is finished.
    ]]

-- magic GLOBAL register for this module
Global.register({
    countdown = countdown
}, function(tbl)
    countdown = tbl.countdown
end)


-- new EVENTs by this module
GameStart.events = {
    on_countdown_finished = script.generate_event_name()
}


-- FUNCTIONs
function GameStart.get_countdown()
    return countdown
end
-- ---------------------------------------------------------------------------------------------------------------------


-- GUI stuff
local function apply_heading_style(style, width)
    style.font = 'default-large-bold'
    style.minimal_width = width
end

local function apply_list_style(style, width, font)
    if font ~= nil then
        style.font = font
    end
    style.minimal_width = width
    style.single_line = false
end

local function redraw_heading(data, player)
    local heading = data.heading
    Gui.clear(heading)

    apply_heading_style(heading.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.Heading.Welcome', caption = 'Welcome to the track, ' .. player.name}).style, 150)
end

local function redraw_content(data, player)
    local list = data.list
    Gui.clear(list)

    local players = game.connected_players
    local count_players = #players
    local players_left = GameConfig.players_to_start - count_players

    --[[local caption = [[
Hello, my name is Niki L. and I am happy to see you here! I am sure you will have a good time
and much fun.
Can you see the countdown? When the counter reaches 0, you will transferred into your car and
the game starts immediately. But take care to drive into the correct direction. Sometimes
the guys of your team are a bit drunken and they will set your car into the wrong direction.
The correct direction for this track is counterclockwise!
So, take a deep breath, stretch yourself one last time and then get ready for the match!
    ]]

    apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info', caption = data.caption}).style, 150)

    -- shows players left for start
    if count_players < GameConfig.players_to_start then
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info1', caption = count_players .. ' player(s) online. ' .. players_left .. ' player(s) left. Waiting for players to join the game.' }).style, 150)
    else
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info1', caption = count_players .. ' player(s) online. Waiting until countdown is finished.'}).style, 150)
    end
    -- shows countdown
    if count_players < GameConfig.players_to_start then
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Countdown', caption = 'Countdown starts after ' .. GameConfig.players_to_start .. ' players are online.' }).style, 150, 'default-semibold')
    else
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Countdown', caption = 'Countdown: ' .. countdown['act'] .. ' s / ' .. GameConfig.time_to_start .. ' s' }).style, 150, 'default-semibold')
    end
    apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info2', caption = 'After the countdown has finished, you will be automatically teleported into your car.' }).style, 150)
    apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info3', caption = 'This window will close automatically.' }).style, 150)
end

local function infoscreen(event, caption)
    local player = event.player

    local frame = player.gui.left['Racetrack.GameStart.Countdown.Frame']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_content(data, player)
        return
    end

    frame = player.gui.left.add({name = 'Racetrack.GameStart.Countdown.Frame', type = 'frame', direction = 'vertical'})

    local heading = frame.add({type = 'flow', direction = 'horizontal'})

    local list = frame.add({type = 'flow', direction = 'vertical'})

    local data = {
        frame = frame,
        heading = heading,
        list = list,
        caption = caption
    }

    redraw_heading(data, player)
    redraw_content(data, player)

    Gui.set_data(frame, data)
end

function GameStart.update_gui(data, caption)
    for _, player in ipairs(game.connected_players) do
        if data == nil then
            local data = {player = player, trigger = 'update_gui'}
            infoscreen(data, caption)
        else
            infoscreen(data, caption)
        end
    end
end
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTs
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('GameStart::player_joined: event called by player: ' .. player.name)

    -- clear players inventory
    if player.character ~= nil then
        player.character.clear_items_inside()
    end

    -- after a player connects and game isnt startet/restarted reset the countdown to the value from config
    -- also show a message for a new connected player that a game is currently running
    if GameData.get_value('finished') or GameData.get_value('restart') then
        countdown['act'] = GameConfig.time_to_start

        local data = {player = player, trigger = 'update_gui'}
        GameStart.update_gui(data, game_start_info)
    else

        local data = {player = player, trigger = 'update_gui'}
        GameStart.update_gui(data, game_running_info)
    end

    -- give me admin rank
    if player.name == 'der-dave.com' then
        player.admin = true
    end
end

local function check_minimum_players_reached(event)
    -- called every 60 ticks!
    local players = game.connected_players

    -- check game start condition
    if GameData.get_value('started') == false and GameData.get_value('driving_players') == 0 or GameData.get_value('restart') then
        local count_players = #players
        if count_players >= GameConfig.players_to_start and countdown['act'] > 0 then
            -- decrease countdown by 1
            countdown['act'] = countdown['act'] - 1

            -- update the GUI (the info frame)
            local data = {player = players[1], trigger = 'update_gui'}
            GameStart.update_gui(data, game_start_info)
        end

        -- countdown reached 0 -> raise the event
        if countdown['act'] == 0 and countdown['start_tick'] == 0 then
            Debug.print('GameStart::check_minimum_players_reached: raised on_countdown_finished event')

            script.raise_event(
                GameStart.events.on_countdown_finished, {}
                )
        end
    end
end

local function on_countdown_finished(event)
    -- save the ticks after countdown was reached
    countdown['start_tick'] = event.tick

    -- teleport all players into their cars
    local players = game.connected_players
    local count_players = #players
    for _, player in ipairs(players) do
    --for i = 1, count_players do
        -- transfer player to finish line
        PlayerCar.transfer_body_to_car(player, {MapData.checkpoints[1].offset_x, MapData.checkpoints[1].offset_y})

        -- set zoom level
        player.zoom = GameConfig.player_zoom

        -- set player_data start time, driving _state and finished
        local player_id = player.name
        Player.set_value(player, 'start', event.tick)
        Player.set_value(player, 'driving_state', 'driving')
        Player.set_value(player, 'finished', false)

        -- close infoscreen
        local data = {player = player}      -- by removing "trigger" attribute we destroy the infoscreen
        infoscreen(data)

        Debug.print('GameStart::on_countdown_finished: transferred ' .. count_players .. ' player into their cars')
    end

    -- set game data
    GameData.set_value('started', true)
    GameData.set_value('restart', false)
    GameData.set_value('finished', false)

    -- store number of players transferred to track
    GameData.set_value('driving_players', count_players)
end
-- ---------------------------------------------------------------------------------------------------------------------

function GameStart.register(config)
    Event.add(defines.events.on_player_joined_game, player_joined)
    Event.add(GameStart.events.on_countdown_finished, on_countdown_finished)
    Event.on_nth_tick(60, check_minimum_players_reached)    -- every 1 second

    -- initialize game_data
    GameData.reset_game_data()

    -- initialize countdown
    countdown['act'] = GameConfig.time_to_start
    countdown['start_tick'] = 0
end

return GameStart
