local Module = {}

local Debug = require 'utils.debug'
local states = require 'map_gen.combined.tetris.states'

local in_state_callbacks = {}
local transaction_callbacks = {}
local max_stack_depth = 20
local machine_count = 0

--- Transitions the supplied machine into a given state and executes all transaction_callbacks
-- @param self StateMachine
-- @param new_state number/string The new state to transition to
function Module.transition(self, new_state)
    Debug.print(string.format('Transitioning from state %d to state %d.', self.state, new_state), true)
    local old_state = self.state

    local stack_depth = self.stack_depth
    self.stack_depth = stack_depth + 1
    if stack_depth > max_stack_depth then
        if _DEBUG then
            error('[WARNING] Stack overflow at:' .. debug.traceback())
        else
            log('[WARNING] Stack overflow at:' .. debug.traceback())
        end
    end

    local exit_callbacks = transaction_callbacks[self.id][old_state]
    if exit_callbacks then
        for i = 1, #exit_callbacks do
            local callbacks = exit_callbacks[i]
            if callback then
                callback()
            end
        end
    end
    self.state = new_state
end

--- Is this machine in this state?
-- @param self StateMachine
-- @param state number/string
-- @return boolean
function Module.in_state(self, state)
   return self.state == state
end

--- Invoke a machine tick. Will execute all in_state_callbacks of the given machine
-- @param self StateMachine the machine, whose handlers will be invoked
function Module.machine_tick(self)
    local callbacks = in_state_callbacks[self.id][self.state]
    if callbacks then
        for i=1, #callbacks do
            local callback = callbacks[i]
            if callback then
                callback()
            end
        end
    end
    self.stack_depth = 0
end

--- Register a handler that will be invoked by StateMachine.machine_tick
-- NOTICE: This function will invoke an error if called after init. Dynamic machine changes are currently unsupported
-- @param self StateMachine the machine
-- @param state number/string The state, that the machine will be in, when callback is invoked
-- @param callback function
function Module.register_state_tick_callback(self, state, callback)
    if game then
        error('StateMachine.register_state_tick_callback after on_init() is unsupported due to desyncs.', 2)
    end
    in_state_callbacks[self.id][state] = in_state_callbacks[self.id][state] or {}
    table.insert(in_state_callbacks[self.id][state], callback)
end

--- Register a handler that will be invoked by StateMachine.transition
-- NOTICE: This function will invoke an error if called after init. Dynamic machine changes are currently unsupported
-- @param self StateMachine the machine
-- @param state number/string exiting state
-- @param state number/string entering state
-- @param callback function
function Module.register_transition_callback(self, old, new, callback)
    if game then
        error('StateMachine.register_transition after on_init() is unsupported due to desyncs.', 2)
    end
    transaction_callbacks[self.id][old] = transaction_callbacks[self.id][old] or {}
    transaction_callbacks[self.id][old][new] = transaction_callbacks[self.id][old][new] or {}
    table.insert(transaction_callbacks[self.id][old][new], callback)
end

--- Constructs a new state machine
-- @param init_state number/string The starting state of the machine
-- @return StateMachine The constructed state machine object
function Module.new(init_state)
    if game then
        error('StateMachine.register_transition after on_init() is unsupported due to desyncs.', 2)
    end
    machine_count = machine_count + 1
    in_state_callbacks[machine_count] = {}
    transaction_callbacks[machine_count] = {}
    return {
        state = init_state,
        stack_depth = 0,
        id = machine_count,
    }
end

return Module