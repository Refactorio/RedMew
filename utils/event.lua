local Event = {}

local debug_mode = false

local init_event_name = -1
local load_event_name = -2

local event_handlers = {}-- map of event_name to handlers[]
local on_nth_tick_event_handlers = {}-- map of nth_tick to handlers[]

local function call_handlers(handlers, event)
    if debug_mode then
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

local function on_inti()
    local handlers = event_handlers[init_event_name]
    call_handlers(handlers)
end

local function on_load()
    local handlers = event_handlers[load_event_name]
    call_handlers(handlers)
end

local function on_nth_tick_event(event)
    local handlers = on_nth_tick_event_handlers[event.nth_tick]
    call_handlers(handlers, event)
end

function Event.add(event_name, handler)
    local handlers = event_handlers[event_name]
    if not handlers then
        event_handlers[event_name] = {handler}
        script.on_event(event_name, on_event)
    else
        table.insert(handlers, handler)
    end
end

function Event.on_init(handler)
    local handlers = event_handlers[init_event_name]
    if not handlers then
        event_handlers[init_event_name] = {handler}
        script.on_init(on_inti)
    else
        table.insert(handlers, handler)
    end
end

function Event.on_load(handler)
    local handlers = event_handlers[load_event_name]
    if not handlers then
        event_handlers[load_event_name] = {handler}
        script.on_load(on_load)
    else
        table.insert(handlers, handler)
    end
end

function Event.on_nth_tick(tick, handler)
    local handlers = on_nth_tick_event_handlers[tick]
    if not handlers then
        on_nth_tick_event_handlers[tick] = {handler}
        script.on_nth_tick(tick, on_nth_tick_event)
    else
        table.insert(handlers, handler)
    end
end

return Event
