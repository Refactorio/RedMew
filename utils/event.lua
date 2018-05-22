local Event = {}

local init_event_name = -1
local load_event_name = -2

local control_stage = true

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
        script.on_init(on_init)
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

local Token = require 'utils.global_token'
global.event_tokens = {}

function Event.add_removable(event_name, token)
    local event_tokens = global.event_tokens

    local tokens = event_tokens[event_name]
    if not tokens then
        event_tokens[event_name] = {token}
    else
        table.insert(tokens, token)
    end

    if not control_stage then
        local handler = Token.get(token)
        Event.add(event_name, handler)
    end
end

local function remove(t, e)
    for i, v in ipairs(t) do
        if v == e then
            table.remove(t, i)
            break
        end
    end
end

function Event.remove_removable(event_name, token)
    local event_tokens = global.event_tokens

    local tokens = event_tokens[event_name]

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

local function add_token_handlers()
    control_stage = false

    local event_tokens = global.event_tokens

    for event_name, tokens in pairs(event_tokens) do
        for _, token in ipairs(tokens) do
            local handler = Token.get(token)
            Event.add(event_name, handler)
        end
    end
end

Event.on_init(add_token_handlers)
Event.on_load(add_token_handlers)

return Event
