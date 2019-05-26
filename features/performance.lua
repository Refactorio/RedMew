local Command = require 'utils.command'
local Ranks = require 'resources.ranks'
local Global = require 'utils.global'

local format = string.format

local Performance = {}

local mining_efficiency = {
    active_modifier = 0
}

local craft_bonus = {
    active_modifier = 0
}

local running_bonus = {
    active_modifier = 0
}

Global.register(
    {
        mining_efficiency = mining_efficiency,
        craft_bonus = craft_bonus,
        running_bonus = running_bonus
    },
    function(tbl)
        mining_efficiency = tbl.mining_efficiency
        craft_bonus = tbl.craft_bonus
        running_bonus = tbl.running_bonus
    end
)

---Sets the scale of performance.
---1 means the game runs at normal game speed with normal walking speed
---0.5 means the game runs at half speed, running speed is doubled
---@param scale <number>
function Performance.set_time_scale(scale)
    if scale < 0.05 or scale > 1 then
        error(format('Scale must range from 0.05 to 1'))
    end

    game.speed = scale

    local stat_mod = Performance.get_player_stat_modifier()
    for _, force in pairs(game.forces) do
        force.character_running_speed_modifier = force.character_running_speed_modifier - running_bonus.active_modifier + stat_mod - 1
        running_bonus.active_modifier = stat_mod - 1
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - mining_efficiency.active_modifier + stat_mod - 1
        mining_efficiency.active_modifier = stat_mod - 1
        force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier - craft_bonus.active_modifier + stat_mod - 1
        craft_bonus.active_modifier = stat_mod - 1
    end
end

---Returns the current game time scale
function Performance.get_time_scale()
    return game.speed
end

---Returns the stat modifier for stats affecting the players
function Performance.get_player_stat_modifier()
    return 1 / game.speed
end

Command.add(
    'performance-scale-set',
    {
        description = {'command_description.performance_scale_set'},
        arguments = {'scale'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    function(arguments, player)
        local scale = tonumber(arguments.scale)
        if scale == nil or scale < 0.05 or scale > 1 then
            player.print({'performance.fail_wrong_argument'})
            return
        end

        Performance.set_time_scale(scale)
        local p = game.print
        local stat_mod = Performance.get_player_stat_modifier()
        p({'performance.stat_preamble'})
        p({'performance.generic_stat', {'performance.game_speed'}, format('%.2f', Performance.get_time_scale())})
        local stat_string = format('%.2f', stat_mod)
        p({'performance.output_formatter', {'performance.game_speed'}, stat_string, {'performance.manual_mining_speed'}, stat_string, {'performance.manual_crafting_speed'}, stat_string})
    end
)

Command.add(
    'performance-scale-get',
    {
        description = {'command_description.performance_scale_get'}
    },
    function(_, player)
        local p = player.print
        local stat_mod = Performance.get_player_stat_modifier()
        p({'performance.generic_stat', {'performance.game_speed'}, format('%.2f', Performance.get_time_scale())})
        local stat_string = format('%.2f', stat_mod)
        p({'performance.output_formatter', {'performance.game_speed'}, stat_string, {'performance.manual_mining_speed'}, stat_string, {'performance.manual_crafting_speed'}, stat_string})
    end
)

return Performance
