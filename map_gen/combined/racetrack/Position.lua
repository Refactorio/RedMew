--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 16.11.2018 20:26 via IntelliJ IDEA
-- Many thanks to Linaori and the Diggy scenario for inspiring me coding like this
-- Also many thanks to Valansch and grilledham showing me how to use RedMew framework
-- And, of course, greetings to the whole RedMew community. It´s a pleasure <3
--

--local Debug = require'map_gen.Diggy.Debug'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local insert = table.insert
local Command = require 'utils.command'

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'
local MapData = GameConfig.track
local PlayerCar = require 'map_gen.combined.racetrack.PlayerCar'
local Player = require 'map_gen.combined.racetrack.Player'
local GameData = require 'map_gen.combined.racetrack.GameData'

local Position = {}

local checkpoint_timetable = {}


--[[
-- LAYOUT of checkpoint_timetable
    checkpoint_timetable[checkpoint_id][player_id]['time']          in ticks
    checkpoint_timetable[checkpoint_id][player_id]['passed']        true/false after the checkpoint was passed
    checkpoint_timetable[checkpoint_id][player_id]['round']         which round the player is currently driving
 ]]


-- magic GLOBAL register for this module
Global.register({
    checkpoint_timetable = checkpoint_timetable
}, function(tbl)
    checkpoint_timetable = tbl.checkpoint_timetable
end)


-- new EVENTs by this module
Position.events = {
    on_checkpoint_passed = script.generate_event_name(),        -- one checkpoint was passed
    on_finish_passed = script.generate_event_name(),            -- the finish was passed
    on_player_ends = script.generate_event_name(),              -- player passed the finish x times -> end of race
    on_game_ends = script.generate_event_name()                 -- when last player passed finish
}


-- local FUNCTIONs
local function parse_checkpoints(checkpoints, type)
    local result = {}

    for _, data in pairs(checkpoints) do
        if data.type == type then
            insert(result, data)
        end
    end

    return result
end

local function reset_passed_checkpoint_timetable(player)
    -- after finished is passed and round > 1 this function is called to set the 'passed' attribute of all checkpoints in checkpoint_timetable to false
    local player_id = player.name

    local all_checkp = MapData.checkpoints
    for _, checkpoint in ipairs(all_checkp) do
        checkpoint_timetable[checkpoint.id][player_id]['passed'] = false
    end
end

local function reset_checkpoint_timetable(player)
    -- set all data in checkpoint_timetable to default values
    -- called if:
    --      game ends
    --      player created

    local player_id = player.name

    -- initialize the checkpoint timetable for the player and all checkpoints and set time to 0, passed to false and round to 1
    local all_checkp = MapData.checkpoints
    for _, checkpoint in ipairs(all_checkp) do
        local checkpoint_id = checkpoint.id
        local data = {
            time = 0,
            passed = false
        }
        local check_point = checkpoint_timetable[checkpoint_id]
        if check_point then
            check_point[player_id] = data
        else
            data[player_id] = {
                time = 0,
                passed = false
            }
            checkpoint_timetable[checkpoint_id] = data
        end
    end
end

local function delete_player_from_checkpoint_timetable(player)
    -- called wehen player left the game --> delete the player of the checkpoint_timetable

    local all_checkp = MapData.checkpoints
    local count_checkp = #all_checkp
    local player_id = player.name

    -- most performant version isnt table.remove, just set the dataset to nil is most performant
    for i = 1, count_checkp  do
        local checkpoint_id = all_checkp[i].id
        checkpoint_timetable[checkpoint_id][player_id] = nil
    end

    Debug.print('Position::delete_player_from_checkpoint_timetable: deleted player with ID ' .. player_id .. ' from checkpoint_timetable')
end
-- ---------------------------------------------------------------------------------------------------------------------


-- GUI stuff
local function apply_heading_style(style, width)
    style.font = 'default-bold'
    style.width = width
end

local function redraw_extended_title(data, player)
    local player_id = player.name

    data.frame.caption = 'Round ' .. Player.get_value(player, 'rounds') .. ' / ' .. GameConfig.rounds
    local heading = data.heading

    local all_checkpoints = parse_checkpoints(MapData.checkpoints, 'checkpoint')
    local column_count = #all_checkpoints + 3       -- offset '3' for columns: player, round, finish

    local heading_table = heading.add({type = 'table', column_count = column_count})
    apply_heading_style(heading_table.add({type = 'label', name = 'Racetrack.Position.Extended.Frame.Heading.Player', caption = 'Player'}).style, 150)

    apply_heading_style(heading_table.add({type = 'label', name = 'Racetrack.Position.Extended.Frame.Heading.Round', caption = 'Round'}).style, 50)

    for _, checkp in ipairs(all_checkpoints) do
        apply_heading_style(heading_table.add({type = 'label', name = 'Racetrack.Position.Extended.Frame.Heading.Checkpoint' .. checkp.id, caption = checkp.name}).style, 100)
    end

    apply_heading_style(heading_table.add({type = 'label', name = 'Racetrack.Position.Extended.Frame.Heading.Finish', caption = 'Finish'}).style, 50)
end

local function redraw_extended_table(data, player)
    for _, p in ipairs(game.connected_players) do
        local list = data.list
        local player_id = p.name

        local all_checkpoints = parse_checkpoints(MapData.checkpoints, 'checkpoint')
        local column_count = #all_checkpoints + 3       -- offset '3' for columns: player, round, finish

        local list_table = list.add{type = 'table', column_count = column_count }

        list_table.style.horizontal_spacing = 16

        local tag_player = list_table.add {type = 'label', name = 'Racetrack.Position.Extended.Frame.List.Player', caption = p.name}
        tag_player.style.minimal_width = 150

        local tag_round = list_table.add {type = 'label', name = 'Racetrack.Position.Extended.Frame.List.Round', caption = Player.get_value(p, 'rounds')}
        tag_round.style.minimal_width = 50

        for _, checkp in ipairs(all_checkpoints) do
            --local time = checkpoint_timetable[checkp.id][player_id]['time'] - player_data[player_id]['start']
            -- TODO improve checkpoint time calculation, its triggered when player ends game
            local tag_position = list_table.add {type = 'label', name = 'Racetrack.Position.Extended.Frame.List.Checkpoint' .. checkp.id, caption = checkpoint_timetable[checkp.id][player_id]['time']}
            tag_position.style.minimal_width = 100
        end

        local tag_finish = list_table.add {type = 'label', name = 'Racetrack.Position.Extended.Frame.List.Finish', caption = checkpoint_timetable[1][p.name]['time']}
        tag_finish.style.minimal_width = 50
    end
end

local function extended_score(data)
    local player = data.player

    local frame = player.gui.left['Racetrack.Position.Extended.Frame']

    if (frame) then
        Gui.destroy(frame)
        return
    end

    frame = player.gui.left.add({name = 'Racetrack.Position.Extended.Frame', type = 'frame', direction = 'vertical'})

    local heading = frame.add({type = 'flow', direction = 'horizontal'})
    local list = frame.add({type = 'flow', direction = 'vertical'})

    frame.add({ type = 'button', name = 'Racetrack.Position.Button', caption = 'Close'})

    local data = {
        frame = frame,
        heading = heading,
        list = list
    }

    redraw_extended_title(data, player)
    redraw_extended_table(data, player)

    Gui.set_data(frame, data)
end

Gui.on_click('Racetrack.Position.Button', extended_score)

function Position.update_gui()
    for _, player in ipairs(game.connected_players) do
        local extended_score_frame = player.gui.left['Racetrack.Position.Extended.Frame']

        if extended_score_frame and extended_score_frame.valid then
            local data = {player = player}
            extended_score(data)
            extended_score(data)
        end
    end
end

Command.add(
    'finish-game',
    {
        description = 'Finish the game immediately',
        admin_only = true,
        allowed_by_server = true
    },
    function()
        script.raise_event(
            Position.events.on_game_ends, {player = game.player}
        )
    end
)
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTs
local function on_player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    -- add GUI button
    player.gui.top.add({
        name = 'Racetrack.Position.Button',
        type = 'sprite-button',
        sprite = 'entity/car',
    })
end

local function on_player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    reset_checkpoint_timetable(player)
    Position.update_gui()
end

local function on_player_left(event)
    -- called when player left the game -> delete player from checkpoint_timetable
    local player = Game.get_player_by_index(event.player_index)
    delete_player_from_checkpoint_timetable(player)

    -- due to timing modell at this time game_data[driving_players] is already 0, we decreased game_data[driving_players] in Player.lua::player_left function
    if GameData.get_value('driving_players') == 0 then
        Debug.print('Position::on_player_left: No more players driving -> raise event on_game_ends')
        script.raise_event(
            Position.events.on_game_ends,
            {player = player}
        )
    end

    Position.update_gui()
end

local function on_checkpoint_passed(event)
    -- called when a player passes a checkpoint

    local checkpoint = event.checkpoint
    local player = event.player

    local checkpoint_type = checkpoint.type
    local checkpoint_id = checkpoint.id
    local player_id = player.name
    local overwrite = false

    -- the first checkpoint is passed == false, we need to overwrite this
    local all_checkpoints = parse_checkpoints(MapData.checkpoints, 'checkpoint')
    if all_checkpoints[1].id == checkpoint_id then
        overwrite = true
    end

    if (checkpoint_timetable[checkpoint_id-1][player_id]['passed'] and checkpoint_type == 'checkpoint' and checkpoint_timetable[checkpoint_id][player_id]['passed'] == false) or (overwrite and checkpoint_timetable[checkpoint_id][player_id]['passed'] == false) then

        checkpoint_timetable[checkpoint_id][player_id]['time'] = event.tick
        checkpoint_timetable[checkpoint_id][player_id]['passed'] = true

        Debug.print('Position::on_checkpoint_passed: Player ' .. player_id .. ' passed ' .. checkpoint.name .. ' with ID ' .. checkpoint_id .. ' after ' .. event.tick .. ' ticks')

        player.print('You passed ' .. checkpoint.name .. ' after ' .. event.tick .. ' ticks')

        Position.update_gui()
    else
        -- TODO: maybe put a message the player is driving in wrong direction?
        --Debug.print('on_checkpoint_passed: something went wrong/wrong direction?')
    end
end

local function on_finish_passed(event)
    -- called when a player passes the finish line

    local checkpoint = event.checkpoint
    local player = event.player

    local checkpoint_type = checkpoint.type
    local checkpoint_id = checkpoint.id
    local player_id = player.name

    -- get last checkpoint id
    local all_checkpoints = MapData.checkpoints
    local count_all_checkpoints = #all_checkpoints
    local last_checkpoint_id = all_checkpoints[count_all_checkpoints].id

    if (checkpoint_timetable[last_checkpoint_id][player_id]['passed'] and checkpoint_type == 'finish' and checkpoint_timetable[checkpoint_id][player_id]['passed'] == false) then
        checkpoint_timetable[checkpoint_id][player_id]['time'] = event.tick
        checkpoint_timetable[checkpoint_id][player_id]['passed'] = true

        if Player.get_value(player, 'rounds') >= GameConfig.rounds then
            -- game ends
            script.raise_event(
                Position.events.on_player_ends,
                {player = player, checkpoint_id = checkpoint_id}
            )

            Position.update_gui()
        else
            -- next round
            local rounds = Player.get_value(player, 'rounds')
            Player.set_value(player, 'rounds', rounds + 1)

            reset_passed_checkpoint_timetable(player)
            Debug.print('Position::on_finish_passed: Player ' .. player_id .. ' passed ' .. checkpoint.name .. ' with ID ' .. checkpoint_id .. ' after ' .. event.tick .. ' ticks')

            player.print('You passed ' .. checkpoint.name .. ' after ' .. event.tick .. ' ticks')

            Position.update_gui()
        end
    end
end

local function player_ends_game(event)
    -- called when a player passes the finish line after X rounds (GameConfig)

    local player = event.player
    local player_id = player.name
    local checkpoint_id = event.checkpoint_id

    -- set finished to true and driving_state to waiting
    Player.set_value(player, 'finished', true)

    -- calculate overall time for player
    local finish_time = checkpoint_timetable[checkpoint_id][player_id]['time']
    Player.set_value(player, 'gend', finish_time)
    local start_time = Player.get_value(player, 'start')
    local overall_time = finish_time - start_time

    -- show popup               TODO: show/collect more information
    local message_1 = "Hi, it's me again, Niki L.. You successfully finished the race. Congratulations.\n"
    local message_2 = 'I collected some information for you:\n\n'
    local message_3 = 'Overall time: ' .. overall_time .. ' ticks which is about ~' .. math.round(overall_time / 60, 3) .. ' seconds.\n'
    local message_4 = 'Finished rounds: ' .. Player.get_value(player, 'rounds') .. '\n'
    local message_5 = 'Collected coins: ' .. Player.get_value(player, 'collected_coins') .. '\n'
    local message = message_1 .. message_2 .. message_3 .. message_4 .. message_5
    require 'features.gui.popup'.player(player, message)

    -- remove players car and teleport player to playground
    PlayerCar.transfer_body_to_character(player)

    -- decrease game_data[driving_players] by 1
    -- IMPORTANT NOTE: decreasing "driving_players" is done via Player::driving_state_changed
    -- because the driving state changed event is always called and so we will decrease it 2 times

    if GameData.get_value('driving_players') < 1 and GameData.get_value('started') then
        -- game was started and last player reached the finish ---> game end
        script.raise_event(
            Position.events.on_game_ends, {player = event.player}
        )
    end

    Position.update_gui()
end

local function spill_items(data)
    local stack = {name = 'coin', count = data.count}
    data.surface.spill_item_stack(data.position, stack, true)
end

local function game_end(event)
    -- called when last player passed the finish line after X rounds (GameConfig) or no more players alive/connected
    local last_player = event.player

    Debug.print('Position::game_end: event called by last player: ' .. last_player.name)

    -- set started to false, finished to true and restart to true
    GameData.set_value('started', false)
    GameData.set_value('finished', true)
    GameData.set_value('restart', true)
    GameData.set_value('driving_players', 0)

    -- reset countdown
    GameData.set_value('countdown_act', GameConfig.time_to_start)
    GameData.set_value('countdown_start_tick', 0)


    -- reset player depending data
    local players = game.connected_players
    for _, player in ipairs(players) do
        -- reset checkpoint_timetable for player
        reset_checkpoint_timetable(player)

        -- reset player_data; just resetting, dont delete the player!
        Player.reset_player_data(player)
    end

    -- clear track, remove all coins and entities build by players
    local protected_entity_types = {'player', 'simple-entity'}
    for _, entity in pairs(last_player.surface.find_entities_filtered{type = protected_entity_types, invert = true}) do
        entity.destroy()
    end

    -- place new random coins on track (which consists of tiles_to_find)
    local tiles_to_find = {'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7', 'dry-dirt',
        'grass-1', 'grass-2', 'grass-3', 'grass-4', 'lab-dark-1', 'lab-dark-2', 'lab-white',
        'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3', 'sand-1', 'sand-2', 'sand-3'
    }

    -- calculate BoundingBox area of map to use find_tiles_filtered in
    local half_width = MapData.width / 2
    local half_height = MapData.height / 2
    local top_left = {-(half_width - math.abs(MapData.spawn.x)), -(half_height + math.abs(MapData.spawn.y)) }
    local bottom_right = {(half_width - math.abs(MapData.spawn.x)) + half_width, (half_height - math.abs(MapData.spawn.y))}

    local all_tiles = last_player.surface.find_tiles_filtered{area = {top_left, bottom_right}, name = tiles_to_find}  --13.830 tiles
    local count_tiles = #all_tiles

    for i = 1, count_tiles do
        local random = math.random(0, 100)
        local count = 100 - GameConfig.coin_chance
        if random > count then
            spill_items({count = 1, surface = last_player.surface, position = all_tiles[i].position})
        end
    end

    Position.update_gui()
end
-- ---------------------------------------------------------------------------------------------------------------------


-- POSITION handling
local function check_player_position(event)

    if GameData.get_value('started') then

        -- when no more players driving, call game end
        if GameData.get_value('driving_players') < 1 then
            local players = game.connected_players
            script.raise_event(
                Position.events.on_game_ends, {player = players[1]}
            )
        end

        -- create table with players whos driving_state is 'driving'
        local driving_players = {}
        for _, player in pairs(game.connected_players) do
            if Player.get_value(player, 'driving_state') == 'driving' then
                insert(driving_players, player)
            end
        end

        for _, driver in pairs(driving_players) do

            -- checkpoints check and message
            local checkp = MapData.checkpoints
            local count_checkp = #checkp

            for i = 1, count_checkp do

                if checkp[i].comp_op_x == '>=' and checkp[i].comp_op_y == '<=' then         -- S to E
                    if driver.position.x >= checkp[i].offset_x+checkp[i].check_x and driver.position.y <= checkp[i].offset_y+checkp[i].check_y  then
                        if checkp[i].type == 'checkpoint' then
                            script.raise_event(
                                Position.events.on_checkpoint_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                        if checkp[i].type == 'finish' then
                            script.raise_event(
                                Position.events.on_finish_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                    end
                end

                if checkp[i].comp_op_x == '<=' and checkp[i].comp_op_y == '<=' then         -- E to N
                    if driver.position.x <= checkp[i].offset_x+checkp[i].check_x and driver.position.y <= checkp[i].offset_y+checkp[i].check_y  then
                        if checkp[i].type == 'checkpoint' then
                            script.raise_event(
                                Position.events.on_checkpoint_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                        if checkp[i].type == 'finish' then
                            script.raise_event(
                                Position.events.on_finish_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                    end
                end

                if checkp[i].comp_op_x == '<=' and checkp[i].comp_op_y == '>=' then         -- N to W
                    if driver.position.x <= checkp[i].offset_x+checkp[i].check_x and driver.position.y >= checkp[i].offset_y+checkp[i].check_y  then
                        if checkp[i].type == 'checkpoint' then
                            script.raise_event(
                                Position.events.on_checkpoint_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                        if checkp[i].type == 'finish' then
                            script.raise_event(
                                Position.events.on_finish_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                    end
                end

                if checkp[i].comp_op_x == '>=' and checkp[i].comp_op_y == '>=' then         -- W to S
                    if driver.position.x >= checkp[i].offset_x+checkp[i].check_x and driver.position.y >= checkp[i].offset_y+checkp[i].check_y  then
                        if checkp[i].type == 'checkpoint' then
                            script.raise_event(
                                Position.events.on_checkpoint_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                        if checkp[i].type == 'finish' then
                            script.raise_event(
                                Position.events.on_finish_passed,
                                {checkpoint = checkp[i], player = driver }
                            )
                        end
                    end
                end

                -- prevent changing zoom level when players are driving
                if Player.get_value(driver, 'driving_state') == 'driving' and Player.get_value(driver, 'finished') == false then
                    driver.zoom = GameConfig.player_zoom
                end
            end
        end
    end
end

function Position.register(config)
    Event.add(defines.events.on_player_created, on_player_created)      --> only create GUI button with car icon
    Event.add(defines.events.on_player_joined_game, on_player_joined)
    Event.add(defines.events.on_player_left_game, on_player_left)
    --Event.add(defines.events.on_player_driving_changed_state, on_player_driving_state_changed)
    Event.add(Position.events.on_checkpoint_passed, on_checkpoint_passed)
    Event.add(Position.events.on_finish_passed, on_finish_passed)
    Event.add(Position.events.on_player_ends, player_ends_game)
    Event.add(Position.events.on_game_ends, game_end)
    Event.on_nth_tick(10, check_player_position)            -- every 0.1 seconds



    --[[Event.add(defines.events.on_chunk_generated, function (event)
        local checkp = MapData.checkpoints
        local count_checkp = #checkp

        for i = 1, count_checkp do
            for x = checkp[i].offset_x, checkp[i].offset_x + checkp[i].check_x do
                for y = checkp[i].offset_y, checkp[i].offset_y + checkp[i].check_y do
                    Debug.print_grid_value('X', event.surface, {x = x, y = y}, nil, nil, true)
                end
            end
        end
    end)]]
end

return Position
