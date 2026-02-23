--- Provides the ability to inform players that solar panels doesn't work underground
-- also handles the freezing of nighttime
-- @module NightTime
--

-- dependencies
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local Popup = require 'features.gui.popup'

-- this
local NightTime = {}

--- Event handler for on_built_entity
-- checks if player placed a solar-panel and displays a popup
-- @param event table containing the on_built_entity event specific attributes
--
local function on_built_entity(event)
    local player = game.get_player(event.player_index)
    local entity = event.entity
    if entity.name == 'solar-panel' then
        Popup.player(player, { 'diggy.night_time_warning' })
    end
end

--- Setup of on_built_entity and on_research_finished events
-- assigns the two events to the corresponding local event handlers
-- @param config table containing the configurations for NightTime.lua
--
function NightTime.register()
    Event.add(defines.events.on_built_entity, on_built_entity)
end

--- Sets the daytime to 0.5 and freezes the day/night circle.
-- a daytime of 0.5 is the value where every light and ambient lights are turned on.
--
function NightTime.on_init()
    local surface = RS.get_surface()

    surface.daytime = 0.42 --0.5
    surface.freeze_daytime = true
    surface.solar_power_multiplier = 0
    surface.min_brightness = 0.11
    surface.show_clouds = false
    surface.brightness_visual_weights = { 1 / 0.85, 1 / 0.85, 1 / 0.85 }
end

return NightTime
