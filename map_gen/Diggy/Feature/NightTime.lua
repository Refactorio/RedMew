--[[-- info
    Provides the ability to inform players that solar panels doesn't work underground
]]

-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'

-- this
local NightTime = {}

local function on_built_entity(event)
    local player = Game.get_player_by_index(event.player_index)
    local entity = event.created_entity
    if (entity.name == 'solar-panel') then
        require 'popup'.player(
            player,[[
Placing solar panels underground does not seem
to have an effect on power production!
Studies show, that the same applies to the portable version!

Foreman's advice: Solar Panels are only useful in crafting
satellites
]]
        )
    end
end

local function on_research_finished(event)
    local force = game.forces.player
    force.recipes["solar-panel-equipment"].enabled=false
end

function NightTime.register(config)
        Event.add(defines.events.on_built_entity, on_built_entity)
        Event.add(defines.events.on_research_finished, on_research_finished)
end

function NightTime.on_init()
    local surface = game.surfaces.nauvis
    
    surface.daytime = 0.5
    surface.freeze_daytime = 1
end

return NightTime