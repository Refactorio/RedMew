--- See documentation at https://github.com/Refactorio/RedMew/pull/469

local Token = require 'utils.token'
local Global = require 'utils.global'

local Public = {}

local raw_print = print
function print(str)
    raw_print('[PRINT] ' .. str)
end

local server_time = {secs = 0, tick = 0}

Global.register(
    server_time,
    function(tbl)
        server_time = tbl
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
Public.events = {on_server_started = script.generate_event_name()}

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

        local message = table.concat({'Pong in ', diff, ' tick(s) ', 'sent tick: ', sent_tick, ' received tick: ', now})
        game.print(message)
    end
)

--- Pings the web server.
-- @param  func_token<token> The function that is called when the web server replies.
-- The function is passed the tick that the ping was sent.
function Public.ping(func_token)
    local message = table.concat({ping_tag, func_token or default_ping_token, ' ', game.tick})
    raw_print(message)
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
        error('data_set must be a string')
    end
    if type(key) ~= 'string' then
        error('key must be a string')
    end

    -- Excessive escaping because the data is serialized twice.
    data_set = data_set:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')
    key = key:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')

    local message
    local vt = type(value)
    if vt == 'nil' then
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '"}'})
    elseif vt == 'string' then
        -- Excessive escaping because the data is serialized twice.
        value = value:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')

        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"\\"', value, '\\""}'})
    elseif vt == 'number' then
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', value, '"}'})
    elseif vt == 'boolean' then
        message =
            table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', tostring(value), '"}'})
    elseif vt == 'function' then
        error('value cannot be a function')
    else -- table
        value = serpent.line(value)

        -- Less escaping than the string case as serpent provides one level of escaping.
        -- Need to escape single quotes as serpent uses double quotes for strings.
        value = value:gsub('\\', '\\\\'):gsub("'", "\\'")

        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, "\",value:'", value, "'}"})
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
        error('data_set must be a string')
    end
    if type(key) ~= 'string' then
        error('key must be a string')
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number')
    end

    -- Excessive escaping because the data is serialized twice.
    data_set = data_set:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')
    key = key:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')

    local message = table.concat {data_get_tag, callback_token, ' {', 'data_set:"', data_set, '",key:"', key, '"}'}
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
        error('data_set must be a string')
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number')
    end

    -- Excessive escaping because the data is serialized twice.
    data_set = data_set:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')

    local message = table.concat {data_get_all_tag, callback_token, ' {', 'data_set:"', data_set, '"}'}
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
                error(err)
            end
        end
    else
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
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
    if type(data_set) ~= 'string' then
        error('data_set must be a string')
    end

    local handlers = data_set_handlers[data_set]
    if handlers == nil then
        handlers = {handler}
        data_set_handlers[data_set] = handlers
    else
        table.insert(handlers, handler)
    end
end

--- Called by the web server to notify the client that a data_set has changed.
Public.raise_data_set = data_set_changed

--- Called by the web server to determine which data_sets are being tracked.
function Public.get_tracked_data_sets()
    local message = {data_tracked_tag, '['}

    for k, _ in pairs(data_set_handlers) do
        -- Excessive escaping because the data is serialized twice.
        k = k:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"')

        table.insert(message, '"')
        table.insert(message, k)
        table.insert(message, '"')
        table.insert(message, ',')
    end

    if message[#message] == ',' then
        table.remove(message)
    end

    table.insert(message, ']')

    message = table.concat(message)
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
        error('username must be a string')
    end

    if reason == nil then
        reason = ''
    elseif type(reason) ~= 'string' then
        error('reason must be a string or nil')
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil')
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

    local message =
        table.concat({ban_sync_tag, '{username:"', username, '",reason:"', reason, '",admin:"', admin, '"}'})
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
        error('username must be a string')
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil')
    end

    -- game.unban_player errors if player not found.
    -- However we may still want to use this function to unban player names.
    local player = game.players[username]
    if player then
        game.unban_player(username)
    end

    username = escape(username)
    admin = escape(admin)

    local message = table.concat({unbanned_sync_tag, '{username:"', username, '",admin:"', admin, '"}'})
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

--- Gets a table {secs:number, tick:number} with secs being the unix epoch timestamp
-- for the server time and ticks the number of game ticks it was set
-- @return table
function Public.get_time_data_raw()
    return server_time
end

--- Gets an estimate of the current server time as a unix epoch timestamp
-- The estimate may be slightly off if within the last minute the game has been paused, saving or overwise,
-- or the game speed has been changed.
-- @return number
function Public.get_current_time()
    local diff = game.tick - server_time.tick
    return server_time.secs + diff / game.speed
end

return Public
