local Event = {}

local events = {}
local handlers = {}
global.handler_next_id = 1

local function get_handler_id(handler)
    local id = handlers[handler]
    if id then
        return id
    else
        id = global.handler_next_id
        handlers[id] = handler
        
        global.handler_next_id = id + 1
        return id
    end
end

local function add(event_id, handler)
    local handler_id = get_handler_id(handler)
    
    local handlers = events[event_id]
    if not handlers then
        handlers = {}
        events[event_id] = handlers
        script.on_event(event_id, on_event)
    end
    
    table.insert(handlers, handler_id)
end

local function remove(event_id, handler)
    local handler_id = get_handler_id(handler)
   
    local handlers = events[event_id]
    if not handlers then
        return
    end

    table.remove_element(handlers, handler_id)


end


return Event
