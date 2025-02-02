-- luacheck: globals script
-- This module exists to break the circular dependency between event.lua and global.lua.
-- It is not expected that any user code would require this module instead event.lua should be required.

---@alias EventName defines.events | int

local ErrorLogging = require 'utils.error_logging'

local Public = {}

local xpcall = xpcall
local log = log
local remove_element = require 'utils.table'.remove_element

--- Constants representing special event names
local events = {
    on_init = 'on_init',
    on_load = 'on_load',
    on_configuration_changed = 'on_configuration_changed',
}

--- Tables to hold event handlers
local event_handlers = {}
local event_handlers_on_nth_tick = {}
local token_handlers = {}
local token_handlers_on_nth_tick = {}
local function_handlers = {}
local function_handlers_on_nth_tick = {}

--- Call all handlers for a given event
---@param handlers function[]
local function call_handlers_factory(handlers)
    return function(event)
        if handlers then
            for i = #handlers, 1, -1 do
                xpcall(handlers[i], ErrorLogging.generate_error_report, event)
            end
        end
    end
end

--- Register a handler for a specific event name
---@param event_name EventName
---@param handler function
---@param handlers_table function[]
---@param script_event_function function
local function register_handler(event_name, handler, handlers_table, script_event_function)
    local handlers = handlers_table[event_name]

    if not handlers then
        handlers = {}
        handlers_table[event_name] = handlers
        if events[event_name] then
            script_event_function(call_handlers_factory(handlers))
        else
            script_event_function(event_name, call_handlers_factory(handlers))
        end
    end

    table.insert(handlers, 1, handler)
end

--- Remove a handler from a specific event
---@param event_name EventName
---@param handler function
---@param handlers_table function[]
local function remove_handler(event_name, handler, handlers_table)
    local handlers = handlers_table[event_name]
    if handlers then
        remove_element(handlers, handler)  -- Remove handler from the list
        if #handlers == 0 then
            handlers_table[event_name] = nil  -- Remove the event entry if no handlers are left
        end
        return true
    end
    return false
end

--- Add a new event handler to a specified event.
--- This method allows flexible registration of a function, token, or named string handler.
--- Use an optional `options` table to customize handler registration, including setting the event to be invoked on nth ticks or specifying a token retrieval function.
---@param event_name: EventName - The name of the event to register the handler for
---@param handler: function|number|string - The function, token, or string handler to be called when the event occurs
---@param options?: table - An optional table containing options for handler registration
---@param options.on_nth_tick: boolean - If true, the event handler will be invoked on every nth tick
---@param options.get_token: function - A function that retrieves a token associated with the handler
---@param options.name: string - The name of the handler for named string handlers
Public.add = function(event_name, handler, options)
    options = options or {}
    local handler_type = type(handler)
    local on_nth_tick = options.on_nth_tick or false
    local handlers_table = on_nth_tick and event_handlers_on_nth_tick or event_handlers
    local script_event_function = on_nth_tick and script.on_nth_tick or script.on_event

    -- Case: Explicit function
    if handler_type == 'function' then
        return register_handler(event_name, handler, handlers_table, script_event_function)
    end

    -- Case: Token function
    if handler_type == 'number' and options.get_token then
        local token_handler = options.get_token(handler)

        if not token_handler then
            return error('Invalid token or handler cannot be nil.')
        end

        local tokens = on_nth_tick and token_handlers_on_nth_tick or token_handlers
        tokens[event_name] = tokens[event_name] or {}
        tokens[event_name][handler] = true

        return register_handler(event_name, token_handler, handlers_table, script_event_function)
    end

    -- Case: Named string function
    if handler_type == 'string' and options.name then
        local func_handler, err = load('return ' .. handler)()

        if not func_handler or type(func_handler) ~= 'function' then
            return error('Invalid string function: ' .. (err or 'nil'))
        end

        local functions = on_nth_tick and function_handlers_on_nth_tick or function_handlers
        functions[event_name] = functions[event_name] or {}
        functions[event_name][options.name] = handler

        return register_handler(event_name, func_handler, handlers_table, script_event_function)
    end

    return error('Handler must be a function, token, or valid string function with a name.')
end

--- Remove an existing event handler from a specified event.
--- This method allows for the removal of a handler that was registered previously using `Event.add`.
--- The handler can be specified by function reference, token, or by its assigned name.
--- Use an optional `options` table to customize the removal process, including specifying whether the handler is associated with nth tick events.
---@param event_name: EventName - The name of the event from which to remove the handler
---@param handler: function|number|string - The handler to remove, which can be a function reference, token number, or named string handler
---@param options?: table - An optional table containing options for handler removal
---@param options.on_nth_tick: boolean - If true, indicates that the handler is associated with nth tick events
Public.remove = function(event_name, handler, options)
    options = options or {}
    local handler_type = type(handler)
    local on_nth_tick = options.on_nth_tick or false
    local handlers_table = on_nth_tick and event_handlers_on_nth_tick or event_handlers

    -- Case: Token function
    if handler_type == 'number' then
        local token_handler = options.get_token and options.get_token(handler)

        if not token_handler then
            log('Token not found: ' .. handler)
            return false
        end

        local tokens = on_nth_tick and token_handlers_on_nth_tick or token_handlers
        tokens[event_name][handler] = false

        return remove_handler(event_name, token_handler, handlers_table)
    end

    -- Case: Named string handler
    if handler_type == 'string' then
        local functions = on_nth_tick and function_handlers_on_nth_tick or function_handlers
        local string_handler = functions[event_name] and functions[event_name][handler]

        if not string_handler then
            log('Handler not found: ' .. handler)
            return false
        end

        functions[event_name][handler] = nil
        local func_handler = load('return ' .. string_handler)()

        return remove_handler(event_name, func_handler, handlers_table)
    end

    -- Assume it's an explicit function
    return error('Cannot remove registered function: handler must be a token or valid function name.')
end

--- Register an init handler.
-- This will be called when script initialization occurs.
-- @param handler The function that will be called on initialization.
Public.on_init = function(handler)
    return register_handler(events.on_init, handler, event_handlers, script.on_init)
end

--- Register a load handler.
---This will be called when the script is loaded.
---@param handler The function that will be called on loading.
Public.on_load = function(handler)
    return register_handler(events.on_load, handler, event_handlers, script.on_load)
end

--- Register a configuration change handler.
---This will be called when the configuration changes.
---@param handler The function that will be called on configuration change.
Public.on_configuration_changed = function(handler)
    return register_handler(events.on_configuration_changed, handler, event_handlers, script.on_configuration_changed)
end

Public.get_handlers = function()
    return {
        token_handlers = token_handlers,
        token_handlers_on_nth_tick = token_handlers_on_nth_tick,
        function_handlers = function_handlers,
        function_handlers_on_nth_tick = function_handlers_on_nth_tick,
    }
end

Public.set_handlers = function(tbl)
    token_handlers = tbl.token_handlers
    token_handlers_on_nth_tick = tbl.token_handlers_on_nth_tick
    function_handlers = tbl.function_handlers
    function_handlers_on_nth_tick = tbl.function_handlers_on_nth_tick
end

--- Generate a new, unique event ID.
---@param name string, name of the event/variable that is exposed
Public.generate_event_name = function(name)
    local event_id = script.generate_event_name()

    -- If we're in debug, add the event ID into defines.events for the debuggertron's event module
    if _DEBUG then
        defines.events[name] = event_id -- luacheck: ignore 122
    end

    return event_id
end

return Public