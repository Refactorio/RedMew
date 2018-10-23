--[[-- info
    Provides the ability to spawn aliens.
]]

-- dependencies
local Event = require 'utils.event'
local AlienEvolutionProgress = require 'map_gen.Diggy.AlienEvolutionProgress'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'
local insert = table.insert
local random = math.random

-- this
local AlienSpawner = {}

local function spawn_alien(surface, x, y)
    local enemy_force = game.forces.enemy
    local enemy_force_evolution = enemy_force.evolution_factor
    local position = {x = x, y = y}
    local biters = AlienEvolutionProgress.getBitersByEvolution(random(1, 2), enemy_force_evolution)
    local spitters = AlienEvolutionProgress.getSpittersByEvolution(random(1, 2), enemy_force_evolution)

    local units = {}
    for name, amount in pairs(biters) do
        insert(units, {name = name, position = position, force = enemy_force, amount = amount})
    end
    for name, amount in pairs(spitters) do
        insert(units, {name = name, position = position, force = enemy_force, amount = amount})
    end

    Template.units(surface, units, 3)
end

--[[--
    Registers all event handlers.
]]
function AlienSpawner.register(config)
    local alien_minimum_distance_square = config.alien_minimum_distance ^ 2

    Event.add(Template.events.on_void_removed, function(event)
        game.forces.enemy.evolution_factor = game.forces.enemy.evolution_factor + 0.0000008

        local x = event.old_tile.position.x
        local y = event.old_tile.position.y

        if (x^2 + y^2 < alien_minimum_distance_square or config.alien_probability < random()) then
            return
        end

        spawn_alien(event.surface, x, y)
    end)
end

function AlienSpawner.get_extra_map_info(config)
    return [[Alien Spawner, aliens might spawn when mining!
Spawn chance: ]] .. (config.alien_probability * 100) .. [[%
Minimum spawn distance: ]] .. config.alien_minimum_distance .. ' tiles'
end

return AlienSpawner
