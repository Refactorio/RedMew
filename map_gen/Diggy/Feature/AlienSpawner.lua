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

    Template.units(surface, units, 1.5, 'small-biter')
end

--[[--
    Registers all event handlers.
]]
function AlienSpawner.register(config)
    local alien_minimum_distance_square = config.alien_minimum_distance ^ 2

    Event.add(Template.events.on_void_removed, function (event)
        game.forces.enemy.evolution_factor = game.forces.enemy.evolution_factor + 0.0000012

        local position = event.position
        local x = position.x
        local y = position.y

        if (x * x + y * y < alien_minimum_distance_square or config.alien_probability < random()) then
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

function AlienSpawner.on_init()
	-- base factorio =                pollution_factor = 0.000015
    game.map_settings.enemy_evolution.pollution_factor = 0.000004
end

return AlienSpawner
