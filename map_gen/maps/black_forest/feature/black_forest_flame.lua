--- Provides the ability to inform players that solar panels doesn't work underground
-- also handles the freezing of nighttime
-- @module NightTime
--


-- dependencies
local Event = require 'utils.event'


-- this
local Flame = {}

--- Event handler for on_built_entity
-- checks if player placed a solar-panel and displays a popup
-- @param event table containing the on_built_entity event specific attributes
--
--local function on_built_entity(event)
--    local player = game.get_player(event.player_index)
--    local entity = event.created_entity
--    if (entity.name == 'flamethrower') then
--        require 'features.gui.popup'.player(
--            player, {'diggy.night_time_warning'}
--        )
--    end
--end

--- Event handler for on_research_finished
-- sets the force, which the research belongs to, recipe for solar-panel-equipment
-- to false, to prevent wastefully crafting. The technology is needed for further progression
-- @param event table containing the on_research_finished event specific attributes
--
local function on_research_finished(event)
    local force = event.research.force
    force.recipes["flamethrower"].enabled = false
    force.recipes["flamethrower-ammo"].enabled = false
    force.recipes["flamethrower-turret"].enabled = false
end

--- Setup of on_built_entity and on_research_finished events
-- assigns the two events to the corresponding local event handlers
-- @param config table containing the configurations for NightTime.lua
--
function Flame.register()
    --Event.add(defines.events.on_built_entity, on_built_entity)
    Event.add(defines.events.on_research_finished, on_research_finished)
end



return Flame
