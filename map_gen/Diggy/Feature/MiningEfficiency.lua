--[[-- info
    Provides the ability to increase mining efficiency while preserving the original value.
]]

-- dependencies
local Event = require 'utils.event'

-- this
local MiningEfficiency = {}

global.MiningEfficiency = {
    default_mining_speed = 0,
    active_modifier = 0,
    current_modifier = 0,
    research_modifier = 0,
}

local function update_mining_speed(player_force)
    -- recalculate current modifier
    global.MiningEfficiency.current_modifier = global.MiningEfficiency.default_mining_speed + global.MiningEfficiency.research_modifier

    -- remove the current buff
    player_force.manual_mining_speed_modifier = player_force.manual_mining_speed_modifier - global.MiningEfficiency.active_modifier

    -- update the active modifier
    global.MiningEfficiency.active_modifier = global.MiningEfficiency.current_modifier

    -- add the new active modifier
    player_force.manual_mining_speed_modifier = player_force.manual_mining_speed_modifier + global.MiningEfficiency.active_modifier
end

--[[--
    Registers all event handlers.
]]
function MiningEfficiency.register(cfg)
    local config = cfg.features.MiningEfficiency

    Event.add(defines.events.on_research_finished, function(event)
        local player_force = game.forces.player

        global.MiningEfficiency.research_modifier = player_force.mining_drill_productivity_bonus * config.mining_speed_productivity_multiplier / 2

        update_mining_speed(player_force)
    end)
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function MiningEfficiency.initialize(cfg)
    local config = cfg.features.MiningEfficiency

    global.MiningEfficiency.default_mining_speed = config.default_mining_speed
    update_mining_speed(game.forces.player)
end

return MiningEfficiency
