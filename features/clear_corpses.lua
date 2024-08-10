local Global = require 'utils.global'

local this = {
  radius = 128
}
Global.register(this, function(tbl) this = tbl end)

local Public = {}

function Public.clear_corpses(player, args)
  if not player or not player.valid then
    return
  end

  local surface = player.surface
  if not surface or not surface.valid then
    return
  end

  local whole_surface = false
  if args and args.surface then
    local surface_arg = args.surface:lower()
    whole_surface = player.admin and (surface_arg == 's' or surface_arg == 'surface')
  end

  local corpses
  if whole_surface then
    corpses = surface.find_entities_filtered({ type = 'corpse' })
  else
    local pos = player.position
    local area = { { pos.x - this.radius, pos.y - this.radius }, { pos.x + this.radius, pos.y + this.radius } }
    corpses = surface.find_entities_filtered({ type = 'corpse', area = area })
  end

  for i = 1, #corpses do
    corpses[i].destroy()
  end

  if #corpses > 0 then
    player.print({ 'clear_corpses.count', #corpses })
  else
    player.print({ 'clear_corpses.clear' })
  end
end

function Public.radius(value)
  this.radius = value or 128
end

return Public
