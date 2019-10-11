local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Gui = require 'utils.gui'
local b = require 'map_gen.shared.builders'
local snake_game = require 'features.snake.game'

local floor = math.floor
local Public = {}

--Lobby Map
local Generate = require 'map_gen.shared.generate'
local shape = b.rectangle(45, 4)
shape = b.change_tile(shape, true, 'concrete')
Generate.get_surfaces()['snake'] = shape

local delay_snake_checker

local players_needed = 4

local size = 45

local snake_generate =
    Token.register(
    function()
        local surface = game.get_surface('snake')
        if surface.get_tile({100, -50}).name == 'out-of-map' and surface.get_tile({100, 50}).name == 'out-of-map' then
            local position = {x = -floor(size), y = 5}
            local max_food = 8
            local speed = 30
            snake_game.start_game(surface, position, size, speed, max_food)
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
            local surface = game.get_surface('snake')
            if surface.get_tile({100, -50}).name == 'out-of-map' and surface.get_tile({100, 50}).name == 'out-of-map' then
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
        local snake_surface = game.create_surface('snake')
        game.forces.player.set_spawn_position({x = 0, y = 0}, snake_surface)
        local y = 128
        local x = 128
        game.forces.player.chart(snake_surface, {lefttop = {x = -x, y = -y}, rightbottom = {x = x, y = y}})
        Task.set_timeout_in_ticks(60 * 3, delay_snake_checker)
    end
)

-- <Waiting GUI start>

local waiting_close_name = Gui.uid_name()

local function show_waiting_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Lobby']
    if (gui) then
        Gui.destroy(gui)
    end

    local snake_button_text

    if snake_game.is_running() then
        snake_button_text = 'Play Snake'
    else
        snake_button_text = '... Loading Snake ...'
    end
    frame = player.gui.center.add {name = 'Space-Race-Lobby', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 8
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'center'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = #game.connected_players .. ' out of ' .. players_needed .. ' players needed to begin!'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    --Footer
    local ok_button_flow = frame.add {type = 'flow'}
    ok_button_flow.style.horizontally_stretchable = true
    ok_button_flow.style.horizontal_align = 'center'

    local ok_button = ok_button_flow.add {type = 'button', name = waiting_close_name, caption = snake_button_text}
    Gui.set_data(ok_button, frame)
end

Gui.on_click(
    waiting_close_name,
    function(event)
        if snake_game.is_running() then
            local frame = Gui.get_data(event.element)
            local player = event.player

            game.permissions.get_group('lobby').remove_player(player)
            snake_game.new_snake(player)

            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

-- <Waiting GUI end>

-- <Join GUI start>

local join_USA = Gui.uid_name()
local join_USSR = Gui.uid_name()

local function show_join_gui(event)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Lobby']
    if (gui) then
        Gui.destroy(gui)
    end

    frame = player.gui.center.add {name = 'Space-Race-Lobby', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 8
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'center'
    label_flow.style.horizontally_stretchable = true

    local label = label_flow.add {type = 'label', caption = 'Feel free to pick a side!'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    --Footer
    local button_flow = frame.add {type = 'flow'}
    button_flow.style.horizontal_align = 'center'
    button_flow.style.horizontally_stretchable = true

    local usa_button_flow = button_flow.add {type = 'flow', direction = 'vertical'}
    usa_button_flow.style.horizontally_stretchable = true
    usa_button_flow.style.horizontal_align = 'center'

    local ussr_button_flow = button_flow.add {type = 'flow', direction = 'vertical'}
    ussr_button_flow.style.horizontally_stretchable = true
    ussr_button_flow.style.horizontal_align = 'center'

    local teams = remote.call('space-race', 'get_teams')

    local force_USSR = teams[2]
    local force_USA = teams[1]

    local usa_players = #force_USA.players
    local ussr_players = #force_USSR.players

    local usa_connected = #force_USA.connected_players
    local ussr_connected = #force_USSR.connected_players

    label = usa_button_flow.add {type = 'label', caption = usa_connected .. ' online / ' .. usa_players .. ' total'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    local join_usa_button = usa_button_flow.add {type = 'button', name = join_USA, caption = 'Join United Factory Workers'}

    label = ussr_button_flow.add {type = 'label', caption = ussr_connected .. ' online / ' .. ussr_players .. ' total'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'
    local join_ussr_button = ussr_button_flow.add {type = 'button', name = join_USSR, caption = 'Join Union of Factory Employees'}

    Gui.set_data(join_usa_button, frame)
    Gui.set_data(join_ussr_button, frame)
end

Gui.on_click(
    join_USA,
    function(event)
        local frame = Gui.get_data(event.element)
        local player = event.player

        if remote.call('space-race', 'join_usa', nil, player) then
            Gui.remove_data_recursively(frame)
            frame.destroy()
            Public.update_gui()
        end
    end
)

Gui.on_click(
    join_USSR,
    function(event)
        local frame = Gui.get_data(event.element)
        local player = event.player

        if remote.call('space-race', 'join_ussr', nil, player) then
            Gui.remove_data_recursively(frame)
            frame.destroy()
            Public.update_gui()
        end
    end
)

-- <Join GUI end>

-- <Won GUI start>

local won_close_name = Gui.uid_name()

local function show_won_gui(event, force)
    local frame
    local player = game.get_player(event.player_index)
    local center = player.gui.center
    local gui = center['Space-Race-Lobby']
    if (gui) then
        Gui.destroy(gui)
    end

    local snake_button_text

    if snake_game.is_running() then
        snake_button_text = 'Play Snake'
    else
        snake_button_text = '... Loading Snake ...'
    end
    frame = player.gui.center.add {name = 'Space-Race-Lobby', type = 'frame', direction = 'vertical', style = 'captionless_frame'}

    frame.style.minimal_width = 300

    --Header
    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.style.horizontal_align = 'center'
    top_flow.style.horizontally_stretchable = true

    local title_flow = top_flow.add {type = 'flow'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_padding = 8
    title_flow.style.horizontally_stretchable = false

    local title = title_flow.add {type = 'label', caption = 'Welcome to Space Race'}
    title.style.font = 'default-large-bold'

    --Body

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 8
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontal_align = 'center'
    content_flow.style.horizontally_stretchable = true

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'center'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = force.name .. ' have won the game!\nWaiting for map restart\n\nPlay some snake while we wait!'}
    label.style.horizontal_align = 'center'
    label.style.single_line = false
    label.style.font = 'default'

    --Footer
    local ok_button_flow = frame.add {type = 'flow'}
    ok_button_flow.style.horizontally_stretchable = true
    ok_button_flow.style.horizontal_align = 'center'

    local ok_button = ok_button_flow.add {type = 'button', name = won_close_name, caption = snake_button_text}
    Gui.set_data(ok_button, frame)
end

Gui.on_click(
    won_close_name,
    function(event)
        if snake_game.is_running() then
            local frame = Gui.get_data(event.element)
            local player = event.player

            game.permissions.get_group('lobby').remove_player(player)
            snake_game.new_snake(player)

            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

-- <Won GUI end>

function Public.show_gui(event)
    if #game.connected_players < players_needed and (not remote.call('space-race', 'get_game_status')) then
        if not snake_game.is_running() and game.tick > 60 * 55 then
            Token.get(snake_generate)()
        end
        game.forces.enemy.evolution_factor = 0
        show_waiting_gui(event)
        return
    end
    local won = remote.call('space-race', 'get_won')
    if won then
        show_won_gui(event, won)
    else
        if snake_game.is_running() then
            snake_game.end_game()
        end
        show_join_gui(event)
    end
end

function Public.update_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        local center = player.gui.center
        local gui = center['Space-Race-Lobby']
        if (gui) then
            Public.show_gui({player_index = player.index})
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

return Public
