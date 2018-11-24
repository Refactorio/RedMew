local Token = require 'utils.global_token'
local Event = require 'utils.event'

local Public = {}

local raw_print = print
function print(str)
    raw_print('[PRINT] ' .. str)
end

local discord_tag = '[DISCORD]'
local discord_raw_tag = '[DISCORD-RAW]'
local discord_bold_tag = '[DISCORD-BOLD]'
local discord_admin_tag = '[DISCORD-ADMIN]'
local discord_admin_raw_tag = '[DISCORD-ADMIN-RAW]'
local discord_embed_tag = '[DISCORD-EMBED]'
local discord_embed_raw_tag = '[DISCORD-EMBED-RAW]'
local discord_admin_embed_tag = '[DISCORD-ADMIN-EMBED]'
local discord_admin_embed_raw_tag = '[DISCORD-ADMIN-EMBED-RAW]'
local regular_promote_tag = '[REGULAR-PROMOTE]'
local regular_deomote_tag = '[REGULAR-DEOMOTE]'
local donator_set_tag = '[DONATOR-SET]'
local start_scenario_tag = '[START-SCENARIO]'
local ping_tag = '[PING]'
local data_set_tag = '[DATA-SET]'
local data_get_tag = '[DATA-GET]'
local data_get_all_tag = '[DATA-GET-ALL]'
local data_tracked_tag = '[DATA-TRACKED]'

Public.raw_print = raw_print

local data_set_handlers = {}

defines.events.on_server_started = script.generate_event_name()

Public.events = {on_server_started = defines.events.on_server_started}

function Public.to_discord(message)
    raw_print(discord_tag .. message)
end

function Public.to_discord_raw(message)
    raw_print(discord_raw_tag .. message)
end

function Public.to_discord_bold(message)
    raw_print(discord_bold_tag .. message)
end

function Public.to_admin(message)
    raw_print(discord_admin_tag .. message)
end

function Public.to_admin_raw(message)
    raw_print(discord_admin_raw_tag .. message)
end

function Public.to_discord_embed(message)
    raw_print(discord_embed_tag .. message)
end

function Public.to_discord_embed_raw(message)
    raw_print(discord_embed_raw_tag .. message)
end

function Public.to_admin_embed(message)
    raw_print(discord_admin_embed_tag .. message)
end

function Public.to_admin_embed_raw(message)
    raw_print(discord_admin_embed_raw_tag .. message)
end

function Public.regular_promote(target, promotor)
    local control_message = table.concat {regular_promote_tag, target, ' ', promotor}
    local discord_message = table.concat {discord_bold_tag, promotor .. ' promoted ' .. target .. ' to regular.'}

    raw_print(control_message)
    raw_print(discord_message)
end

function Public.regular_deomote(target, demotor)
    local discord_message = table.concat {discord_bold_tag, target, ' was demoted from regular by ', demotor, '.'}

    raw_print(regular_deomote_tag .. target)
    raw_print(discord_message)
end

function Public.donator_set(target, perks)
    perks = perks or 'nil'

    local message = table.concat {donator_set_tag, target, ' ', perks}

    raw_print(message)
end

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

function Public.ping(func_token)
    local message = table.concat({ping_tag, func_token or default_ping_token, ' ', game.tick})
    raw_print(message)
end

function Public.set_data(data_set, key, value)
    if type(data_set) ~= 'string' then
        error('data_set must be a string')
    end
    if type(key) ~= 'string' then
        error('key must be a string')
    end

    local message
    local vt = type(value)
    if vt == 'nil' then
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '"}'})
    elseif vt == 'string' then
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"\\"', value, '\\""}'})
    elseif vt == 'number' or vt == 'boolean' then
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', value, '"}'})
    elseif vt == 'function' then
        error('value cannot be a function')
    else
        value = serpent.line(value)
        message = table.concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', value, '"}'})
    end

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

Public.raise_data_set = data_set_changed

function Public.get_tracked_data_sets()
    local message = {data_tracked_tag, '['}

    for k, _ in pairs(data_set_handlers) do
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
    game.print(message)
end

return Public
