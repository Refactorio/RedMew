-- This feature adds teleport shortcuts in train stop's GUI to allow players to teleport between tran stations.
-- A player must stand nearby a train station to be able to teleport, and must teleport to a physical train stop (not ghost).

local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local config = require 'config'.train_station_teleport

local relative_frame_name = Gui.uid_name()
local teleport_button_name = Gui.uid_name()

local this = {
  relative_gui = {},
  radius = config.radius or 13,
  enabled = config.enabled or false,
}

Global.register(this, function(tbl) this = tbl end)

Event.add(defines.events.on_gui_opened, function(event)
  if event.gui_type ~= defines.gui_type.entity then
    return
  end

  local old = this.relative_gui[event.player_index]
  if old and old.valid then
    Gui.destroy(old)
  end

  if not this.enabled then
    return
  end

  local entity = event.entity
  if not entity or entity.name ~= 'train-stop' then
    return
  end

  local player = game.get_player(event.player_index)
  local frame = player.gui.relative.add {
    type = 'frame',
    name = relative_frame_name,
    direction = 'vertical',
    anchor = {
      gui = defines.relative_gui_type.train_stop_gui,
      position = defines.relative_gui_position.top,
    }
  }
  Gui.set_style(frame, { horizontally_stretchable = false, padding = 3 })

  local canvas = frame.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }
  Gui.set_style(canvas, { padding = 4 })

  local button = canvas.add { type = 'button', name = teleport_button_name, caption = 'Teleport' , style = 'confirm_button_without_tooltip' }
  Gui.set_data(button, { entity = entity })

  this.relative_gui[event.player_index] = frame
end)

Gui.on_click(teleport_button_name, function(event)
  local player = event.player
  if player.physical_surface.count_entities_filtered({
    position = player.physical_position,
    radius = this.radius,
    name = 'train-stop',
    limit = 1,
  }) == 0 then
    player.print({ 'train_station_teleport.err_no_nearby_station' })
    return
  end

  local entity = Gui.get_data(event.element).entity
  if not (entity and entity.valid) then
    return
  end

  local position = entity.surface.find_non_colliding_position('character', entity.position, this.radius, 0.2)
  if position then
    player.print({ 'train_station_teleport.success_destination', entity.backer_name })
    player.teleport(position, entity.surface)
  else
    player.print({ 'train_station_teleport.err_no_valid_position' })
  end
end)

local Public = {}

Public.get = function(key)
  return this[key]
end

Public.set = function(key, value)
  this[key] = value
end

return Public
