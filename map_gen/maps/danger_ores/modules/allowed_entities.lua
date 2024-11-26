-- This module prevents all but the allowed entities to be built on top of resources
--
-- Params (by precedence):
-- 1. Banned entities: entities/ghosts (by name) that will never be placed, regardless of type.
-- 2. Allowed entities: entities/ghosts (by name) that will be allowed if not blacklisted, regardless of type.
-- 3. Types: entity types allowed to be built
--
-- Usage:
-- local config = {
--   types = { ['transport-belt'] = true, },                -- all belts allowed on ore
--   allowed_entities = { ['burner-inserter'] = true, }     -- Burner inserters allowed as well, even if they're not of type `transport-belt`
--   banned_entities = { ['turbo-transport-belt'] = true, } -- Turbo belts not allowed on ore, even if they're of type `transport-belt`
-- }
-- local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'
-- AllowedEntities.register(config)

local Event = require 'utils.event'
local Global = require 'utils.global'
local random = math.random

local types = {}
local allowed_entities = {}
local banned_entities = {}

Global.register({
  types = types,
  allowed_entities = allowed_entities,
  banned_entities = banned_entities,
}, function(tbl)
  types = tbl.types
  allowed_entities = tbl.allowed_entities
  banned_entities = tbl.banned_entities
end)

local danger_alerts = {
  [[Ooooh, that's going to leave a mark!]],
  [[LOOK OUT! THE GROUND IS ANGRY!]],
  [[YOU'VE AWAKENED THE BEAST!]],
  [[OOPS! That wasn't part of the plan!]],
  [[DANGER! You've breached the ore's sanctuary!]],
  [[RUN TO THE HILLS! or at least away from THE ORE!]],
  [["I just wanted to build a factory" - famous last words]],
  [[Congratulations! YOU'VE TRIGGERED THE ORE'S WRATH!]],
  [[FROM DUST TO DUST... AND FROM ORE TO DOOM!]],
  [[THE GROUND TREMBLES WITH VENGEANCE!]],
  [[FEAR THE CURSE OF THE DEAD MINER!]],
  [[THE ORE IS ALIVE... AND IT IS ANGRY!]],
  [[A PRICE MUST BE PAID FOR YOUR ARROGANCE!]],
}

local explosions = {
  'explosion',
  'land-mine-explosion',
  'grenade-explosion',
  'medium-explosion',
  'big-explosion',
  'massive-explosion',
  'big-artillery-explosion',
  'nuke-explosion',
}

local function get_entity_info(entity)
  local ghost = (entity.name == 'entity-ghost')
  return {
    name = (ghost and entity.ghost_name) or entity.name,
    type = (ghost and entity.ghost_type) or entity.type,
    ghost = ghost
  }
end

local function allowed_entity(entity)
  local area = entity.bounding_box
  local left_top, right_bottom = area.left_top, area.right_bottom
  if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
    return true
  end
  local count = entity.surface.count_entities_filtered{ area = area, type = 'resource', limit = 1 }
  return (count == 0)
end

local function on_built(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local e = get_entity_info(entity)
  if not banned_entities[e.name] and (allowed_entities[e.name] or types[e.type]) then
    return
  end

  if allowed_entity(entity) then
    return
  end

  entity.surface.create_entity{
    name = (e.ghost and 'water-splash') or explosions[random(#explosions)],
    position = entity.position,
  }
  entity.destroy{ raise_destroy = true }

  local player = event.player_index and game.get_player(event.player_index)
  if player then
    player.print(
      danger_alerts[random(#danger_alerts)],
      { color = { r = 1, g = random(1, 100) * 0.01, b = 0 } }
    )
  end
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)

local function register_dictionary(src, dst, call)
  if not src or not dst then
    return
  end

  call = call or function(v) return v end
  for k, v in pairs(src) do
    dst[k] = call(v)
  end
end

local Public = {}

---@param config
---@field types table<string, bool>
---@field allowed_entities table<string, bool>
---@field banned_entities table<string, bool>
Public.register = function(config)
  register_dictionary(config.types, types)
  register_dictionary(config.allowed_entities, allowed_entities)
  register_dictionary(config.banned_entities, banned_entities)
end

return Public