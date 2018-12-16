-- This module exists to break the circular dependency between event.lua and global.lua.
-- It is not expected that any user code would require this module instead event.lua should be required.

local Public = {}

local init_event_name = -1
local load_event_name = -2

Public.runtime = false

-- map of event_name to handlers[]
local event_handlers = {}
-- map of nth_tick to handlers[]
local on_nth_tick_event_handlers = {}

local function call_handlers(handlers, event)
    if _DEBUG then
        for _, handler in ipairs(handlers) do
            handler(event)
        end
    else
        for _, handler in ipairs(handlers) do
            local success, error = pcall(handler, event)
            if not success then
                log(error)
            end
        end
    end
end

local function on_event(event)
    local handlers = event_handlers[event.name]
    call_handlers(handlers, event)
end

local function on_init()
    local handlers = event_handlers[init_event_name]
    call_handlers(handlers)

    Public.runtime = true
end

local function on_load()
    local handlers = event_handlers[load_event_name]
    call_handlers(handlers)

    Public.runtime = true
end

local function on_nth_tick_event(event)
    local handlers = on_nth_tick_event_handlers[event.nth_tick]
    call_handlers(handlers, event)
end

function Public.add(event_name, handler)
    local handlers = event_handlers[event_name]
    if not handlers then
        event_handlers[event_name] = {handler}
        script.on_event(event_name, on_event)
    else
        table.insert(handlers, handler)
    end
end

function Public.on_init(handler)
    local handlers = event_handlers[init_event_name]
    if not handlers then
        event_handlers[init_event_name] = {handler}
        script.on_init(on_init)
    else
        table.insert(handlers, handler)
    end
end

function Public.on_load(handler)
    local handlers = event_handlers[load_event_name]
    if not handlers then
        event_handlers[load_event_name] = {handler}
        script.on_load(on_load)
    else
        table.insert(handlers, handler)
    end
end

function Public.on_nth_tick(tick, handler)
    local handlers = on_nth_tick_event_handlers[tick]
    if not handlers then
        on_nth_tick_event_handlers[tick] = {handler}
        script.on_nth_tick(tick, on_nth_tick_event)
    else
        table.insert(handlers, handler)
    end
end

function Public.get_event_handlers()
    return event_handlers
end

function Public.get_on_nth_tick_event_handlers()
    return on_nth_tick_event_handlers
end

return Public
