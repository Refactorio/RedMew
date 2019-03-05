--- See documentation at https://github.com/Refactorio/RedMew/pull/469

local Token = require 'utils.token'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Timestamp = require 'utils.timestamp'
local Print = require('utils.print_override')
local ErrorLogging = require 'utils.error_logging'

local serialize = serpent.serialize
local concat = table.concat
local remove = table.remove
local tostring = tostring
local raw_print = Print.raw_print

local serialize_options = {sparse = true, compact = true}

local Public = {}

local server_time = {secs = nil, tick = 0}
ErrorLogging.server_time = server_time

Global.register(
    server_time,
    function(tbl)
        server_time = tbl
        ErrorLogging.server_time = tbl
    end
)

local discord_tag = '[DISCORD]'
local discord_raw_tag = '[DISCORD-RAW]'
local discord_bold_tag = '[DISCORD-BOLD]'
local discord_admin_tag = '[DISCORD-ADMIN]'
local discord_admin_raw_tag = '[DISCORD-ADMIN-RAW]'
local discord_embed_tag = '[DISCORD-EMBED]'
local discord_embed_raw_tag = '[DISCORD-EMBED-RAW]'
local discord_admin_embed_tag = '[DISCORD-ADMIN-EMBED]'
local discord_admin_embed_raw_tag = '[DISCORD-ADMIN-EMBED-RAW]'
local start_scenario_tag = '[START-SCENARIO]'
local ping_tag = '[PING]'
local data_set_tag = '[DATA-SET]'
local data_get_tag = '[DATA-GET]'
local data_get_all_tag = '[DATA-GET-ALL]'
local data_tracked_tag = '[DATA-TRACKED]'
local ban_sync_tag = '[BAN-SYNC]'
local unbanned_sync_tag = '[UNBANNED-SYNC]'
local query_players_tag = '[QUERY-PLAYERS]'
local player_join_tag = '[PLAYER-JOIN]'
local player_leave_tag = '[PLAYER-LEAVE]'

Public.raw_print = raw_print

local data_set_handlers = {}

--- The event id for the on_server_started event.
-- The event is raised whenever the server goes from the starting state to the running state.
-- It provides a good opportunity to request data from the web server.
-- Note that if the server is stopped then started again, this event will be raised again.
-- @usage
-- local Server = require 'features.server'
-- local Event = require 'utils.event'
--
-- Event.add(Server.events.on_server_started,
-- function()
--      Server.try_get_all_data('regulars', callback)
-- end)
Public.events = {on_server_started = Event.generate_event_name('on_server_started')}

--- Sends a message to the linked discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @usage
-- local Server = require 'features.server'
-- Server.to_discord('Hello from scenario script!')
function Public.to_discord(message)
    raw_print(discord_tag .. message)
end

--- Sends a message to the linked discord channel. The message is not sanitized of markdown.
-- @param  message<string> message to send.
function Public.to_discord_raw(message)
    raw_print(discord_raw_tag .. message)
end

--- Sends a message to the linked discord channel. The message is sanitized of markdown server side, then made bold.
-- @param  message<string> message to send.
function Public.to_discord_bold(message)
    raw_print(discord_bold_tag .. message)
end

--- Sends a message to the linked admin discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
function Public.to_admin(message)
    raw_print(discord_admin_tag .. message)
end

--- Sends a message to the linked admin discord channel. The message is not sanitized of markdown.
-- @param  message<string> message to send.
function Public.to_admin_raw(message)
    raw_print(discord_admin_raw_tag .. message)
end

--- Sends a embed message to the linked discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
function Public.to_discord_embed(message)
    raw_print(discord_embed_tag .. message)
end

--- Sends a embed message to the linked discord channel. The message is not sanitized of markdown.
-- @param  message<string> the content of the embed.
function Public.to_discord_embed_raw(message)
    raw_print(discord_embed_raw_tag .. message)
end

--- Sends a embed message to the linked admin discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
function Public.to_admin_embed(message)
    raw_print(discord_admin_embed_tag .. message)
end

--- Sends a embed message to the linked admin discord channel. The message is not sanitized of markdown.
-- @param  message<string> the content of the embed.
function Public.to_admin_embed_raw(message)
    raw_print(discord_admin_embed_raw_tag .. message)
end

--- Stops and saves the factorio server and starts the named scenario.
-- @param  scenario_name<string> The name of the scenario as appears in the scenario table on http://redmew.com/admin
-- @usage
-- local Server = require 'features.server'
-- Server.start_scenario('my_scenario_name')
function Public.start_scenario(scenario_name)
    if type(scenario_name) ~= 'string' then
        game.print('start_scenario - scenario_name ' .. tostring(scenario_name) .. ' must be a string.')
        return
    end

    local message = start_scenario_tag .. scenario_name

    raw_print(message)
end

local default_ping_token =
    Token.register(
    function(sent_tick)
        local now = game.tick
        local diff = now - sent_tick

        local message = concat({'Pong in ', diff, ' tick(s) ', 'sent tick: ', sent_tick, ' received tick: ', now})
        game.print(message)
    end
)

--- Pings the web server.
-- @param  func_token<token> The function that is called when the web server replies.
-- The function is passed the tick that the ping was sent.
function Public.ping(func_token)
    local message = concat({ping_tag, func_token or default_ping_token, ' ', game.tick})
    raw_print(message)
end

local function double_escape(str)
    -- Excessive escaping because the data is serialized twice.
    return str:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"'):gsub('\n', '\\\\n')
end

--- Sets the web server's persistent data storage. If you pass nil for the value removes the data.
-- Data set this will by synced in with other server if they choose to.
-- There can only be one key for each data_set.
-- @param  data_set<string>
-- @param  key<string>
-- @param  value<nil|boolean|number|string|table> Any type that is not a function. set to nil to remove the data.
-- @usage
-- local Server = require 'features.server'
-- Server.set_data('my data set', 'key 1', 123)
-- Server.set_data('my data set', 'key 2', 'abc')
-- Server.set_data('my data set', 'key 3', {'some', 'data', ['is_set'] = true})
--
-- Server.set_data('my data set', 'key 1', nil) -- this will remove 'key 1'
-- Server.set_data('my data set', 'key 2', 'def') -- this will change the value for 'key 2' to 'def'
function Public.set_data(data_set, key, value)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end
    if type(key) ~= 'string' then
        error('key must be a string', 2)
    end

    data_set = double_escape(data_set)
    key = double_escape(key)

    local message
    local vt = type(value)
    if vt == 'nil' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '"}'})
    elseif vt == 'string' then
        value = double_escape(value)

        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"\\"', value, '\\""}'})
    elseif vt == 'number' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', value, '"}'})
    elseif vt == 'boolean' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', tostring(value), '"}'})
    elseif vt == 'function' then
        error('value cannot be a function', 2)
    else -- table
        value = serialize(value, serialize_options)

        -- Less escaping than the string case as serpent provides one level of escaping.
        -- Need to escape single quotes as serpent uses double quotes for strings.
        value = value:gsub('\\', '\\\\'):gsub("'", "\\'")

        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, "\",value:'", value, "'}"})
    end

    raw_print(message)
end

--- Gets data from the web server's persistent data storage.
-- The callback is passed a table {data_set: string, key: string, value: any}.
-- If the value is nil, it means there is no stored data for that data_set key pair.
-- @param  data_set<string>
-- @param  key<string>
-- @param  callback_token<token>
-- @usage
-- local Server = require 'features.server'
-- local Token = require 'utils.token'
--
-- local callback =
--     Token.register(
--     function(data)
--         local data_set = data.data_set
--         local key = data.key
--         local value = data.value -- will be nil if no data
--
--         game.print(data_set .. ':' .. key .. ':' .. tostring(value))
--     end
-- )
--
-- Server.try_get_data('my data set', 'key 1', callback)
function Public.try_get_data(data_set, key, callback_token)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end
    if type(key) ~= 'string' then
        error('key must be a string', 2)
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number', 2)
    end

    data_set = double_escape(data_set)
    key = double_escape(key)

    local message = concat {data_get_tag, callback_token, ' {', 'data_set:"', data_set, '",key:"', key, '"}'}
    raw_print(message)
end

--- Gets all the data for the data_set from the web server's persistent data storage.
-- The callback is passed a table {data_set: string, entries: {dictionary key -> value}}.
-- If there is no data stored for the data_set entries will be nil.
-- @param  data_set<string>
-- @param  callback_token<token>
-- @usage
-- local Server = require 'features.server'
-- local Token = require 'utils.token'
--
-- local callback =
--     Token.register(
--     function(data)
--         local data_set = data.data_set
--         local entries = data.entries -- will be nil if no data
--         local value2 = entries['key 2']
--         local value3 = entries['key 3']
--     end
-- )
--
-- Server.try_get_all_data('my data set', callback)
function Public.try_get_all_data(data_set, callback_token)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number', 2)
    end

    data_set = double_escape(data_set)

    local message = concat {data_get_all_tag, callback_token, ' {', 'data_set:"', data_set, '"}'}
    raw_print(message)
end

local function data_set_changed(data)
    local handlers = data_set_handlers[data.data_set]
    if handlers == nil then
        return
    end

    if _DEBUG then
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
                ErrorLogging.generate_error_report(err)
                error(err, 2)
            end
        end
    else
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
                ErrorLogging.generate_error_report(err)
            end
        end
    end
end

--- Register a handler to be called when the data_set changes.
-- The handler is passed a table {data_set:string, key:string, value:any}
-- If value is nil that means the key was removed.
-- The handler may be called even if the value hasn't changed. It's up to the implementer
-- to determine if the value has changed, or not care.
-- To prevent desyncs the same handlers must be registered for all clients. The easiest way to do this
-- is in the control stage, i.e before on_init or on_load would be called.
-- @param  data_set<string>
-- @param  handler<function>
-- @usage
-- local Server = require 'features.server'
-- Server.on_data_set_changed(
--     'my data set',
--     function(data)
--         local data_set = data.data_set
--         local key = data.key
--         local value = data.value -- will be nil if data was removed.
--     end
-- )
function Public.on_data_set_changed(data_set, handler)
    if _LIFECYCLE == _STAGE.runtime then
        error('cannot call during runtime', 2)
    end
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end

    local handlers = data_set_handlers[data_set]
    if handlers == nil then
        handlers = {handler}
        data_set_handlers[data_set] = handlers
    else
        handlers[#handlers + 1] = handler
    end
end

--- Called by the web server to notify the client that a data_set has changed.
Public.raise_data_set = data_set_changed

--- Called by the web server to determine which data_sets are being tracked.
function Public.get_tracked_data_sets()
    local message = {data_tracked_tag, '['}

    for k, _ in pairs(data_set_handlers) do
        k = double_escape(k)

        local message_length = #message
        message[message_length + 1] = '"'
        message[message_length + 2] = k
        message[message_length + 3] = '"'
        message[message_length + 4] = ','
    end

    if message[#message] == ',' then
        remove(message)
    end

    message[#message + 1] = ']'

    message = concat(message)
    raw_print(message)
end

local function escape(str)
    return str:gsub('\\', '\\\\'):gsub('"', '\\"')
end

--- If the player exists bans the player.
-- Regardless of whether or not the player exists the name is synchronized with other servers
-- and stored in the database.
-- @param  username<string>
-- @param  reason<string?> defaults to empty string.
-- @param  admin<string?> admin's name, defaults to '<script>'
function Public.ban_sync(username, reason, admin)
    if type(username) ~= 'string' then
        error('username must be a string', 2)
    end

    if reason == nil then
        reason = ''
    elseif type(reason) ~= 'string' then
        error('reason must be a string or nil', 2)
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil', 2)
    end

    -- game.ban_player errors if player not found.
    -- However we may still want to use this function to ban player names.
    local player = game.players[username]
    if player then
        game.ban_player(player, reason)
    end

    username = escape(username)
    reason = escape(reason)
    admin = escape(admin)

    local message = concat({ban_sync_tag, '{username:"', username, '",reason:"', reason, '",admin:"', admin, '"}'})
    raw_print(message)
end

--- If the player exists bans the player else throws error.
-- The ban is not synchronized with other servers or stored in the database.
-- @param  PlayerSpecification
-- @param  reason<string?> defaults to empty string.
function Public.ban_non_sync(PlayerSpecification, reason)
    game.ban_player(PlayerSpecification, reason)
end

--- If the player exists unbans the player.
-- Regardless of whether or not the player exists the name is synchronized with other servers
-- and removed from the database.
-- @param  username<string>
-- @param  admin<string?> admin's name, defaults to '<script>'. This name is stored in the logs for who removed the ban.
function Public.unban_sync(username, admin)
    if type(username) ~= 'string' then
        error('username must be a string', 2)
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil', 2)
    end

    -- game.unban_player errors if player not found.
    -- However we may still want to use this function to unban player names.
    local player = game.players[username]
    if player then
        game.unban_player(username)
    end

    username = escape(username)
    admin = escape(admin)

    local message = concat({unbanned_sync_tag, '{username:"', username, '",admin:"', admin, '"}'})
    raw_print(message)
end

--- If the player exists unbans the player else throws error.
-- The ban is not synchronized with other servers or removed from the database.
-- @param  PlayerSpecification
function Public.unban_non_sync(PlayerSpecification)
    game.unban_player(PlayerSpecification)
end

--- Called by the web server to set the server time.
-- @param  secs<number> unix epoch timestamp
function Public.set_time(secs)
    server_time.secs = secs
    server_time.tick = game.tick
end

--- Gets a table {secs:number?, tick:number} with secs being the unix epoch timestamp
-- for the server time and ticks the number of game ticks ago it was set.
-- @return table
function Public.get_time_data_raw()
    return server_time
end

--- Gets an estimate of the current server time as a unix epoch timestamp.
-- If the server time has not been set returns nil.
-- The estimate may be slightly off if within the last minute the game has been paused, saving or overwise,
-- or the game speed has been changed.
-- @return number?
function Public.get_current_time()
    local secs = server_time.secs
    if secs == nil then
        return nil
    end

    local diff = game.tick - server_time.tick
    return math.floor(secs + diff / game.speed / 60)
end

--- Called be the web server to re sync which players are online.
function Public.query_online_players()
    local message = {query_players_tag, '['}

    for _, p in ipairs(game.connected_players) do
        message[#message + 1] = '"'
        local name = escape(p.name)
        message[#message + 1] = name
        message[#message + 1] = '",'
    end

    if message[#message] == '",' then
        message[#message] = '"'
    end

    message[#message + 1] = ']'

    message = concat(message)
    raw_print(message)
end

--- Sets the server time as the scenario version. Imperfect since we ideally want the commit,
-- but an easy way to at least establish a baseline.
local function set_scenario_version()
    -- A 1 hour buffer is in place to account for potential playtime pre-upload.
    if game.tick < 216000 and not global.redmew_version then
        local time_string = Timestamp.to_string(Public.get_current_time())
        global.redmew_version = string.format('Time of map launch: %s UTC', time_string)
    end
end

Event.add(Public.events.on_server_started, set_scenario_version)

--- The [JOIN] nad [LEAVE] messages Factorio sends to stdout aren't sent in all cases of
--  players joining or leaving. So we send our own [PLAYER-JOIN] and [PLAYER-LEAVE] tags.
Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        if not player then
            return
        end

        raw_print(player_join_tag .. player.name)
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        local player = Game.get_player_by_index(event.player_index)
        if not player then
            return
        end

        raw_print(player_leave_tag .. player.name)
    end
)

return Public
