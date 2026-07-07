-- luacheck: globals script
-- This module exists to break the circular dependency between event.lua and storage.lua.
-- It is not expected that any user code would require this module instead event.lua should be required.
local ErrorLogging = require 'utils.error_logging'

local Public = {}

local init_event_name = -1
local load_event_name = -2
local configuration_changed_name = -3

-- map of event_name to handlers[]
local event_handlers = {}
-- map of nth_tick to handlers[]
local on_nth_tick_event_handlers = {}

local xpcall = xpcall
local log = log
local script_on_event = script.on_event
local script_on_nth_tick = script.on_nth_tick
local error_handler = ErrorLogging.error_handler

local call_handlers
local log_handler_registration
if _DEBUG then
    function call_handlers(handlers, event)
        for i = #handlers, 1, -1 do
            local handler = handlers[i]
            handler(event)
        end
    end

    -- map of event key string (e.g. "on_player_created") to registered handler count
    local handler_counts = {}
    -- map of event_name id to its key string, seeded with the non-defines.events pseudo events
    local event_id_to_key = {
        [init_event_name] = 'on_init',
        [load_event_name] = 'on_load',
        [configuration_changed_name] = 'on_configuration_changed'
    }

    local function get_event_key(event_name)
        if type(event_name) == 'string' then
            return event_name
        end

        local key = event_id_to_key[event_name]
        if key then
            return key
        end

        for name, id in pairs(defines.events) do
            if id == event_name then
                event_id_to_key[event_name] = name
                return name
            end
        end

        key = 'unknown_event_' .. tostring(event_name)
        event_id_to_key[event_name] = key
        return key
    end

    function log_handler_registration(event_name, count)
        local key = get_event_key(event_name)
        handler_counts[key] = count
        helpers.write_file('event_handler_registry.json', helpers.table_to_json(handler_counts), false)
    end
else
    function call_handlers(handlers, event)
        for i = #handlers, 1, -1 do
            local handler = handlers[i]
            local success, result = xpcall(handler, error_handler, event)

            if not success then
                log(result)
            end
        end
    end
end

local function on_event(event)
    local handlers = event_handlers[event.name]
    call_handlers(handlers, event)
end

local function on_init()
    _LIFECYCLE = 5 -- on_init
    local handlers = event_handlers[init_event_name]
    call_handlers(handlers)

    event_handlers[init_event_name] = nil
    event_handlers[load_event_name] = nil

    _LIFECYCLE = 8 -- Runtime
end

local function on_load()
    _LIFECYCLE = 6 -- on_load
    local handlers = event_handlers[load_event_name]
    call_handlers(handlers)

    event_handlers[init_event_name] = nil
    event_handlers[load_event_name] = nil

    _LIFECYCLE = 8 -- Runtime
end

local function configuration_changed()
    _LIFECYCLE = 7 -- config_change
    local handlers = event_handlers[configuration_changed_name]
    call_handlers(handlers)

    event_handlers[configuration_changed_name] = nil

    _LIFECYCLE = 8 -- Runtime
end

local function on_nth_tick_event(event)
    local handlers = on_nth_tick_event_handlers[event.nth_tick]
    call_handlers(handlers, event)
end

--- Do not use this function, use Event.add instead as it has safety checks.
function Public.add(event_name, handler)
    local handlers = event_handlers[event_name]
    if not handlers then
        event_handlers[event_name] = {handler}
        script_on_event(event_name, on_event)
    else
        table.insert(handlers, 1, handler)
        if #handlers == 1 then
            script_on_event(event_name, on_event)
        end
    end

    if _DEBUG then
        log_handler_registration(event_name, #event_handlers[event_name])
    end
end

--- Do not use this function, use Event.on_init instead as it has safety checks.
function Public.on_init(handler)
    local handlers = event_handlers[init_event_name]
    if not handlers then
        event_handlers[init_event_name] = {handler}
        script.on_init(on_init)
    else
        table.insert(handlers, 1, handler)
        if #handlers == 1 then
            script.on_init(on_init)
        end
    end

    if _DEBUG then
        log_handler_registration(init_event_name, #event_handlers[init_event_name])
    end
end

--- Do not use this function, use Event.on_load instead as it has safety checks.
function Public.on_load(handler)
    local handlers = event_handlers[load_event_name]
    if not handlers then
        event_handlers[load_event_name] = {handler}
        script.on_load(on_load)
    else
        table.insert(handlers, 1, handler)
        if #handlers == 1 then
            script.on_load(on_load)
        end
    end

    if _DEBUG then
        log_handler_registration(load_event_name, #event_handlers[load_event_name])
    end
end

--- Do not use this function, use Event.on_configuration_changed instead as it has safety checks.
function Public.on_configuration_changed(handler)
    local handlers = event_handlers[configuration_changed_name]
    if not handlers then
        event_handlers[configuration_changed_name] = {handler}
        script.on_configuration_changed(configuration_changed)
    else
        table.insert(handlers, 1, handler)
        if #handlers == 1 then
            script.on_configuration_changed(configuration_changed)
        end
    end

    if _DEBUG then
        log_handler_registration(configuration_changed_name, #event_handlers[configuration_changed_name])
    end
end

--- Do not use this function, use Event.on_nth_tick instead as it has safety checks.
function Public.on_nth_tick(tick, handler)
    local handlers = on_nth_tick_event_handlers[tick]
    if not handlers then
        on_nth_tick_event_handlers[tick] = {handler}
        script_on_nth_tick(tick, on_nth_tick_event)
    else
        table.insert(handlers, 1, handler)
        if #handlers == 1 then
            script_on_nth_tick(tick, on_nth_tick_event)
        end
    end

    if _DEBUG then
        log_handler_registration('on_nth_tick_' .. tick, #on_nth_tick_event_handlers[tick])
    end
end

function Public.get_event_handlers()
    return event_handlers
end

function Public.get_on_nth_tick_event_handlers()
    return on_nth_tick_event_handlers
end

Public.on_event = on_event

return Public
