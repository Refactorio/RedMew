local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Server = require 'features.server'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Popup = require 'features.gui.popup'
require 'utils.string'

local Public = {}

local game_types = {scenario = 'scenario', save = 'save'}
Public.game_types = game_types

local memory = {
    mod_pack_text = '',
    restarting = nil,
    use_map_poll_result = nil,
    known_mod_packs = nil
}
local start_game_data = {
    type = game_types.scenario,
    name = '',
    mod_pack = nil
}

Global.register({
    start_game_data = start_game_data,
    memory = memory
}, function(tbl)
    start_game_data = tbl.start_game_data
    memory = tbl.memory
end)

local function default_can_restart_func(player)
    return player.valid and player.admin
end

local registered = false
local server_can_restart_func = default_can_restart_func
local server_restart_requested_callback = nil
local server_restart_callback = nil

local server_player = {name = '<server>', print = print, admin = true}

local function double_print(str)
    game.print(str)
    print(str)
end

local restart_callback_token
restart_callback_token = Token.register(function(data)
    if not memory.restarting then
        return
    end

    local state = data.state
    if state == 0 then
        if server_restart_callback then
            server_restart_callback()
        end

        Server.start_game(start_game_data)
        double_print('restarting')
        memory.restarting = nil
        return
    elseif state == 1 then
        Popup.all('\nServer restarting!\nInitiated by ' .. data.player_name .. '\n' .. 'Next map: '
                      .. start_game_data.name)
    end

    double_print(state)

    data.state = state - 1
    Task.set_timeout_in_ticks(60, restart_callback_token, data)
end)

local function get_start_data(player)
    local message = {'Start Game Data:', '\nType: ', start_game_data.type, '\nName: ', start_game_data.name}

    local mod_pack = start_game_data.mod_pack
    if mod_pack then
        message[#message + 1] = '\nMod Pack: '
        message[#message + 1] = mod_pack
    end

    local text = table.concat(message)
    player.print(text)
end

local function sanitize_set_start_data_str(str)
    str = str:trim()

    local first_char = str:sub(1, 1)
    if first_char == "'" or first_char == '"' or first_char == '{' then
        return str
    end

    return '"' .. str .. '"'
end

local function set_start_data(player, str)
    str = sanitize_set_start_data_str(str)

    local func, err = loadstring('return ' .. str)
    if not func then
        player.print(err)
        return false
    end

    local suc, value = pcall(func)
    if not suc then
        if value then
            local i = value:find('\n')
            if i then
                player.print(value:sub(1, i))
                return false
            end

            i = value:find('%s')
            if i then
                player.print(value:sub(i + 1))
            end
        end

        return false
    end

    Public.set_start_game_data(value)

    player.print('Start Game Data set')
    get_start_data(player)

    return true
end

local function restart(args, player)
    player = player or server_player

    if memory.restarting then
        player.print('Restart already in progress')
        return
    end

    if not server_can_restart_func(player) then
        return
    end

    if server_restart_requested_callback then
        server_restart_requested_callback()
    end

    local str = args.str:trim()
    if str ~= '' and player.admin then
        if not set_start_data(player, str) then
            return
        end
    end

    memory.restarting = true

    double_print('#################-Attention-#################')
    double_print('Server restart initiated by ' .. player.name)
    double_print('Next map: ' .. start_game_data.name)
    double_print('###########################################')

    for _, p in pairs(game.players) do
        if p.admin then
            p.print('Abort restart with /abort')
        end
    end
    print('Abort restart with /abort')
    Task.set_timeout_in_ticks(60, restart_callback_token, {state = 10, player_name = player.name})
end

local function abort(_, player)
    player = player or server_player

    if memory.restarting then
        memory.restarting = nil
        double_print('Restart aborted by ' .. player.name)
    else
        player.print('Cannot abort a restart that is not in progress.')
    end
end

function Public.register(can_restart_func, restart_callback, restart_requested_callback)
    if registered then
        error('Register can only be called once', 2)
    end

    if _LIFECYCLE == 8 then
        error('Calling Token.register after on_init() or on_load() has run is a desync risk.', 2)
    end

    registered = true
    server_can_restart_func = can_restart_func or default_can_restart_func
    server_restart_requested_callback = restart_requested_callback
    server_restart_callback = restart_callback
end

function Public.get_use_map_poll_result_option()
    return memory.use_map_poll_result
end

function Public.set_use_map_poll_result_option(state)
    memory.use_map_poll_result = state
end

function Public.get_known_modpacks_option()
    return memory.known_mod_packs
end

function Public.set_known_modpacks_option(state)
    memory.known_mod_packs = state
end

local main_frame_name = Gui.uid_name()
local close_button_name = Gui.uid_name()
local scenario_radio_button_name = Gui.uid_name()
local save_radio_button_name = Gui.uid_name()
local name_textfield_name = Gui.uid_name()
local set_mod_pack_checkbox_name = Gui.uid_name()
local mod_pack_name_textfield_name = Gui.uid_name()
local use_map_poll_result_checkbox_name = Gui.uid_name()
local known_mod_pack_textfield_name = Gui.uid_name()

Public._main_frame_name = main_frame_name
Public._close_button_name = close_button_name
Public._scenario_radio_button_name = scenario_radio_button_name
Public._save_radio_button_name = save_radio_button_name
Public._name_textfield_name = name_textfield_name
Public._set_mod_pack_checkbox_name = set_mod_pack_checkbox_name
Public._mod_pack_name_textfield_name = mod_pack_name_textfield_name
Public._use_map_poll_result_checkbox_name = use_map_poll_result_checkbox_name
Public._known_mod_pack_textfield_name = known_mod_pack_textfield_name

local function value_of_type_or_deafult(value, value_type, default)
    if type(value) == value_type then
        return value
    end

    return default
end

--- Gets the data used to start the next game when restart is used.
-- @returns data<table> {type<string:'scenario'|'save'>, name<string>, mod_pack<string?>}
function Public.get_start_game_data()
    return {type = start_game_data.type, name = start_game_data.name, mod_pack = start_game_data.mod_pack}
end

--- Sets the data used to start the next game when restart is used.
-- @params data<table|string> {type<string?:'scenario'|'save'='scenario'>, name<string>, mod_pack<string?>}
-- If mod_pack is nil that means to use the current mod pack, set to empty string ('') to use no mod pack.
-- When data is a string: type is scenario, name is data and mod_pack is nil.
-- Note: name and mod_pack are case sensitive.
function Public.set_start_game_data(data)
    local data_type = type(data)
    if data_type == 'string' then
        data = {type = game_types.scenario, name = data}
    elseif data_type ~= 'table' then
        error('data must be a table or string', 2)
    end

    local game_type = value_of_type_or_deafult(data.type, 'string', game_types.scenario)
    local name = value_of_type_or_deafult(data.name, 'string', '')
    local mod_pack = value_of_type_or_deafult(data.mod_pack, 'string', nil)

    game_type = game_type:lower()
    if game_type ~= game_types.save then
        game_type = game_types.scenario
    end

    start_game_data.type = game_type
    start_game_data.name = name
    start_game_data.mod_pack = mod_pack

    if mod_pack then
        memory.mod_pack_text = mod_pack
    else
        memory.mod_pack_text = ''
    end
end

local function draw_main_frame(player)
    if player == server_player then
        player.print('/config-restart with no arguments cannot be used from the server.')
        return
    end

    local center = player.gui.center
    local main_frame = center[main_frame_name]
    if main_frame and main_frame.valid then
        Gui.destroy(main_frame)
    end

    main_frame = center.add {
        type = 'frame',
        name = main_frame_name,
        caption = 'Configure Restart',
        direction = 'vertical'
    }

    local is_scenario = start_game_data.type == game_types.scenario
    local radio_button_flow = main_frame.add {type = 'flow', direction = 'horizontal'}
    radio_button_flow.add {type = 'label', caption = 'Type:'}
    local scenario_radio_button = radio_button_flow.add {
        type = 'radiobutton',
        name = scenario_radio_button_name,
        caption = 'scenario',
        state = is_scenario
    }
    local save_radio_button = radio_button_flow.add {
        type = 'radiobutton',
        name = save_radio_button_name,
        caption = 'save',
        state = not is_scenario
    }

    local radio_data = {scenario_radio_button = scenario_radio_button, save_radio_button = save_radio_button}

    Gui.set_data(scenario_radio_button, radio_data)
    Gui.set_data(save_radio_button, radio_data)

    local name_flow = main_frame.add {type = 'flow', direction = 'horizontal'}
    name_flow.add {type = 'label', caption = 'Name:'}
    local name_textfield = name_flow.add {type = 'textfield', name = name_textfield_name, text = start_game_data.name}
    name_textfield.style.horizontally_stretchable = true
    name_textfield.style.maximal_width = 600

    local is_set_mod_pack = start_game_data.mod_pack ~= nil
    local set_mod_pack_checkbox = main_frame.add {
        type = 'checkbox',
        name = set_mod_pack_checkbox_name,
        caption = 'Set mod pack (uncheck to not change current)',
        state = is_set_mod_pack
    }
    local mod_pack_name_flow = main_frame.add {type = 'flow', direction = 'horizontal'}
    mod_pack_name_flow.add {type = 'label', caption = 'Mod Pack (empty to set none):'}
    local mod_pack_name_textfield = mod_pack_name_flow.add {
        type = 'textfield',
        name = mod_pack_name_textfield_name,
        text = memory.mod_pack_text
    }
    mod_pack_name_textfield.enabled = is_set_mod_pack

    Gui.set_data(set_mod_pack_checkbox, mod_pack_name_textfield)

    if memory.use_map_poll_result ~= nil then
        main_frame.add {
            type = 'checkbox',
            name = use_map_poll_result_checkbox_name,
            caption = 'Use map poll result',
            state = memory.use_map_poll_result
        }
    end

    if memory.known_mod_packs ~= nil then
        for mod_pack_name, mod_pack_value in pairs(memory.known_mod_packs) do
            local mod_pack_flow = main_frame.add {type = 'flow', direction = 'horizontal'}
            mod_pack_flow.add {type = 'label', caption = mod_pack_name .. ':'}
            local mod_pack_textfield = mod_pack_flow.add {type = 'textfield', name = known_mod_pack_textfield_name, text = mod_pack_value}
            Gui.set_data(mod_pack_textfield, mod_pack_name)
        end
    end

    local bottom_flow = main_frame.add {
        type = 'flow',
        direction = 'horizontal'
    }

    bottom_flow.add {
        type = 'button',
        name = close_button_name,
        caption = {'common.close_button'},
        style = 'back_button'
    }
end

Gui.on_click(close_button_name, function(event)
    local main_frame = event.player.gui.center[main_frame_name]
    if main_frame and main_frame.valid then
        Gui.destroy(main_frame)
    end
end)

local function set_game_type(radio_data, game_type)
    radio_data.scenario_radio_button.state = game_type == game_types.scenario
    radio_data.save_radio_button.state = game_type == game_types.save

    start_game_data.type = game_type
end

Gui.on_checked_state_changed(scenario_radio_button_name, function(event)
    local radio_data = Gui.get_data(event.element)
    set_game_type(radio_data, game_types.scenario)
end)

Gui.on_checked_state_changed(save_radio_button_name, function(event)
    local radio_data = Gui.get_data(event.element)
    set_game_type(radio_data, game_types.save)
end)

Gui.on_text_changed(name_textfield_name, function(event)
    start_game_data.name = event.element.text
end)

Gui.on_checked_state_changed(set_mod_pack_checkbox_name, function(event)
    local set_mod_pack_checkbox = event.element
    local mod_pack_name_textfield = Gui.get_data(set_mod_pack_checkbox)

    if set_mod_pack_checkbox.state then
        mod_pack_name_textfield.enabled = true
        start_game_data.mod_pack = memory.mod_pack_text
    else
        mod_pack_name_textfield.enabled = false
        start_game_data.mod_pack = nil
    end
end)

Gui.on_checked_state_changed(use_map_poll_result_checkbox_name, function(event)
    local use_map_poll_result_checkbox = event.element
    memory.use_map_poll_result = use_map_poll_result_checkbox.state
end)

Gui.on_text_changed(mod_pack_name_textfield_name, function(event)
    local text = event.element.text
    start_game_data.mod_pack = text
    memory.mod_pack_text = text
end)

Gui.on_text_changed(known_mod_pack_textfield_name, function(event)
    local textfield = event.element
    local mod_pack_name = Gui.get_data(textfield)
    local mod_pack_value = textfield.text
    memory.known_mod_packs[mod_pack_name] = mod_pack_value
end)

local function config_restart(args, player)
    local str = args.str
    player = player or server_player

    if str == '' then
        draw_main_frame(player)
    elseif str == 'get' then
        get_start_data(player)
    elseif str:sub(1, 3) == 'set' then
        str = str:sub(4) -- remove 'set' from start of str.
        set_start_data(player, str)
    else
        player.print('Invalid arguments')
    end
end

Public._config_restart = config_restart

Command.add('config-restart', {
    description = [[
configure the restart command
use /config-restart to open a gui,
use /config-restart get to prints the values,
use /config-restart set scenario_name<string> | {type<string?>, name<string>, mod_pack<string?>} to set the values
e.g. /config-restart set 'develop'
or /config-restart set {type = 'save', name = 'file.zip'}
or /config-restart set {type = 'scenario', name = 'develop', mod_pack = 'mod'}
]],
    arguments = {'str'},
    default_values = {str = ''},
    capture_excess_arguments = true,
    required_rank = Ranks.admin,
    allowed_by_server = true,
    allowed_by_player = true
}, config_restart)

Command.add('abort',
    {description = {'command_description.abort'}, required_rank = Ranks.admin, allowed_by_server = true}, abort)

Command.add('restart', {
    description = {'command_description.restart'},
    arguments = {'str'},
    capture_excess_arguments = true,
    default_values = {str = ''},
    required_rank = Ranks.guest,
    allowed_by_server = true
}, restart)

return Public
