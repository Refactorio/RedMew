-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local ForceControl = require 'features.force_control'

-- Will be registered in Experience.register
local ForceControl_builder = {}

-- this
local Experience = {}

local Config = {}
local floor = math.floor
local ceil = math.ceil
local log10 = math.log10
local force = 'player'

function Experience.calculate_level(level) -- all configurable variables must be integers.
    local b = floor(Config.difficulty_scale) or 25 -- Default 25 <-- Controls how much stone is needed.
    local start_value = floor(Config.start_stone) or 50 -- The start value/the first level cost
    local number = b*(level^3)+(start_value-b)
    return number
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if ((entity.name ~= 'sand-rock-big') and (entity.name ~= 'rock-huge')) then
        return
    end
    local exp = math.random(19,24)
    ForceControl.add_experience(force, exp)

    game.print(ForceControl.get_formatted_force_data(force))
end

function Experience.register(cfg)
    Config = cfg
    local b = floor(Config.difficulty_scale) or 25 -- Default 25 <-- Controls how much stone is needed.
    local start_value = floor(Config.start_stone) or 50 -- The start value/the first level cost

    ForceControl_builder = ForceControl.register(function (level_reached)
        return b*(level_reached^3)+(start_value-b)
    end)

    ForceControl_builder.register_on_every_level(function (level_reached, force)
        force.print('Leved up to ' .. level_reached .. '!')
    end)

    -- Events
    Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
end

function Experience.on_init()
    ForceControl.register_force(force)
end

return Experience
