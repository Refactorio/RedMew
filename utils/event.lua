local EventCore = require 'utils.event_core'
local Global = require 'utils.global'
local Token = require 'utils.token'

local table_remove = table.remove
local core_add = EventCore.add
local core_on_init = EventCore.on_init
local core_on_load = EventCore.on_load
local core_on_nth_tick = EventCore.on_nth_tick

local Event = {}

local event_handlers = EventCore.get_event_handlers()
local on_nth_tick_event_handlers = EventCore.get_on_nth_tick_event_handlers()

local token_handlers = {}
local token_nth_tick_handlers = {}
local function_handlers = {}
local function_nth_tick_handlers = {}

Global.register(
    {
        token_handlers = token_handlers,
        token_nth_tick_handlers = token_nth_tick_handlers,
        function_handlers = function_handlers,
        function_nth_tick_handlers = function_nth_tick_handlers
    },
    function(tbl)
        token_handlers = tbl.token_handlers
        token_nth_tick_handlers = tbl.token_nth_tick_handlers
        function_handlers = tbl.function_handlers
        function_nth_tick_handlers = tbl.function_nth_tick_handlers
    end
)

local function remove(tbl, handler)
    -- the handler we are looking for is more likly to be at the back of the array.
    for i = #tbl, 1, -1 do
        if tbl[i] == handler then
            table_remove(tbl, i)
            break
        end
    end
end

function Event.add(event_name, handler)
    if EventCore.runtime then
        error('Calling Event.add after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_add(event_name, handler)
end

function Event.on_init(handler)
    if EventCore.runtime then
        error('Calling Event.on_init after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_init(handler)
end

function Event.on_load(handler)
    if EventCore.runtime then
        error('Calling Event.on_load after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_load(handler)
end

function Event.on_nth_tick(tick, handler)
    if EventCore.runtime then
        error('Calling Event.on_nth_tick after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_nth_tick(tick, handler)
end

function Event.add_removable(event_name, token)
    local tokens = token_handlers[event_name]
    if not tokens then
        token_handlers[event_name] = {token}
    else
        tokens[#tokens + 1] = token
    end

    -- If this is called before runtime, we don't need to add the handlers
    -- as they will be added later either in on_init or on_load.
    if EventCore.runtime then
        local handler = Token.get(token)
        core_add(event_name, handler)
    end
end

function Event.remove_removable(event_name, token)
    local tokens = token_handlers[event_name]

    if not tokens then
        return
    end

    local handler = Token.get(token)
    local handlers = event_handlers[event_name]

    remove(tokens, token)
    remove(handlers, handler)

    if #handlers == 0 then
        script.on_event(event_name, nil)
    end
end

function Event.add_removable_function(event_name, func)
    local funcs = function_handlers[event_name]
    if not funcs then
        function_handlers[event_name] = {func}
    else
        funcs[#funcs + 1] = func
    end

    -- If this is called before runtime, we don't need to add the handlers
    -- as they will be added later either in on_init or on_load.
    if EventCore.runtime then
        local handler = Token.get(func)
        core_add(event_name, handler)
    end
end

function Event.remove_removable_function(event_name, func)
    local funcs = function_handlers[event_name]

    if not funcs then
        return
    end

    local handlers = event_handlers[event_name]

    remove(funcs, func)
    remove(handlers, func)

    if #handlers == 0 then
        script.on_event(event_name, nil)
    end
end

function Event.add_removable_nth_tick(tick, token)
    local tokens = token_nth_tick_handlers[tick]
    if not tokens then
        token_nth_tick_handlers[tick] = {token}
    else
        tokens[#tokens + 1] = token
    end

    -- If this is called before runtime, we don't need to add the handlers
    -- as they will be added later either in on_init or on_load.
    if EventCore.runtime then
        local handler = Token.get(token)
        core_on_nth_tick(tick, handler)
    end
end

function Event.remove_removable_nth_tick(tick, token)
    local tokens = token_nth_tick_handlers[tick]

    if not tokens then
        return
    end

    local handler = Token.get(token)
    local handlers = on_nth_tick_event_handlers[tick]

    remove(tokens, token)
    remove(handlers, handler)

    if #handlers == 0 then
        script.on_nth_tick(tick, nil)
    end
end

function Event.add_removable_nth_tick_function(tick, func)
    local funcs = function_nth_tick_handlers[tick]
    if not funcs then
        function_nth_tick_handlers[tick] = {func}
    else
        funcs[#funcs + 1] = func
    end

    -- If this is called before runtime, we don't need to add the handlers
    -- as they will be added later either in on_init or on_load.
    if EventCore.runtime then
        core_on_nth_tick(tick, func)
    end
end

function Event.remove_removable_nth_tick_function(tick, func)
    local funcs = function_nth_tick_handlers[tick]

    if not funcs then
        return
    end

    local handlers = on_nth_tick_event_handlers[tick]

    remove(funcs, func)
    remove(handlers, func)

    if #handlers == 0 then
        script.on_nth_tick(tick, nil)
    end
end

local function add_handlers()
    for event_name, tokens in pairs(token_handlers) do
        for i = 1, #tokens do
            local handler = Token.get(tokens[i])
            core_add(event_name, handler)
        end
    end

    for event_name, funcs in pairs(function_handlers) do
        for i = 1, #funcs do
            local handler = funcs[i]
            core_add(event_name, handler)
        end
    end

    for tick, tokens in pairs(token_nth_tick_handlers) do
        for i = 1, #tokens do
            local handler = Token.get(tokens[i])
            core_on_nth_tick(tick, handler)
        end
    end

    for tick, funcs in pairs(function_nth_tick_handlers) do
        for i = 1, #funcs do
            local handler = funcs[i]
            core_on_nth_tick(tick, handler)
        end
    end
end

core_on_init(add_handlers)
core_on_load(add_handlers)

return Event
