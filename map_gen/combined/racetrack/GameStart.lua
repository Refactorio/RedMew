--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 27.11.2018 16:11 via IntelliJ IDEA
--

local Event = require 'utils.event'
local Game = require 'utils.game'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local Command = require 'utils.command'

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'
local MapData = GameConfig.track
local PlayerCar = require 'map_gen.combined.racetrack.PlayerCar'
local Player = require 'map_gen.combined.racetrack.Player'
local GameData = require 'map_gen.combined.racetrack.GameData'
local Position = require 'map_gen.combined.racetrack.Position'

local GameStart = {}

local countdown = {}

local game_start_info = [[
Hello, my name is Niki L. and I am happy to see you here! I am sure you will have a good time
and much fun.
Can you see the countdown? When the counter reaches 0, you will transferred into your car and
the game starts immediately. But take care to drive into the correct direction. Sometimes
the guys of your team are a bit drunken and they will set your car into the wrong direction.
The correct direction for this track is counterclockwise!
One more private tip: Keep your cursor on your car while driving to collect as much coins as
possible.
So, take a deep breath, stretch yourself one last time and then get ready for the match!
    ]]

local game_running_info = [[
There is currently a game running. Please stand by until the game is finished.
    ]]


-- new EVENTs by this module
GameStart.events = {
    on_countdown_finished = script.generate_event_name()
}
-- ---------------------------------------------------------------------------------------------------------------------


-- FUNCTIONs
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

    apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info', caption = data.caption.msg}).style, 150)

    -- only show countdown when game is not running
    if data.caption.type == 'starting' then
        -- shows players left for start
        if count_players < GameConfig.players_to_start then
            apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info1', caption = count_players .. ' player(s) online. ' .. players_left .. ' player(s) left. Waiting for players to join the game.' }).style, 150)
        else
            apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info1', caption = count_players .. ' player(s) online. Waiting until countdown is finished.'}).style, 150)
        end
        -- shows countdown
        if count_players < GameConfig.players_to_start then
            apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Countdown', caption = 'Countdown starts when ' .. GameConfig.players_to_start .. ' players are online.' }).style, 150, 'default-semibold')
        else
            apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Countdown', caption = 'Countdown: ' .. GameData.get_value('countdown_act') .. ' s / ' .. GameConfig.time_to_start .. ' s' }).style, 150, 'default-semibold')
        end
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info2', caption = 'After the countdown has finished you will be automatically teleported into your car.' }).style, 150)
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info3', caption = 'This window will close automatically.' }).style, 150)
    else
        -- show how many players are on track for new connected players/players who finished already game
        apply_list_style(list.add({type = 'label', name = 'Racetrack.GameStart.Countdown.Frame.List.Info1', caption = GameData.get_value('driving_players') .. ' player(s) found on the track. Take your time to get a drink.'}).style, 150)
    end
end

local function infoscreen(event, caption)

    local player = event.player
    local left = player.gui.left
    local frame = left['Racetrack.GameStart.Countdown.Frame']

    if (frame and event.trigger == '') then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_heading(data, player)
        redraw_content(data, player)
        return
    end

    frame = left.add({name = 'Racetrack.GameStart.Countdown.Frame', type = 'frame', direction = 'vertical'})

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

function GameStart.update_gui(trigger, caption)
    for _, player in ipairs(game.connected_players) do
        local data = {player = player, trigger = trigger}
        infoscreen(data, caption)
    end
end

Command.add(
    'start-game',
    {
        description = 'Start the game immediately',
        admin_only = true,
        allowed_by_server = true
    },
    function()
        script.raise_event(
            GameStart.events.on_countdown_finished, {}
        )
    end
)
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTs
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('GameStart::player_joined: event called by player: ' .. player.name)

    -- initilaize Player global data
    Player.reset_player_data(player)

    -- clear players inventory
    if player.character ~= nil then
        player.character.clear_items_inside()
    end

    -- when new player connects and game isnt startet/restarted reset the countdown to the value from config
    -- also show a message for a new connected player that a game is currently running
    if GameData.get_value('finished') or GameData.get_value('restart') then
        GameData.set_value('countdown_act', GameConfig.time_to_start)

        local data = {player = player, trigger = 'update_gui'}
        infoscreen(data, {msg = game_start_info, type = 'starting'})
    else
        local data = {player = player, trigger = 'update_gui'}
        infoscreen(data, {msg = game_running_info, type = 'running'})
    end

    --always give me admin rank
    if player.name == 'der-dave.com' then
        player.admin = true
    end
end

local function check_minimum_players_reached(event)
    -- called every 60 ticks!

    Debug.print('GameStart::check_minimum_players_reached: event called')

    local players = game.connected_players

    -- check game start condition
    if GameData.get_value('started') == false and GameData.get_value('driving_players') == 0 or GameData.get_value('restart') then
        local count_players = #players
        if count_players >= GameConfig.players_to_start and GameData.get_value('countdown_act') > 0 then
            -- decrease countdown by 1
            local countdown = GameData.get_value('countdown_act')
            countdown = countdown - 1
            GameData.set_value('countdown_act', countdown)
        end

        -- update the GUI (the info frame)
        for _, player in pairs(players) do
            local data = {player = player, trigger = 'update_gui'}
            infoscreen(data, {msg = game_start_info, type = 'starting'})
        end

        -- countdown reached 0 -> raise the event
        if GameData.get_value('countdown_act') == 0 and GameData.get_value('countdown_start_tick') == 0 then
            Debug.print('GameStart::check_minimum_players_reached: raised on_countdown_finished event')

            script.raise_event(
                GameStart.events.on_countdown_finished, {}
            )
        end
    end
end

local function on_countdown_finished(event)
    -- save the ticks after countdown was reached
    GameData.set_value('countdown_start_tick', event.tick)

    -- teleport all players into their cars
    local players = game.connected_players
    local count_players = #players
    for _, player in pairs(players) do

        -- transfer player to finish line
        PlayerCar.transfer_body_to_car(player, {MapData.checkpoints[1].offset_x, MapData.checkpoints[1].offset_y})

        -- set zoom level
        player.zoom = GameConfig.player_zoom

        -- set player_data start time, driving _state and finished
        Player.set_value(player, 'start', event.tick)
        Player.set_value(player, 'driving_state', 'driving')
        Player.set_value(player, 'finished', false)

        -- close infoscreen
        local data = {player = player, trigger = ''}        -- by emptying "trigger" attribute we destroy the infoscreen
        infoscreen(data, {msg = game_start_info, type = 'starting'})

        Debug.print('GameStart::on_countdown_finished: transferred ' .. count_players .. ' player into their cars')
    end

    -- set game data
    GameData.set_value('started', true)
    GameData.set_value('restart', false)
    GameData.set_value('finished', false)

    -- store number of players transferred to track
    GameData.set_value('driving_players', count_players)
end

local function spill_items(data)
    local stack = {name = 'coin', count = data.count}
    data.surface.spill_item_stack(data.position, stack, true)
end

local function chunk_generated(event)
    local area = event.area
    local surface = event.surface

    local tiles_to_find = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7', 'dry-dirt',
        'grass-1', 'grass-2', 'grass-3', 'grass-4', 'lab-dark-1', 'lab-dark-2', 'lab-white',
        'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3', 'sand-1', 'sand-2', 'sand-3'
    }

    local all_tiles = surface.find_tiles_filtered{area = area, name = tiles_to_find}
    local count_tiles = #all_tiles

    for i = 1, count_tiles do
        local random = math.random(0, 100)
        local count = 100 - GameConfig.coin_chance
        if random > count then
            spill_items({count = 1, surface = surface, position = all_tiles[i].position})
        end
    end
end

local function destroy_gui()
    local players = game.connected_players

    for _, player in pairs(players) do
        local data = {player = player, trigger = ''}        -- by emptying "trigger" attribute we destroy the infoscreen
        infoscreen(data, {msg = game_start_info, type = 'starting'})
    end

end
-- ---------------------------------------------------------------------------------------------------------------------

function GameStart.register(config)
    Event.add(defines.events.on_player_joined_game, player_joined)
    Event.add(GameStart.events.on_countdown_finished, on_countdown_finished)
    Event.on_nth_tick(60, check_minimum_players_reached)    -- every 1 second
    Event.add(defines.events.on_chunk_generated, chunk_generated)
    Event.add(Position.events.on_game_ends, destroy_gui)

    -- initialize game_data
    GameData.reset_game_data()

    -- initialize countdown
    countdown['act'] = GameConfig.time_to_start
    countdown['start_tick'] = 0
end

return GameStart
