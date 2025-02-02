-- luacheck: globals script
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
-- Only use this if you need to add the handler at runtime or need to remove the handler, otherwise use Event.add
--
-- Event.add_removable can be safely used at the control stage or in Event.on_init. If used in on_init you don't
-- need to also add in on_load (unlike Event.add).
-- Event.add_removable cannot be called in on_load, doing so will crash the game on loading.
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
-- removing only the first occurrence is removed.
--
-- ** Event.add_removable_function(event_name, func) **
--
-- Only use this function if you can't use Event.add_removable. i.e you are registering the handler at the console.
-- The same restrictions that apply to Event.add_removable also apply to Event.add_removable_function.
-- func cannot be a closure in this case, as there is no safe way to store closures in the global table.
-- A closure is a function that uses a local variable not defined in the function.
--
-- @usage
-- local Event = require 'utils.event'
--
-- If you want to remove the handler you will need to keep a reference to it.
-- storage.handler = function(event)
--     game.print(serpent.block(event)) -- prints the content of the event table to console.
-- end
--
-- The below code would typically be used at the command console.
-- Event.add_removable_function(defines.events.on_built_entity, storage.handler)
--
-- When you no longer need the handler.
-- Event.remove_removable_function(defines.events.on_built_entity, storage.handler)
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

Global.register(EventCore.get_handlers(), EventCore.set_handlers)

local Event = {}

Event.on_init = function(handler)
    EventCore.on_init(handler)
end

Event.on_load = function(handler)
    EventCore.on_load(handler)
end

Event.on_configuration_changed = function(handler)
    EventCore.on_configuration_changed(handler)
end

Event.add = function(event_name, handler, options)
    EventCore.add(event_name, handler, options)
end

Event.remove = function(event_name, handler, options)
    EventCore.remove(event_name, handler, options)
end

Event.on_nth_tick = function(tick, handler)
    EventCore.add(tick, handler, { on_nth_tick = true })
end

Event.add_removable = function(event_name, token, options)
    EventCore.add(event_name, token, { get_token = options and options.get_token or Token.get })
end

Event.remove_removable = function(event_name, token, options)
    EventCore.remove(event_name, token, { get_token = options and options.get_token or Token.get })
end

Event.add_removable_on_nth_tick = function(event_name, token, options)
    EventCore.add(event_name, token, { get_token = options and options.get_token or Token.get, on_nth_tick = true })
end

Event.remove_removable_on_nth_tick = function(event_name, token, options)
    EventCore.remove(event_name, token, { get_token = options and options.get_token or Token.get, on_nth_tick = true })
end

Event.add_function = function(event_name, string_function, options)
    EventCore.add(event_name, string_function, options)
end

Event.remove_function = function(event_name, name)
    EventCore.remove(event_name, name)
end

Event.add_function_on_nth_tick = function(event_name, string_function, options)
    options.on_nth_tick = true
    EventCore.add(event_name, string_function, options)
end

Event.remove_function_on_nth_tick = function(event_name, name)
    EventCore.remove(event_name, name, { on_nth_tick = true })
end

local function handler_factory(event_list)
    return function(handler, options)
        for _, event_name in pairs(event_list) do
            EventCore.add(event_name, handler, options)
        end
    end
end

Event.on_built = handler_factory {
    defines.events.on_biter_base_built,
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.on_space_platform_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
    defines.events.on_entity_cloned,
}
Event.on_destroyed = handler_factory {
    defines.events.on_entity_died,
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_space_platform_mined_entity,
    defines.events.script_raised_destroy,
}
Event.on_built_tile = handler_factory {
    defines.events.on_player_built_tile,
    defines.events.on_robot_built_tile,
    defines.events.on_space_platform_built_tile,
}
Event.on_mined_tile = handler_factory {
    defines.events.on_player_mined_tile,
    defines.events.on_robot_mined_tile,
    defines.events.on_space_platform_mined_tile,
}

Event.generate_event_name = function(name)
    return EventCore.generate_event_name(name)
end

local function register_events()
    local handlers = EventCore.get_handlers()

    for event_name, tokens in pairs(handlers.token_handlers) do
        for _, token in pairs(tokens) do
            local handler = Token.get(token)
            EventCore.add(event_name, handler)
        end
    end

    for tick, tokens in pairs(handlers.token_handlers_on_nth_tick) do
        for _, token in pairs(tokens) do
            local handler = Token.get(token)
            EventCore.add(tick, handler, { on_nth_tick = true })
        end
    end

    for event_name, string_handlers in pairs(handlers.function_handlers) do
        for _, string_handler in pairs(string_handlers) do
            local handler = load('return ' .. string_handler)()
            EventCore.add(event_name, handler)
        end
    end

    for tick, string_handlers in pairs(handlers.function_handlers_on_nth_tick) do
        for _, string_handler in pairs(string_handlers) do
            local handler = load('return ' .. string_handler)()
            EventCore.add(tick, handler, { on_nth_tick = true })
        end
    end
end

EventCore.on_init(register_events)
EventCore.on_load(register_events)

return Event
