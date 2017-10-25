--Author: Valansch

local resource_types = {"copper-ore", "iron-ore", "coal", "stone", "uranium-ore", "crude-oil"}

global.current_portal_index = 1
global.portals = {}
--Sample Portal:
--{entity : LuaEntity (stone-wall connected to gate), target : LuaEntity}

global.current_magic_chest_index = 1
global.magic_chests = {}
--{entity : LuaEntity, target : LuaEntity}


global.last_tp = {}


--Creates autoplace_controls with only one resource type enabled
local function create_resource_setting(resource)
  local settings = game.surfaces[1].map_gen_settings
  for _,type in pairs(resource_types) do
    settings.autoplace_controls[type] = {frequency = "none", size = "none", richness = "none"}
  end
  settings.autoplace_controls[resource] = {frequency = "normal", size = "big", richness = "good"}
  return settings
end
local function init()
  if not game.surfaces[2] then
    for _,type in pairs(resource_types) do
      game.create_surface(type, create_resource_setting(type))
    end
  end
end

function run_combined_module(event)
  init()
end

local function teleport_nearby_players(entity, target)
  for _,player in pairs(game.players) do
    if player.connected then
      if player.surface.name == entity.surface.name and distance({x = entity.position.x + 2, y = entity.position.y + 2}, player.position) < 2.5 then
        if not global.last_tp[player.name] or global.last_tp[player.name] + global.teleport_cooldown * 60 < game.tick then
          player.teleport({target.position.x + 2, target.position.y + 2}, target.surface)
          global.last_tp[player.name] = game.tick
          player.print("Wooosh! You are now in the " .. target.surface.name .. " dimention.")
        end
      end
    end
  end
end

local function teleport_players()
  local num_portals = #global.portals
  if num_portals > 0 then
    local portal = global.portals[global.current_portal_index]
    local network = portal.entity.get_circuit_network(defines.wire_type.green)
    if network and portal.target then
      if network.get_signal{type="virtual", name="signal-G"} > 0 then
        teleport_nearby_players(portal.entity, portal.target)
      end
    end
    global.current_portal_index = (global.current_portal_index) % num_portals + 1 --Next portal
  end
end

local function teleport_stuff()
  local num_chests = #global.magic_chests
  if num_chests > 0 then
    local chest = global.magic_chests[global.current_magic_chest_index]
    if chest.entity and chest.target and chest.entity.valid and chest.target.valid then
      local inv = chest.entity.get_inventory(defines.inventory.chest)
      local target_inv = chest.target.get_inventory(defines.inventory.chest)
      if inv and target_inv then
        for item, count in pairs(inv.get_contents()) do
          local n_inserted = target_inv.insert{name = item, count = count}
          inv.remove{name = item, count = n_inserted}
        end
      end
    end
    global.current_magic_chest_index = (global.current_magic_chest_index) % num_chests + 1 --Next portal
  end
end

local function dim_on_tick(event)
  if game.tick % 2 == 0 then
    teleport_stuff()
  else
    teleport_players()
  end
end

global.chest_selected = false
local function linkchests()
  if game.player and game.player.admin and game.player.selected and game.player.selected.type == "container" then
    game.player.selected.destructible = false
    game.player.selected.minable = false
    if global.chest_selected then
      global.magic_chests[#global.magic_chests].target = game.player.selected
      game.print("Link established.")
    else
      table.insert(global.magic_chests, {entity = game.player.selected})
      game.print("Selected first chest.")
    end
    global.chest_selected = not global.chest_selected
  else
    game.print("failed.")
  end
end

global.portal_selected = false
local function linkportals()
    if game.player and game.player.admin and game.player.selected and game.player.selected.name == "stone-wall" and game.player.selected.get_circuit_network(defines.wire_type.green) then
      game.player.selected.destructible = false
      game.player.selected.minable = false
      if global.portal_selected then
        global.portals[#global.portals].target = game.player.selected
        --Way back home:
        table.insert(global.portals, {entity = game.player.selected, target = global.portals[#global.portals].entity})
        game.print("Portal link established.")
      else
          table.insert(global.portals, {entity = game.player.selected})
          game.print("Selected first portal.")
      end
      global.portal_selected = not global.portal_selected
    else
        game.print("failed.")
    end
end

commands.add_command("linkchests", "Select a chest to link to another. Run this command again to select the other one.", linkchests)
commands.add_command("linkportals", "Select a portal to link to another. Run this command again to select the other one.", linkportals)
Event.register(defines.events.on_tick, dim_on_tick)
