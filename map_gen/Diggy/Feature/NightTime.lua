--- Provides the ability to inform players that solar panels doesn't work underground
-- also handles the freezing of nighttime
-- @module NightTime
--


-- dependencies
local Event = require 'utils.event'
local Game = require 'utils.game'
local RS = require 'map_gen.shared.redmew_surface'

-- this
local NightTime = {}

--- Event handler for on_built_entity
-- checks if player placed a solar-panel and displays a popup
-- @param event table containing the on_built_entity event specific attributes
--
local function on_built_entity(event)
    local player = Game.get_player_by_index(event.player_index)
    local entity = event.created_entity
    if (entity.name == 'solar-panel') then
        require 'features.gui.popup'.player(
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

--- Event handler for on_research_finished
-- sets the force, which the research belongs to, recipe for solar-panel-equipment
-- to false, to prevent wastefully crafting. The technology is needed for further progression
-- @param event table containing the on_research_finished event specific attributes
--
local function on_research_finished(event)
    local force = event.research.force
    force.recipes["solar-panel-equipment"].enabled = false
end

--- Setup of on_built_entity and on_research_finished events
-- assigns the two events to the corresponding local event handlers
-- @param config table containing the configurations for NightTime.lua
--
function NightTime.register()
    Event.add(defines.events.on_built_entity, on_built_entity)
    Event.add(defines.events.on_research_finished, on_research_finished)
end

--- Sets the daytime to 0.5 and freezes the day/night circle.
-- a daytime of 0.5 is the value where every light and ambient lights are turned on.
--
function NightTime.on_init()
    local surface = RS.get_surface()

    surface.daytime = 0.5
    surface.freeze_daytime = 1
end

return NightTime
