--- This Module allows for registering multiple handlers to the same event, overcoming the limitation of script.register.
--
-- ** Event.add(event_name, handler) **
--
-- Handlers added with Event.add must be added at the control stage or in Event.on_init or Event.on_load.
-- Remember that for each player, on_init or on_load is run, never both. So if you can't add the handler in the
-- control stage add the handler in both on_init and on_load.
-- Handlers added with Event.add cannot be removed.
-- For handlers that need to be removed or added at runtime use Event.add_removable.
-- @usage
-- local Event = require 'utils.event'
-- Event.add(
--     defines.events.on_built_entity,
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- ** Event.add_removable(event_name, token) **
--
-- For conditional event handlers. Event.add_removable can be safely called at runtime without desync risk.
-- Only use this if you need to add the handler at runtime or need to remove the handler, other wise use Event.add
-- Token is used because it's a desync risk to store closures inside the global table.
--
-- @usage
-- local Token = require 'utils.token'
-- local Event = require 'utils.event'
--
-- Token.register must not be called inside an event handler.
-- local handler =
--     Token.register(
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- The below code would typically be inside another event or a custom command.
-- Event.add_removable(defines.events.on_built_entity, handler)
--
-- When you no longer need the handler.
-- Event.remove_removable(defines.events.on_built_entity, handler)
--
-- It's not an error to register the same token multiple times to the same event, however when
-- removing only the first occurance is removed.
--
-- ** Event.add_removable_function(event_name, func) **
--
-- Only use this function if you can't use Event.add_removable. i.e you are registering the handler at the console.
-- func cannot be a closure in this case, as there is no safe way to store closures in the global table.
-- A closure is a function that uses a local variable not defined in the function.
--
-- @usage
-- local Event = require 'utils.event'
--
-- If you want to remove the handler you will need to keep a reference to it.
-- global.handler = function(event)
--     game.print(serpent.block(event)) -- prints the content of the event table to console.
-- end
--
-- The below code would typically be used at the command console.
-- Event.add_removable_function(defines.events.on_built_entity, global.handler)
--
-- When you no longer need the handler.
-- Event.remove_removable_function(defines.events.on_built_entity, global.handler)
--
-- ** Other Events **
--
-- Use Event.on_init(handler) for script.on_init(handler)
-- Use Event.on_load(handler) for script.on_load(handler)
--
-- Use Event.on_nth_tick(tick, handler) for script.on_nth_tick(tick, handler)
-- Favour this event over Event.add(defines.events.on_tick, handler)
-- There are also Event.add_removable_nth_tick(tick, token) and Event.add_removable_nth_tick_function(tick, func)
-- That work the same as above.
--
-- ** Custom Scenario Events **
--
-- local Event = require 'utils.event'
--
-- local event_id = script.generate_event_name()
--
-- Event.add(
--     event_id,
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- The table contains extra information that you want to pass to the handler.
-- script.raise_event(event_id, {extra = 'data'})

local EventCore = require 'utils.event_core'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Debug = require 'utils.debug'

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

--- Register a handler for the event_name event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load.
-- See documentation at top of file for details on using events.
-- @param event_name<number>
-- @param handler<function>
function Event.add(event_name, handler)
    if EventCore.runtime then
        error('Calling Event.add after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_add(event_name, handler)
end

--- Register a handler for the script.on_init event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load
-- See documentation at top of file for details on using events.
-- @param handler<function>
function Event.on_init(handler)
    if EventCore.runtime then
        error('Calling Event.on_init after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_init(handler)
end

--- Register a handler for the script.on_load event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load
-- See documentation at top of file for details on using events.
-- @param handler<function>
function Event.on_load(handler)
    if EventCore.runtime then
        error('Calling Event.on_load after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_load(handler)
end

--- Register a handler for the nth_tick event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load.
-- See documentation at top of file for details on using events.
-- @param tick<number> The handler will be called every nth tick
-- @param handler<function>
function Event.on_nth_tick(tick, handler)
    if EventCore.runtime then
        error('Calling Event.on_nth_tick after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_nth_tick(tick, handler)
end

--- Register a token handler that can be safely added and removed at runtime.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
function Event.add_removable(event_name, token)
    if type(token) ~= 'number' then
        error('token must be a number', 2)
    end

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

--- Removes a token handler for the given event_name.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
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

--- Register a handler that can be safely added and removed at runtime.
-- The handler must not be a closure, as that is a desync risk.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  func<function>
function Event.add_removable_function(event_name, func)
    if type(func) ~= 'function' then
        error('func must be a function', 2)
    end

    if Debug.is_closure(func) then
        error(
            'func cannot be a closure as that is a desync risk. Consider using Event.add_removable(event_name, token) instead.',
            2
        )
    end

    local funcs = function_handlers[event_name]
    if not funcs then
        function_handlers[event_name] = {func}
    else
        funcs[#funcs + 1] = func
    end

    -- If this is called before runtime, we don't need to add the handlers
    -- as they will be added later either in on_init or on_load.
    if EventCore.runtime then
        core_add(event_name, func)
    end
end

--- Removes a handler for the given event_name.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  func<function>
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

--- Register a token handler for the nth tick that can be safely added and removed at runtime.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
function Event.add_removable_nth_tick(tick, token)
    if type(token) ~= 'number' then
        error('token must be a number', 2)
    end

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

--- Removes a token handler for the nth tick.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
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

--- Register a handler for the nth tick that can be safely added and removed at runtime.
-- The handler must not be a closure, as that is a desync risk.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  func<function>
function Event.add_removable_nth_tick_function(tick, func)
    if type(func) ~= 'function' then
        error('func must be a function', 2)
    end

    if Debug.is_closure(func) then
        error(
            'func cannot be a closure as that is a desync risk. Consider using Event.add_removable_nth_tick(tick, token) instead.',
            2
        )
    end

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

--- Removes a handler for the nth tick.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  func<function>
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
