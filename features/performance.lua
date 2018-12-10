local Command = require 'utils.command'
local format = string.format

local Performance = {}

---Sets the scale of performance.
---1 means the game runs at normal game speed with full particles and normal walking speed
---0.5 means the game runs at half speed, running speed is doubled and particles are halved
---@param scale number
function Performance.set_scale(scale)
    if scale < 0.05 or scale > 1 then
        error(format('Scale must range from 0.05 to 1'))
    end

    game.speed = scale
    local movement_speed_scale = Performance.get_running_speed_modifier() - 1
    for _, force in pairs(game.forces) do
        force.character_running_speed_modifier = movement_speed_scale
    end
end

---Returns the current scale
function Performance.get_scale()
    return game.speed
end

---Returns the running speed modifier
function Performance.get_running_speed_modifier()
    return 1 / game.speed
end

Command.add('set-performance-scale', {
    description = 'Sets the performance scale between 0.05 and 1. Will alter the game speed and character running speed per force.',
    arguments = {'scale'},
    admin_only = true,
    allowed_by_server = true,
}, function (arguments, player)
    local scale = tonumber(arguments.scale)
    if scale == nil or scale < 0.05 or scale > 1 then
        player.print('Scale must be a valid number ranging from 0.05 to 1')
        return
    end

    Performance.set_scale(scale)
    local p = game.print
    p('## - Changed the game speed and running speed.')
    p(format('## - Game speed: %.2f', Performance.get_scale()))
    p(format('## - Force running speed: %.2f', Performance.get_running_speed_modifier()))
end)

Command.add('get-performance-scale', {
    description = 'Shows the current performance scale.',
}, function (_, player)
    local p = player.print
    p(format('Game speed: %.2f', Performance.get_scale()))
    p(format('Running speed: %.2f', Performance.get_running_speed_modifier()))
end)

return Performance
