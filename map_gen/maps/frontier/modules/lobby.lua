local Config = global.config
local Public = require 'map_gen.maps.frontier.shared.core'
local this = Public.get()

local Lobby = {}

Lobby.name = 'nauvis'
Lobby.mgs = {
  water = 0,
  default_enable_all_autoplace_controls = false,
  width = 64,
  height = 64,
  peaceful_mode = true,
}

function Lobby.get_surface()
  local surface = game.get_surface(Lobby.name)
  if not surface then
    surface = game.create_surface(Lobby.name, Lobby.mgs)
  end
  return surface
end

function Lobby.teleport_to(player)
  for k = 1, player.get_max_inventory_index() do
    local inv = player.get_inventory(k)
    if inv and inv.valid then
      inv.clear()
    end
  end

  local surface = Lobby.get_surface()
  local position = surface.find_non_colliding_position('character', {0, 0}, 0, 0.2)
  player.teleport(position, surface, true)
end

function Lobby.teleport_from(player, destination)
  for _, stack in pairs(Config.player_create.starting_items) do
    if game.item_prototypes[stack.name] then
      player.insert(stack)
    end
  end
  local surface = this.surface
  local position = surface.find_non_colliding_position('character', destination or {0, 0}, 0, 0.2)
  player.teleport(position, surface, true)
end

function Lobby.teleport_all_to()
  for _, player in pairs(game.players) do
    Lobby.teleport_to(player)
  end
end

function Lobby.teleport_all_from(destination)
  for _, player in pairs(game.players) do
    Lobby.teleport_from(player, destination)
  end
end

function Lobby.on_chunk_generated(event)
  local area = event.area
  local surface = event.surface

  surface.build_checkerboard(area)
  for _, e in pairs(surface.find_entities_filtered{ area = area }) do
    if e.type ~= 'character' then
      e.destroy()
    end
  end
end

function Lobby.on_init()
  local surface = Lobby.get_surface()
  surface.map_gen_settings = Lobby.mgs
  Lobby.on_chunk_generated({ area = {left_top = {-64, -64}, right_bottom = {64, 64}}, surface = surface })
end

return Lobby
