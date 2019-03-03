-- dependencies
local Global = require 'utils.global'
local Event = require 'utils.event'
local raise_event = script.raise_event
local ceil = math.ceil
local max = math.max
local floor = math.floor
local format = string.format

-- this, things that can be done run-time
local ForceControl = {}
ForceControl.events = {
    --- triggered when the force levels up
    --- uses event = {level_reached = number, force = LuaForce}
    on_level_up = Event.generate_event_name('on_level_up')
}

-- the builder, can only be accessed through ForceControl.register() and should be avoided used run-time
local ForceControlBuilder = {}

-- all force data being monitored
local forces = {}

-- the function that calculates the experience to next level
local calculate_next_level_cap = nil

Global.register(
    {
        forces = forces,
    },
    function(tbl)
        forces = tbl.forces
    end
)

---Asserts if a given variable is of the expected type using type().
---
---@param expected_type string
---@param given any
---@param variable_reference_message string displayed when the expectation is not met
local function assert_type(expected_type, given, variable_reference_message)
    local given_type = type(given)
    if given_type ~= expected_type then
        error('Argument ' .. variable_reference_message .. " must be of type '" .. expected_type .. "', given '" .. given_type .. "'")
    end
end

---Returns a valid force based on the lua force or name given.
---@param lua_force_or_name LuaForce|string
local function get_valid_force(lua_force_or_name)
    if not lua_force_or_name then
        return
    end

    if type(lua_force_or_name) == 'string' then
        local force = game.forces[lua_force_or_name]
        if not force or not force.valid then
            return
        end

        return force
    end

    if type(lua_force_or_name) ~= 'table' or not lua_force_or_name.valid or nil == lua_force_or_name.evolution_factor then
        return
    end

    return lua_force_or_name
end

---Register a reward that checks if a reward should be given if the level
---matches the callback. If so, it will apply the if_level_criteria_matches
---callback.
---
---@param level_matches function function(number level_reached)
---@param callback function function(number level_reached, LuaForce force)
---@param lua_force_name string|nil only register for this force (optional)
function ForceControlBuilder.register(level_matches, callback, lua_force_name)
    if _LIFECYCLE > _STAGE.control then
        error('You can only register level up callbacks before the game is initialized')
    end
    assert_type('function', level_matches, 'level_matches of function ForceControl.register_reward')
    assert_type('function', callback, 'callback of function ForceControlBuilder.register')

    local function on_level_up(event)
        local level = event.level_reached
        if level_matches(level, event.force) then
            callback(level, event.force)
        end
    end

    if not lua_force_name then
        Event.add(ForceControl.events.on_level_up, on_level_up)
        return
    end

    Event.add(
        ForceControl.events.on_level_up,
        function(event)
            local force = get_valid_force(lua_force_name)
            if not force then
                error('Can only register a lua force name for ForceControlBuilder.register')
            end
            if force ~= event.force then
                return
            end

            on_level_up(event)
        end
    )
end

---Register a reward which triggers when the given level is reached.
---
---@param level number
---@param callback function function(number level_reached, LuaForce force)
---@param lua_force_name string|nil only register for this force (optional)
function ForceControlBuilder.register_on_single_level(level, callback, lua_force_name)
    assert_type('number', level, 'level of function ForceControl.register_reward_on_single_level')
    assert_type('function', callback, 'callback of function ForceControlBuilder.register_on_single_level')

    ForceControlBuilder.register(function(level_reached)
        return level == level_reached
    end, callback, lua_force_name)
end

---Always returns true
local function always_true()
    return true
end

---Register a reward that triggers for every level.
---
---@param callback function function(number level_reached, LuaForce force)
---@param lua_force_name string|nil only register for this force (optional)
function ForceControlBuilder.register_on_every_level(callback, lua_force_name)
    assert_type('function', callback, 'callback of function ForceControlBuilder.register_on_every_level')

    ForceControlBuilder.register(always_true, callback, lua_force_name)
end

---Register the config and initialize the feature.
---@param level_up_formula function
function ForceControl.register(level_up_formula)
    if calculate_next_level_cap then
        error('Can only register one force control.')
    end

    calculate_next_level_cap = level_up_formula

    return ForceControlBuilder
end

---Registers a new force to participate.
---@param lua_force_or_name LuaForce|string
function ForceControl.register_force(lua_force_or_name)
    if not calculate_next_level_cap then
        error('Can only register a force when the config has been initialized via ForceControl.register(config_table).')
    end
    local force = get_valid_force(lua_force_or_name)
    if not force then
        error('Can only register a LuaForce for ForceControl')
    end

    forces[force.name] = {
        current_experience = 0,
        total_experience = 0,
        current_level = 0,
        experience_level_up_cap = calculate_next_level_cap(0)
    }
end

---Returns the ForceControlBuilder.
function ForceControl.get_force_control_builder()
    if not calculate_next_level_cap then
        error('Can only get the force control builder when the config has been initialized via ForceControl.register(config_table).')
    end

    return ForceControlBuilder
end

---Removes experience from a force. Won't cause de-level nor go below 0.
---@param lua_force_or_name LuaForce|string
---@param experience number amount of experience to remove
---@return number the experience being removed
function ForceControl.remove_experience(lua_force_or_name, experience)
    assert_type('number', experience, 'Argument experience of function ForceControl.remove_experience')

    if experience < 1 then
        return
    end
    local force = get_valid_force(lua_force_or_name)
    if not force then
        return
    end
    local force_config = forces[force.name]
    if not force_config then
        return
    end
    local backup_current_experience = force_config.current_experience
    force_config.current_experience = max(0, force_config.current_experience - experience)
    force_config.total_experience = (force_config.current_experience == 0) and force_config.total_experience - backup_current_experience or max(0, force_config.total_experience - experience)
    return  backup_current_experience - force_config.current_experience
end

---Removes experience from a force, based on a percentage of the total obtained experience
---@param lua_force_or_name LuaForce|string
---@param percentage number percentage of total obtained experience to remove
---@param min_experience number minimum amount of experience to remove (optional)
---@return number the experience being removed
---@see ForceControl.remove_experience
function ForceControl.remove_experience_percentage(lua_force_or_name, percentage, min_experience)
    min_experience = min_experience ~= nil and min_experience or 0
    local force = get_valid_force(lua_force_or_name)
    if not force then
        return
    end
    local force_config = forces[force.name]
    if not force_config then
        return
    end

    local penalty = force_config.total_experience * percentage
    penalty = (penalty >= min_experience) and ceil(penalty) or ceil(min_experience)
    return ForceControl.remove_experience(lua_force_or_name, penalty)
end

---Adds experience to a force.
---@param lua_force_or_name LuaForce|string
---@param experience number amount of experience to add
---@param resursive_call boolean whether or not the function is called recursively (optional)
function ForceControl.add_experience(lua_force_or_name, experience, recursive_call)
    assert_type('number', experience, 'Argument experience of function ForceControl.add_experience')

    if experience < 1 then
        return
    end
    local force = get_valid_force(lua_force_or_name)
    if not force then
        return
    end
    local force_config = forces[force.name]
    if not force_config then
        return
    end

    local new_experience = force_config.current_experience + experience
    local experience_level_up_cap = force_config.experience_level_up_cap
    if not recursive_call then
        force_config.total_experience = force_config.total_experience + experience
    end

    if (new_experience < experience_level_up_cap) then
        force_config.current_experience = new_experience
        return
    end

    -- level up
    local new_level = force_config.current_level + 1
    force_config.current_level = new_level
    force_config.current_experience = 0
    force_config.experience_level_up_cap = calculate_next_level_cap(new_level)
    raise_event(ForceControl.events.on_level_up, {level_reached = new_level, force = force})

    ForceControl.add_experience(force, new_experience - experience_level_up_cap, true)
end

---Adds experience from a force, based on a percentage of the total obtained experience
---@param lua_force_or_name LuaForce|string
---@param percentage number percentage of total obtained experience to add
---@param min_experience number minimum amount of experience to add (optional)
---@return number the experience being added
---@see ForceControl.add_experience
function ForceControl.add_experience_percentage(lua_force_or_name, percentage, min_experience)
    min_experience = min_experience ~= nil and min_experience or 0
    local force = get_valid_force(lua_force_or_name)
    if not force then
        return
    end
    local force_config = forces[force.name]
    if not force_config then
        return
    end

    local reward = force_config.total_experience * percentage
    reward = (reward >= min_experience) and ceil(reward) or ceil(min_experience)
    ForceControl.add_experience(lua_force_or_name, reward)
    return reward
end

---Return the force data as {
---    current_experience = number,
---    current_level = number,
---    experience_level_up_cap = number,
---    experience_percentage = number,
---}
---@param lua_force_or_name LuaForce|string
function ForceControl.get_force_data(lua_force_or_name)
    local force = get_valid_force(lua_force_or_name)
    if not force then
        return
    end

    local force_config = forces[force.name]
    if not force_config then
        return
    end

    return {
        current_experience = force_config.current_experience,
        total_experience = force_config.total_experience,
        current_level = force_config.current_level,
        experience_level_up_cap = force_config.experience_level_up_cap,
        experience_percentage = (force_config.current_experience / force_config.experience_level_up_cap) * 100
    }
end

function ForceControl.get_formatted_force_data(lua_force_or_name)
    local force_config = ForceControl.get_force_data(lua_force_or_name)
    if not force_config then
        return
    end

    return format(
        'Current experience: %s Total experience: %s Current level: %d  Next level at: %s Percentage to level up: %d%%',
        force_config.current_experience,
        force_config.total_experience,
        force_config.current_level,
        force_config.experience_level_up_cap,
        floor(force_config.experience_percentage * 100) * 0.01
    )
end

return ForceControl
