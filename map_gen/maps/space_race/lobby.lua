local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local b = require 'map_gen.shared.builders'
local snake_game = require 'features.snake.game'
local config = require 'map_gen.maps.space_race.config'
local Gui = require 'utils.gui'

--Guis
local join_gui = require 'map_gen.maps.space_race.gui.join_gui'
local wait_gui = require 'map_gen.maps.space_race.gui.wait_gui'
local won_gui = require 'map_gen.maps.space_race.gui.won_gui'

local floor = math.floor
local Public = {}

local size = config.snake.size
local snake_check_x = (size + 5) * 2
local snake_check_y = size + 5

--Lobby Map
local Generate = require 'map_gen.shared.generate'
local shape = b.rectangle(size, 4)
shape = b.change_tile(shape, true, 'concrete')
Generate.get_surfaces()['snake'] = shape

local delay_snake_checker

local players_needed = config.players_needed_to_start_game

local function check_snake_map_gen()
    local surface = game.get_surface('snake')
    return surface.get_tile({snake_check_x, -snake_check_y}).name == 'out-of-map' and surface.get_tile({snake_check_x, snake_check_y}).name == 'out-of-map'
end

local snake_generate =
    Token.register(
    function()
        local surface = game.get_surface('snake')
        if check_snake_map_gen() then
            local position = {x = -floor(size), y = 5}
            local max_food = config.snake.max_food
            local speed = config.snake.speed
            if not snake_game.is_running() then
                snake_game.start_game(surface, position, size, speed, max_food)
            end
        else
            Task.set_timeout_in_ticks(5, delay_snake_checker)
        end
    end
)

local check_map_gen_is_done
check_map_gen_is_done =
    Token.register(
    function()
        if not snake_game.is_running() then
            if check_snake_map_gen() then
                Event.remove_removable_nth_tick(60, check_map_gen_is_done)
                Token.get(snake_generate)()
                Public.update_gui()
                return
            end
        else
            Event.remove_removable_nth_tick(60, check_map_gen_is_done)
            Public.update_gui()
        end
    end
)

delay_snake_checker =
    Token.register(
    function()
        Event.add_removable_nth_tick(60, check_map_gen_is_done)
    end
)

Event.on_init(
    function()
        local snake_surface = game.create_surface('snake', {height = 1, width = 1})
        game.forces.player.set_spawn_position({x = 0, y = 0}, snake_surface)
        local y = 128
        local x = 128
        game.forces.player.chart(snake_surface, {lefttop = {x = -x, y = -y}, rightbottom = {x = x, y = y}})
        Task.set_timeout_in_ticks(60 * 3, delay_snake_checker)
    end
)

function Public.show_gui(event)
    if #game.connected_players < players_needed and (not remote.call('space-race', 'get_game_status')) then
        if not snake_game.is_running() and game.tick > 60 * 55 then
            Token.get(snake_generate)()
        end
        game.forces.enemy.evolution_factor = 0
        wait_gui.show_gui(event)
        return
    end
    local won = remote.call('space-race', 'get_won')
    if won then
        won_gui.show_gui(event, won)
    else
        if snake_game.is_running() then
            snake_game.end_game()
        end
        join_gui.show_gui(event)
    end
end

function Public.update_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        local center = player.gui.center
        local gui = center['Space-Race-Lobby']
        if (gui) then
            if player.force.name == 'player' then
                Public.show_gui({player_index = player.index})
            else
                Gui.destroy(gui)
            end
        end
    end
end

local function on_snake_player_died(event)
    local player = event.player
    game.permissions.get_group('lobby').add_player(player)
    Public.show_gui({player_index = player.index})
    player.teleport({0, 0}, game.get_surface('snake'))
end

local function to_lobby(player_index)
    local player = game.get_player(player_index)
    player.teleport({0, 0}, game.get_surface('snake'))
    game.permissions.get_group('lobby').add_player(player)

    local character = player.character
    if character and character.valid then
        player.character.destroy()
    end
    player.set_controller {type = defines.controllers.ghost}
    Public.show_gui({player_index = player.index})
end

local function on_player_created(event)
    to_lobby(event.player_index)
end

local function on_player_joined(event)
    local won = remote.call('space-race', 'get_won')
    if won then
        to_lobby(event.player_index)
    end
    Public.update_gui()
end

local delay_to_lobby =
    Token.register(
    function()
        local teams = remote.call('space-race', 'get_teams')
        game.remove_offline_players()
        for i = 1, #teams do
            for _, player in pairs(teams[i].connected_players) do
                player.force = game.forces.player
                to_lobby(player.index)
            end
        end
    end
)

local function on_player_left()
    if #game.connected_players < players_needed and (not remote.call('space-race', 'get_game_status')) then
        Task.set_timeout_in_ticks(1, delay_to_lobby) -- Other on_player_left_game events would error if we removed offline players instantly
    end
    Public.update_gui()
end

Event.add(snake_game.events.on_snake_player_died, on_snake_player_died)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_joined_game, on_player_joined)
Event.add(defines.events.on_player_left_game, on_player_left)

function Public.all_to_lobby()
    local players = game.connected_players
    for i = 1, #players do
        to_lobby(players[i].index)
    end
    Task.set_timeout_in_ticks(5, snake_generate)
end

function Public.to_lobby(player_index)
    to_lobby(player_index)
end

remote.add_interface('space-race-lobby', Public)

return Public
