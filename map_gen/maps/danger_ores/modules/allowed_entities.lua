-- This module prevents all but the allowed entities to be built on top of resources
--
-- Params (by precedence):
-- 1. Banned entities: entities/ghosts (by name) that will never be placed, regardless of type.
-- 2. Allowed entities: entities/ghosts (by name) that will be allowed if not blacklisted, regardless of type.
-- 3. Types: entity types allowed to be built
-- 4. Refund: true - refund and spill contents or, false/nil - destroy entity
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
local primitives = {
  refund = true,
  message = '',
}

Global.register({
  types = types,
  allowed_entities = allowed_entities,
  banned_entities = banned_entities,
  primitives = primitives,
}, function(tbl)
  types = tbl.types
  allowed_entities = tbl.allowed_entities
  banned_entities = tbl.banned_entities
  primitives = tbl.primitives
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

local function get_resource_presence(entity)
  local area = entity.bounding_box
  local left_top, right_bottom = area.left_top, area.right_bottom
  if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
    return false
  end
  local count = entity.surface.count_entities_filtered{ area = area, type = 'resource', limit = 1 }
  return (count > 0)
end

local function handle_entity_refund(entity, event)
  -- spill contents
  if entity.has_items_inside() then
    local spill_item_stack = entity.surface.spill_item_stack
    local def = { position = entity.position, enable_looted = true, force = entity.force, allow_belts = true, max_radius = 32 }
    for i_id = 1, entity.get_max_inventory_index() do
      local inv = entity.get_inventory(i_id)
      if inv and inv.valid then
        local contents = inv.get_contents()
        for _, stack in pairs(contents) do
          def.stack = stack
          spill_item_stack(def)
        end
      end
    end
  end

  -- refund item to robot/player
  local stack = entity.prototype.items_to_place_this[1]
  if stack then
    stack.quality = entity.quality
    local actor = event.robot or (event.player_index and game.get_player(event.player_index))
    if actor and actor.valid and actor.can_insert(stack) then
      actor.insert(stack)
    end
  end
end

local function player_print(player, message)
  if not (player and player.valid) then
    return
  end
  player.print(message, { color = { r = 1, g = random(1, 100) * 0.01, b = 0 } })
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

  if not get_resource_presence(entity) then
    return
  end

  entity.surface.create_entity{
    name = (e.ghost and 'water-splash') or explosions[random(#explosions)],
    position = entity.position,
  }

  local player = event.player_index and game.get_player(event.player_index)

  if not e.ghost then
    if primitives.refund then
      handle_entity_refund(entity, event)
    else
      player_print(player, danger_alerts[random(#danger_alerts)])
    end
  end

  player_print(player, primitives.message)
  entity.destroy{ raise_destroy = true }
end

Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)

local function merge_dictionary(src, dst, call)
  if not src or not dst then
    return
  end
  call = call or function(_, v) return v end
  for k, v in pairs(src) do
    dst[k] = call(k, v)
  end
end

local function build_message()
  local items = {}

  local entities = prototypes.get_entity_filtered
  for type_name, v in pairs(types) do
    if v then
      local filter = {{ filter = 'type', type = { type_name } }}
      merge_dictionary(entities(filter), items, function(k, _) return k end)
    end
  end
  merge_dictionary(allowed_entities, items)
  merge_dictionary(banned_entities, items, function(_, v) return not v end)
  merge_dictionary(items, items, function(k, v) return (v and prototypes.item[k]) or nil end)

  local str = '[color=black][DangerOres][/color] You cannot build that on top of ores, only: '
  local images = {}
  for name, _ in pairs(items) do
    images[#images+1] = '[img=item.'..name..']'
  end
  primitives.message = str .. table.concat(images, ' ')
end

local Public = {}

---@param entity LuaEntity
---@return bool
Public.is_allowed = function(entity)
  local e = get_entity_info(entity)
  if not banned_entities[e.name] and (allowed_entities[e.name] or types[e.type]) then
    return true
  end
  return false
end

---@param config
---@field types? table<string, bool>
---@field allowed_entities? table<string, bool>
---@field banned_entities? table<string, bool>
---@field refund? bool
Public.register = function(config)
  merge_dictionary(config.types, types)
  merge_dictionary(config.allowed_entities, allowed_entities)
  merge_dictionary(config.banned_entities, banned_entities)
  if config.refund ~= nil then
    primitives.refund = config.refund
  end
  if config.message then
    primitives.message = config.message
  end
  build_message()
end

return Public