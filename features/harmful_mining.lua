local Game = require 'utils.game'
local Global = require 'utils.global'
local Event = require 'utils.event'
local random = math.random
local ceil = math.ceil
local floor = math.floor

local this = {
  harmful_mining = true,
  warned = {}
}

Global.register(this, function(tbl) this = tbl end)

local Public = {}
local messages = { 'Ouch.. That hurt! Better be careful now.', 'Just a fleshwound.', 'Better keep those hands to yourself or you might loose them.' }

-- ============================================================================

local function is_player_warned(player, reset)
  if reset and this.warned[player.index] then
    this.warned[player.index] = nil
    return
  end
  if not this.warned[player.index] then
    this.warned[player.index] = { count = 2 }
  end
  this.warned[player.index].count = this.warned[player.index].count + 1
  return this.warned[player.index]
end

local function compute_fullness(player, position)
  if not player.mining_state.mining then
    return false
  end
  local warn_player = is_player_warned(player)
  local free_slots = player.get_main_inventory().count_empty_stacks()
  local inventory_size = #player.get_main_inventory()
  if free_slots == 0 or free_slots == 1 then
    if player.character and player.character.valid then
      local damage = ceil((warn_player.count / 2) * warn_player.count)
      if player.character.health >= damage then
        player.character.damage(damage, 'player', 'explosion')
        player.character.surface.create_entity({ name = 'water-splash', position = player.physical_position })
        Game.create_local_flying_text({ surface = player.surface, position = { position.x, position.y + 0.6 }, text = messages[random(#messages)], color = { r = 0.75, g = 0.0, b = 0.0 } })
      else
        player.character.die('enemy')
        is_player_warned(player, true)
        game.print(player.name .. ' should have emptied their pockets.', {color = { r = 0.75, g = 0.0, b = 0.0 }})
        return free_slots
      end
    end
  else
    is_player_warned(player, true)
  end
  if free_slots > 1 then
    if floor(inventory_size / free_slots) == 10 then -- When player has 10% free slots
      Game.create_local_flying_text({ surface = player.surface, position = { position.x, position.y + 0.6 }, text = 'You are feeling heavy', color = { r = 1.0, g = 0.5, b = 0.0 } })
    end
  end
  return free_slots
end

-- ============================================================================

function Public.check_fullness(player, position)
  if this.harmful_mining then
    local fullness = compute_fullness(player, position)
    if fullness == 0 then
      return
    end
  end
end

function Public.enable_fullness(value)
  if value then
    this.harmful_mining = value
  else
    this.harmful_mining = false
  end
  return this.harmful_mining
end

function Public.get(key)
  if key then
    return this[key]
  else
    return this
  end
end

local check_fullness = Public.check_fullness

Event.add(defines.events.on_player_mined_entity, function(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end

  local player = game.players[event.player_index]
  if not (player and player.valid) then
    return
  end

  if entity.name == 'entity-ghost' then
    return
  end

  if not this.harmful_mining then
    return
  end

  local position = event.entity.position
  check_fullness(player, position)
end)

-- ============================================================================

return Public