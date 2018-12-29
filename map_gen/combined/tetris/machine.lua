local Module = {}

local Global = require 'utils.global'
local Debug = require 'utils.debug'

local states = require 'map_gen.combined.tetris.states'

local primitives = {
    state = states.voting,
    stack_depth = 0,
    last = -1,
}

Global.register(
    {
        primitives = primitives,
    },
    function(tbl)
        primitives = tbl.primitives
    end
)

local actions = {}
local transaction_callbacks = {}
local max_stack_depth = 20

function Module.transition(new_state)
    local old_state = primitives.state

    if _DEBUG then
        local old_state_name = ''
        local new_state_name = ''
        for name, state in pairs(states) do
            if state == new_state then
                new_state_name = name
            end
            if state == old_state then
                old_state_name = name
            end
        end
        Debug.print(string.format('Transitioning from state %s to state %s.', old_state_name, new_state_name))
    end

    local stack_depth = primitives.stack_depth
    primitives.stack_depth = stack_depth + 1
    if stack_depth > max_stack_depth then
        if _DEBUG then
            error('[WARNING] Stack overflow at:' .. debug.traceback())
        else
            log('[WARNING] Stack overflow at:' .. debug.traceback())
        end
    end

    local callbacks = transaction_callbacks[old_state]
    if callbacks then
        local callback = callbacks[new_state]
        primitives.last = new_state
        if callback then
            callback()
        end
    end

    primitives.state = new_state
end

function Module.is_in(state) --Keyword 'in' is illegal in lua :(
   return primitives.state == state
end

function Module.tick()
    local action = actions[primitives.state]
    if action then
        action()
    end

    primitives.stack_depth = 0
end

function Module.register_state_tick_action(state, action)
    actions[state] = action
end

function Module.register_transition(old, new, callback)
    transaction_callbacks[old] = transaction_callbacks[old] or {}
    transaction_callbacks[old][new] = callback
end

return Module