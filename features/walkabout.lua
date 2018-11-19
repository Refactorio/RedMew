local global ={}
local Task = require 'utils.Task'
local Game = require "utils.game"
local Event = require "utils.event"
local Token = require 'utils.global_token'
local Utils = require 'utils.utils'

global.walking = {}
global.walking_storage = {}

--- Returns a player from walkabout after the timeout.
-- If the player is no longer logged in, store their info
-- in the global table walking_storage
local custom_commands_return_player =
    Token.register(
    function(args)
        local player = args.player
        if not player.valid then
            return
        end
        local index = player.index
        -- If walking is false it means they got cleaned by clean_on_join
        if global.walking[index] == false then
            return
        end

        -- If the player is no longer connected, store that information.
        if player.connected then
            global.walking[index] = false

            local walkabout_character = player.character
            if walkabout_character and walkabout_character.valid then
                walkabout_character.destroy()
            end

            local character = args.character
            if character ~= nil and character.valid then
                player.character = character
            else
                player.create_character()
                player.teleport(args.position)
            end

            player.force = args.force

            game.print(args.player.name .. ' came back from his walkabout.')
        else
            local data = {index = index, character = args.character, force = args.force, position = args.position}
            table.insert(global.walking_storage, data)
        end
    end
)

--- Sends a player on a walkabout:
-- They are teleported far away, placed on a neutral force, and are given a new character.
-- They are turned after the timeout by custom_commands_return_player
local function walkabout(cmd)
    if game.player and not game.player.admin then
        Utils.cant_run(cmd.name)
        return
    end
    local params = {}
    if cmd.parameter == nil then
        Game.player_print('Walkabout failed, check /help walkabout.')
        return
    end
    for param in string.gmatch(cmd.parameter, '%S+') do
        table.insert(params, param)
    end
    local player_name = params[1]
    local duration = 60
    if #params > 2 then
        Game.player_print('Walkabout failed, check /help walkabout.')
        return
    elseif #params == 2 and tonumber(params[2]) == nil then
        Game.player_print(params[2] .. ' is not a number.')
        return
    elseif #params == 2 and tonumber(params[2]) then
        duration = tonumber(params[2])
    end
    if duration < 15 then
        duration = 15
    end

    local player = game.players[player_name]
    if player == nil or not player.valid or global.walking[player.index] then
        Game.player_print(player_name .. ' could not go on a walkabout.')
        return
    end
    local chunks = {}
    for chunk in player.surface.get_chunks() do
        table.insert(chunks, chunk)
    end

    local surface = player.surface
    local chunk = surface.get_random_chunk()
    local pos = {x = chunk.x * 32, y = chunk.y * 32}
    local non_colliding_pos = surface.find_non_colliding_position('player', pos, 100, 1)

    local character = player.character
    if character and character.valid then
        character.walking_state = {walking = false}
    end

    if non_colliding_pos then
        game.print(player_name .. ' went on a walkabout, to find himself.')
        Task.set_timeout(
            duration,
            custom_commands_return_player,
            {
                player = player,
                force = player.force,
                position = {x = player.position.x, y = player.position.y},
                character = character
            }
        )
        player.character = nil
        player.create_character()
        player.teleport(non_colliding_pos)
        player.force = 'neutral'
        global.walking[player.index] = true
    else
        Game.player_print('Walkabout failed: could not find non colliding position')
    end
end

--- Cleans the walkabout status off players who disconnected during walkabout.
-- Restores their original force, character, and position.
function clean_on_join(event)
    local player = Game.get_player_by_index(event.player_index)
    local index = player.index
    if global.walking[index] then
        global.walking[index] = false
        local walking_storage = global.walking_storage
        for _, s in pairs (walking_storage) do
            if s.index == index then

                local walkabout_character = player.character
                if walkabout_character and walkabout_character.valid then
                    walkabout_character.destroy()
                end

                local character = s.character
                if character ~= nil and character.valid then
                    player.character = character
                else
                    player.create_character()
                    player.teleport(s.position)
                end

                player.force = s.force
            end
        end
    end
end

Event.add(defines.events.on_player_joined_game, clean_on_join)
commands.add_command('walkabout', '<player> <duration> - Send someone on a walk.  (Admins only)', walkabout)
