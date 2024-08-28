local Color = require 'resources.color_presets'
local EnemyTurret = require 'features.enemy_turret'
local math = require 'utils.math'
local PriceRaffle = require 'features.price_raffle'
local Table = require 'utils.table'
local Toast = require 'features.gui.toast'
local Token = require 'utils.token'
local Debug = require 'map_gen.maps.frontier.shared.debug'
local Public = require 'map_gen.maps.frontier.shared.core'

local register_on_entity_destroyed = script.register_on_entity_destroyed
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_floor = math.floor
local math_max = math.max
local math_random = math.random
local math_sqrt = math.sqrt
local SECOND = 60
local MINUTE = SECOND * 60

local Enemy = {}

Enemy.target_entity_types = {
  ['accumulator'] = true,
  ['assembling-machine'] = true,
  ['beacon'] = true,
  ['boiler'] = true,
  ['furnace'] = true,
  ['generator'] = true,
  ['heat-interface'] = true,
  ['lab'] = true,
  ['mining-drill'] = true,
  ['offshore-pump'] = true,
  ['reactor'] = true,
  ['roboport'] = true,
  ['solar-panel'] = true,
}

Enemy.commands = {
  move = function(unit_group, position)
    local data = Enemy.ai_take_control(unit_group)
    if not position then
      Enemy.ai_processor(unit_group)
      return
    end
    data.position = position
    data.stage = Enemy.stages.move
    unit_group.set_command {
      type = defines.command.go_to_location,
      destination = position,
      radius = 3,
      distraction = defines.distraction.by_enemy
    }
    unit_group.start_moving()
    if Public.get()._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: MOVE [gps=%.2f,%.2f,%s]', unit_group.group_number, position.x, position.y, unit_group.surface.name), Color.dark_gray)
    end
  end,
  scout = function(unit_group, position)
    local data = Enemy.ai_take_control(unit_group)
    if not position then
      Enemy.ai_processor(unit_group)
      return
    end
    data.position = position
    data.stage = Enemy.stages.scout
    unit_group.set_command {
      type = defines.command.attack_area,
      destination = position,
      radius = 15,
      distraction = defines.distraction.by_enemy
    }
    unit_group.start_moving()
    if Public.get()._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: SCOUT [gps=%.2f,%.2f,%s]', unit_group.group_number, position.x, position.y, unit_group.surface.name), Color.dark_gray)
    end
  end,
  attack = function(unit_group, target)
    local data = Enemy.ai_take_control(unit_group)
    if not (target and target.valid) then
      Enemy.ai_processor(unit_group)
      return
    end
    data.target = target
    data.stage = Enemy.stages.attack
    unit_group.set_command {
      type = defines.command.attack_area,--defines.command.attack,
      destination = target.position,
      radius = 15,
      --target = target,
      distraction = defines.distraction.by_damage
    }
    if Public.get()._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | cmd: ATTACK [gps=%.2f,%.2f,%s] (type = %s)', unit_group.group_number, target.position.x, target.position.y, unit_group.surface.name, target.type), Color.dark_gray)
    end
  end
}

Enemy.stages = {
  pending = 1,
  move = 2,
  scout = 3,
  attack = 4,
  fail = 5,
}

Enemy.turret_raffle = {
  -- sets must have at least 1 valid turret and 1 valid refill for function(x_distance, evolution)
  ['base'] = {
    ['gun-turret']          = { weight =  16, min_distance =    0, refill = { 'firearm-magazine', 'piercing-rounds-magazine', 'uranium-rounds-magazine' } },
    ['flamethrower-turret'] = { weight =   2, min_distance =  800, refill = { 'crude-oil', 'heavy-oil', 'light-oil' } },
    ['artillery-turret']    = { weight =  16, min_distance = 2800, refill = { 'artillery-shell' } }
  },
  ['Krastorio2'] = {
    ['gun-turret']          = { weight =  16, min_distance =    0, refill = { 'rifle-magazine', 'armor-piercing-rifle-magazine', 'uranium-rifle-magazine', 'imersite-rifle-magazine' } },
    ['flamethrower-turret'] = { weight =   2, min_distance =  800, refill = { 'crude-oil', 'heavy-oil', 'light-oil' } },
    ['kr-railgun-turret']   = { weight = 128, min_distance = 1400, refill = { 'basic-railgun-shell', 'explosion-railgun-shell', 'antimatter-railgun-shell' } },
    ['kr-rocket-turret']    = { weight =  16, min_distance = 2000, refill = { 'explosive-turret-rocket', 'nuclear-turret-rocket', 'antimatter-turret-rocket' } },
    ['artillery-turret']    = { weight =  16, min_distance = 2800, refill = { 'artillery-shell', 'nuclear-artillery-shell', 'antimatter-artillery-shell' } },
  },
  ['zombiesextended-core'] = {
    ['gun-turret']              = { weight =  16, min_distance =    0, refill = { 'firearm-magazine', 'assault-ammo-mk1', 'uranium-rounds-magazine', 'assault-ammo-mk2' } },
    ['gun-turret-mk1']          = { weight =  64, min_distance =  750, refill = { 'piercing-rounds-magazine', 'assault-ammo-mk1', 'assault-ammo-mk2', 'assault-ammo-mk3' } },
    ['gun-turret-mk2']          = { weight = 256, min_distance = 1500, refill = { 'assault-ammo-mk1', 'uranium-rounds-magazine', 'assault-ammo-mk2', 'assault-ammo-mk3' } },
    ['flamethrower-turret']     = { weight =   2, min_distance =  800, refill = { 'crude-oil', 'heavy-oil', 'light-oil' } },
    ['flamethrower-turret-mk1'] = { weight =   4, min_distance = 1200, refill = { 'crude-oil', 'heavy-oil', 'light-oil' } },
    ['flamethrower-turret-mk2'] = { weight =  16, min_distance = 1500, refill = { 'crude-oil', 'heavy-oil', 'light-oil' } },
    ['artillery-turret']        = { weight = 128, min_distance = 2800, refill = { 'artillery-shell' } }
  }
}

function Enemy.ai_take_control(unit_group)
  local this = Public.get()
  if not this.unit_groups[unit_group.group_number] then
    this.unit_groups[unit_group.group_number] = {
      unit_group = unit_group
    }
  end
  return this.unit_groups[unit_group.group_number]
end

function Enemy.ai_stage_by_distance(posA, posB)
  local x_axis = posA.x - posB.x
  local y_axis = posA.y - posB.y
  local distance = math_sqrt(x_axis * x_axis + y_axis * y_axis)
  if distance <= 15 then
    return Enemy.stages.attack
  elseif distance <= 32 then
    return Enemy.stages.scout
  else
    return Enemy.stages.move
  end
end

function Enemy.ai_processor(unit_group, result)
  if not (unit_group and unit_group.valid) then
    return
  end

  local this = Public.get()
  local data = this.unit_groups[unit_group.group_number]
  if not data then
    return
  end

  if data.failed_attempts and data.failed_attempts >= 3 then
    this.unit_groups[unit_group.group_number] = nil
    return
  end

  if not result or result == defines.behavior_result.fail or result == defines.behavior_result.deleted then
    data.stage = Enemy.stages.pending
  end
  if result == defines.behavior_result.success and (data.stage and data.stage == Enemy.stages.attack) then
    data.stage = Enemy.stages.pending
  end
  data.stage = data.stage or Enemy.stages.pending

  if data.stage == Enemy.stages.pending then
    local surface = unit_group.surface
    data.target = surface.find_nearest_enemy_entity_with_owner {
      position = unit_group.position,
      max_distance = this.rocket_step * 4,
      force = 'enemy',
    }
    if not (data.target and data.target.valid) then
      this.unit_groups[unit_group.group_number] = nil
      return
    end
    data.position = data.target.position
    data.stage = Enemy.ai_stage_by_distance(data.position, unit_group.position)
  else
    data.stage = data.stage + 1
  end

  if this._DEBUG_AI then
    Debug.print_admins(string.format('AI [id=%d] | status: %d', unit_group.group_number, data.stage), Color.dark_gray)
  end

  if data.stage == Enemy.stages.move then
    Enemy.commands.move(unit_group, data.target)
  elseif data.stage == Enemy.stages.scout then
    Enemy.commands.scout(unit_group, data.target)
  elseif data.stage == Enemy.stages.attack then
    Enemy.commands.attack(unit_group, data.target)
  else
    data.failed_attempts = (data.failed_attempts or 0) + 1
    if this._DEBUG_AI then
      Debug.print_admins(string.format('AI [id=%d] | FAIL | stage: %d | attempts: %d', unit_group.group_number, data.stage, data.failed_attempts), Color.dark_gray)
    end
    data.stage, data.position, data.target = nil, nil, nil
    Enemy.ai_processor(unit_group, nil)
  end
end

function Enemy.spawn_enemy_wave(position)
  local surface = Public.surface()
  local find_position = surface.find_non_colliding_position
  local spawn = surface.create_entity
  local current_tick = game.tick
  local this = Public.get()

  local unit_group = surface.create_unit_group { position = position, force = 'enemy' }

  local max_time = math_max(MINUTE, MINUTE * math_ceil(0.5 * (this.rockets_launched ^ 0.5)))

  local radius = 20
  for _ = 1, 12 do
    local name
    if this.rockets_launched < 3 then
      name = math_random(1, 6) == 1 and 'big-worm-turret' or 'medium-worm-turret'
    else
      name = math_random(1, 6) == 1 and 'behemoth-worm-turret' or 'big-worm-turret'
    end
    local about = find_position(name, { x = position.x + math_random(), y = position.y + math_random() }, radius, 0.2)
    if about then
      local worm = spawn { name = name, position = about, force = 'enemy', move_stuck_players = true }
      this.invincible[worm.unit_number] = {
        time_to_live = current_tick + math_random(MINUTE, max_time)
      }
    end
  end

  radius = 32
  for _ = 1, 20 do
    local name
    if this.rockets_launched < 3 then
      name = math_random(1, 3) == 1 and 'big-biter' or 'big-spitter'
    else
      name = math_random(1, 3) == 1 and 'behemoth-biter' or 'behemoth-spitter'
    end
    local about = find_position(name, { x = position.x + math_random(), y = position.y + math_random() }, radius, 0.6)
    if about then
      local unit = spawn { name = name, position = about, force = 'enemy', move_stuck_players = true }
      this.invincible[unit.unit_number] = {
        time_to_live = current_tick + math_random(MINUTE, max_time)
      }
      unit_group.add_member(unit)
    end
  end

  if unit_group.valid then
    Enemy.ai_take_control(unit_group)
    Enemy.ai_processor(unit_group)
  end
end
Enemy.spawn_enemy_wave_token = Token.register(Enemy.spawn_enemy_wave)

function Enemy.on_enemy_died(entity)
  local uid = entity.unit_number
  local this = Public.get()
  local data = this.invincible[uid]
  if not data then
    return
  end

  if game.tick > data.time_to_live then
    this.invincible[uid] = nil
    return
  end

  local new_entity = entity.surface.create_entity {
    name = entity.name,
    position = entity.position,
    force = entity.force,
  }

  this.invincible[new_entity.unit_number] = {
    time_to_live = data.time_to_live,
  }
  this.invincible[uid] = nil

  if new_entity.type == 'unit' then
    new_entity.set_command(entity.command)
    if entity.unit_group then
      entity.unit_group.add_member(new_entity)
    end
  end
end

function Enemy.on_spawner_died(event)
  local entity = event.entity
  local this = Public.get()
  local budget = this.loot_budget + entity.position.x * 2.75
  budget = budget * math_random(25, 175) * 0.01

  local player = false
  if event.cause and event.cause.type == 'character' then
    player = event.cause.player
  end
  if player and player.valid then
    budget = budget + (this.death_contributions[player.name] or 0) * 80
  end

  if math_random(1, 128) == 1 then budget = budget * 4 end
  if math_random(1, 256) == 1 then budget = budget * 4 end
  budget = budget * this.loot_richness

  local chest = entity.surface.create_entity { name = 'steel-chest', position = entity.position, force = 'player', move_stuck_players = true }
  chest.destructible = false
  for i = 1, 4 do
    local item_stacks = PriceRaffle.roll(math_floor(budget / 3 ) + 1, i*i + math_random(3))
    for _, item_stack in pairs(item_stacks) do
      chest.insert(item_stack)
    end
  end
  if player then
    Toast.toast_player(player, nil, {'frontier.loot_chest'})
  end
end

function Enemy.roll_turret(x_distance, evolution)
  local set = Enemy.turret_raffle['base']
  if script.active_mods['Krastorio2'] then
    set = Enemy.turret_raffle['Krastorio2']
  end
  if script.active_mods['zombiesextended-core'] then
    set = Enemy.turret_raffle['zombiesextended-core']
  end

  local weighted_turrets_table = {}
  for name, data in pairs(set) do
    if data.min_distance < x_distance then
      table.insert(weighted_turrets_table, { name, data.weight })
    end
  end

  local turret = Table.get_random_weighted(weighted_turrets_table)
  local refills = set[turret].refill
  local refill
  if evolution < 0.2 then
    refill = refills[1]
  elseif evolution < 0.5 then
    refill = refills[2] or refills[#refills]
  elseif evolution < 0.75 then
    refill = refills[3] or refills[#refills]
  else
    refill = refills[4] or refills[#refills]
  end
  return turret, refill
end

function Enemy.spawn_turret_outpost(position)
  local this = Public.get()
  if position.x < this.right_boundary * 32 + this.wall_width then
    return
  end

  local max_chance = math_clamp(0.02 * math_sqrt(position.x), 0.01, 0.04)
  if math_random() > max_chance then
    return
  end

  local surface = Public.surface()

  if Public.ESCAPE_PLAYER then
    for _, player in pairs(surface.find_entities_filtered{type = 'character'}) do
      local pos = surface.find_non_colliding_position('character', { position.x -10, position.y }, 5, 0.5)
      if pos then
        player.teleport(pos, surface)
      end
    end
  end

  local evolution = game.forces.enemy.evolution_factor
  for _, v in pairs({
    { x = -5, y =  0, direction = defines.direction.west },
    { x =  5, y =  0, direction = defines.direction.east },
    { x =  0, y =  5, direction = defines.direction.south },
    { x =  0, y = -5, direction = defines.direction.north },
  }) do
      local turret_name, refill_name = Enemy.roll_turret(position.x, evolution)
      local pos = surface.find_non_colliding_position(turret_name, { position.x + v.x, position.y + v.y }, 2, 0.5)
      if pos then
        local turret = surface.create_entity {
          name = turret_name,
          position = pos,
          force = 'enemy',
          move_stuck_players = true,
          create_build_effect_smoke = true,
          direction = v.direction,
        }
        if turret and turret.valid then
          EnemyTurret.register(turret, refill_name)
        end
      end
  end
end

function Enemy.start_tracking(entity)
  if not Enemy.target_entity_types[entity.type] then
    return
  end

  if entity.force.name == 'enemy' or entity.force.name == 'neutral' then
    return
  end

  register_on_entity_destroyed(entity)
  Public.get().target_entities[entity.unit_number] = entity
end

function Enemy.stop_tracking(entity)
  Public.get().target_entities[entity.unit_number] = nil
end

function Enemy.get_target()
  return Table.get_random_dictionary_entry(Public.get().target_entities, false)
end

function Enemy.nuclear_explosion(position)
  Public.surface().create_entity {
    name = 'atomic-rocket',
    position = position,
    force = 'enemy',
    source = position,
    target = position,
    max_range = 1,
    speed = 0.1
  }
end
Enemy.nuclear_explosion_token = Token.register(Enemy.nuclear_explosion)

function Enemy.artillery_explosion(data)
  local surface = game.get_surface(data.surface_name)
  local position = data.position
  local r = 20
  surface.create_entity {
    name = 'artillery-projectile',
    position = position,
    force = 'enemy',
    source = position,
    target = { x = position.x + math_random(-r, r) + math_random(), y = position.y + math_random(-r, r) + math_random() },
    max_range = 1,
    speed = 0.1
  }
end
Enemy.artillery_explosion_token = Token.register(Enemy.artillery_explosion)

function Enemy.on_research_finished(technology)
  if technology.force.name ~= 'player' then
    return
  end

  game.forces.enemy.technologies[technology.name].researched = true
end

return Enemy
