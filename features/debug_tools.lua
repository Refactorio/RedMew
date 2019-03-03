local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

Command.add(
    'debug-reveal',
    {
        description = {'command_description.reveal'},
        arguments = {'radius'},
        default_values = {radius = 500},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    function(args, p)
        local radius = args.radius
        if not p then
            p = {force = game.forces.player, surface = game.surfaces.redmew or game.surfaces.nauvis, position = {x = 0, y = 0}}
        end
        local pos = p.position
        p.force.chart(p.surface, {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}})
    end
)
