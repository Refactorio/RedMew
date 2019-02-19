local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

local format = string.format

local Performance = {}

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
        force.character_running_speed_modifier = stat_mod - 1
        force.manual_mining_speed_modifier = stat_mod - 1
        force.manual_crafting_speed_modifier = stat_mod - 1
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
        description = 'Sets the performance scale between 0.05 and 1. Will alter the game speed, manual mining speed, manual crafting speed and character running speed per force.',
        arguments = {'scale'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    function(arguments, player)
        local scale = tonumber(arguments.scale)
        if scale == nil or scale < 0.05 or scale > 1 then
            player.print('Scale must be a valid number ranging from 0.05 to 1')
            return
        end

        Performance.set_time_scale(scale)
        local p = game.print
        local stat_mod = Performance.get_player_stat_modifier()
        p('## - Game speed changed to compensate for UPS drops and players trying to catch up.')
        p(format('## - Game speed: %.2f', Performance.get_time_scale()))
        p(format('## - Running speed: %.2f', stat_mod))
        p(format('## - Manual mining speed: %.2f', stat_mod))
        p(format('## - Manual crafting speed: %.2f', stat_mod))
    end
)

Command.add(
    'performance-scale-get',
    {
        description = 'Shows the current performance scale.'
    },
    function(_, player)
        local p = player.print
        local stat_mod = Performance.get_player_stat_modifier()
        p(format('Game speed: %.2f', Performance.get_time_scale()))
        p(format('Running speed: %.2f -- mining speed: %.2f -- crafting speed: %.2f', stat_mod, stat_mod, stat_mod))
    end
)

return Performance
