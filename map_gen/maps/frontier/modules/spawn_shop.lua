local Color = require 'resources.color_presets'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local PriceRaffle = require 'features.price_raffle'
local ScoreTracker = require 'utils.score_tracker'
local Table = require 'utils.table'
local Toast = require 'features.gui.toast'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Public = require 'map_gen.maps.frontier.shared.core'
local math_ceil = math.ceil
local math_floor = math.floor
local math_random = math.random
local SECOND = 60

local bard_refresh_messages = {
  [[Ah, a gold coin! I bow to its allure! Here are fresh wares for your perusal!]],
  [[Splendid! Gold speaks, and I respond! Behold, new treasures await!]],
  [[With a coin of gold in hand, the fates realign! Check out my dazzling new offers!]],
  [[Gold flows like a river, and I shall bend to its will! Feast your eyes on these new delights!]],
  [[As you wish! The language of gold is my command! Here, new bargains for your quest!]],
  [[A glittering coin! I am at your service! New and wondrous offers are at your fingertips!]],
  [[Language of gold, you say? Very well! Behold, fresh offerings crafted by fate!]],
  [[A golden gift! I bend to its charm! Discover what new wonders sparkle before you!]],
  [[With your coin, I rejuvenate my stock! Here are shiny new wares for your journey!]],
  [[Gold calls, and I answer gladly! Fresh treasures for the wise adventurer await!]],
}

local SpawnShop = {}

SpawnShop.main_frame_name = Gui.uid_name()
SpawnShop.close_button_name = Gui.uid_name()
SpawnShop.refresh_button_name = Gui.uid_name()
SpawnShop.upgrade_button_name = Gui.uid_name()

SpawnShop.upgrades = {
  { name = 'mining_productivity', packs =  100, sprite = 'technology/mining-productivity-1',                     caption = 'Mining productivity',        tooltip = {'frontier.tt_shop_mining_productivity'} },
  { name = 'energy_damage',       packs =  100, sprite = 'technology/laser-weapons-damage-1',                   caption = 'Energy weapons damage',      tooltip = {'frontier.tt_shop_energy_damage'} },
  { name = 'projectile_damage',   packs =  100, sprite = 'technology/physical-projectile-damage-1',              caption = 'Physical projectile damage', tooltip = {'frontier.tt_shop_projectile_damage'} },
  { name = 'explosive_damage',    packs =  100, sprite = 'technology/stronger-explosives-1',                     caption = 'Explosives damage',          tooltip = {'frontier.tt_shop_explosive_damage'} },
  { name = 'flammables_damage',   packs =  100, sprite = 'technology/refined-flammables-1',                      caption = 'Flammables damage',          tooltip = {'frontier.tt_shop_flammables_damage'} },
  { name = 'artillery_range',     packs =  100, sprite = 'technology/artillery-shell-range-1',                   caption = 'Artillery range',            tooltip = {'frontier.tt_shop_artillery_range'} },
  { name = 'artillery_speed',     packs =  100, sprite = 'technology/artillery-shell-speed-1',                   caption = 'Artillery speed',            tooltip = {'frontier.tt_shop_artillery_speed'} },
  { name = 'robot_cargo',         packs = 1000, sprite = 'technology/worker-robots-storage-1',                   caption = 'Worker robot cargo',         tooltip = {'frontier.tt_shop_robot_cargo'} },
  { name = 'robot_speed',         packs =  100, sprite = 'technology/worker-robots-speed-1',                     caption = 'Worker robot speed',         tooltip = {'frontier.tt_shop_robot_speed'} },
  { name = 'robot_battery',       packs =  100, sprite = 'technology/personal-roboport-mk2-equipment',           caption = 'Worker robot battery',       tooltip = {'frontier.tt_shop_robot_battery'} },
  { name = 'braking_force',       packs =  100, sprite = 'technology/braking-force-1',                           caption = 'Braking force',              tooltip = {'frontier.tt_shop_braking_force'} },
  { name = 'inserter_capacity',   packs =  200, sprite = 'technology/inserter-capacity-bonus-1',                 caption = 'Inserters capacity',         tooltip = {'frontier.tt_shop_inserter_capacity'} },
  { name = 'lab_productivity',    packs =  500, sprite = 'technology/research-speed-1',                          caption = 'Laboratory productivity',    tooltip = {'frontier.tt_shop_lab_productivity'} },
  { name = 'p_crafting_speed',    packs =  200, sprite = 'technology/automation-2',                              caption = 'Player crafting speed',      tooltip = {'frontier.tt_shop_p_crafting_speed'} },
  { name = 'p_health_bonus',      packs =  200, sprite = 'technology/energy-shield-mk2-equipment',               caption = 'Player health',              tooltip = {'frontier.tt_shop_p_health_bonus'} },
  { name = 'p_inventory_size',    packs =  500, sprite = 'technology/toolbelt',                                  caption = 'Player inventory size',      tooltip = {'frontier.tt_shop_p_inventory_size'} },
  { name = 'p_mining_speed',      packs =  200, sprite = 'technology/steel-axe',                                 caption = 'Player mining speed',        tooltip = {'frontier.tt_shop_p_mining_speed'} },
  { name = 'p_reach',             packs =  400, sprite = 'technology/power-armor',                               caption = 'Player reach',               tooltip = {'frontier.tt_shop_p_reach'} },
  { name = 'p_running_speed',     packs =  200, sprite = 'technology/exoskeleton-equipment',                     caption = 'Player running speed',       tooltip = {'frontier.tt_shop_p_running_speed'} },
  { name = 'p_trash_size',        packs =  200, sprite = 'utility/character_logistic_trash_slots_modifier_icon', caption = 'Player trash slots size',    tooltip = {'frontier.tt_shop_p_trash_size'} },
}

SpawnShop.starter_upgrades_pool = {
  { p_crafting_speed = 25, p_inventory_size = 10, p_reach = 3, p_running_speed = 30, p_health_bonus = 40 },
  { energy_damage = 40, projectile_damage = 40, explosive_damage = 40, flammables_damage = 40, artillery_range = 15 },
  { mining_productivity = 25, robot_cargo = 8, robot_speed = 40, robot_battery = 40, inserter_capacity = 4, lab_productivity = 40 },
}

function SpawnShop.add_render()
  local e = Public.get().spawn_shop
  rendering.draw_sprite {
    sprite = script.active_mods['redmew-data'] and 'neon-lightning' or 'achievement/lazy-bastard',
    x_scale = 0.8,
    y_scale = 0.8,
    target = {
      entity = e,
      offset = { 0.8, -4.5 },
      position = e.position,
    },
    surface = e.surface,
  }
  game.forces.player.add_chart_tag(e.surface, {
    position = e.position,
    icon = { type = 'virtual', name = 'signal-info' },
    text = '[font=heading-1]   [color=#E9AF96]S[/color][color=#E9E096]P[/color][color=#BFE996]A[/color][color=#96E99E]W[/color][color=#96E9D0]N[/color]  [color=#96D0E9]S[/color][color=#969EE9]H[/color][color=#BF96E9]O[/color][color=#E996E0]P[/color][/font]'
  })
end
SpawnShop.add_render_token = Token.register(SpawnShop.add_render)

function SpawnShop.on_game_started()
  local surface = Public.surface()
  local position = surface.find_non_colliding_position('market', {0, 0}, 32, 0.5, true)
  local shop = surface.create_entity {
    name = 'market',
    position = position,
    force = 'player',
    create_build_effect_smoke = true,
    move_stuck_players = true,
    raise_built = false,
  }
  shop.minable_flag = false
  Public.get().spawn_shop = shop
  Task.set_timeout(1, SpawnShop.add_render_token)
  SpawnShop.refresh_all_prices(false)

  local seed = surface.map_gen_settings.seed
  local pool = SpawnShop.starter_upgrades_pool
  local bonuses = pool[seed % #pool + 1]
  for k, v in pairs(bonuses) do
    SpawnShop.upgrade_perk(k, v)
  end

  if math_random(1, 4) == 1 then
    SpawnShop.upgrade_perk('p_inventory_size', 4)
  end
  if math_random(1, 8) == 1 then
    SpawnShop.upgrade_perk('mining_productivity', 100)
    SpawnShop.upgrade_perk('robot_battery', 50)
    SpawnShop.upgrade_perk('robot_cargo', 20)
    SpawnShop.upgrade_perk('robot_speed', 50)
  end
  if math_random(1, 16) == 1 then
    SpawnShop.upgrade_perk('energy_damage', 100)
    SpawnShop.upgrade_perk('explosive_damage', 100)
    SpawnShop.upgrade_perk('flammables_damage', 100)
    SpawnShop.upgrade_perk('projectile_damage', 100)
  end
  if math_random(1, 32) == 1 then
    SpawnShop.upgrade_perk('lab_productivity', 200)
  end
end

function SpawnShop.draw_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    player.opened = frame
    return
  end

  local this = Public.get()

  frame = player.gui.screen.add { type = 'frame', name = SpawnShop.main_frame_name, direction = 'vertical' }
  Gui.set_style(frame, {
    horizontally_stretchable = true,
    natural_width = 760,
    natural_height = 640,
    maximal_height = 900,
    top_padding = 8,
    bottom_padding = 8,
  })

  do -- title
    local flow = frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

    local label = flow.add { type = 'label', caption = 'Spawn shop', style = 'frame_title' }
    label.drag_target = frame

    local dragger = flow.add { type = 'empty-widget', style = 'draggable_space_header' }
    dragger.drag_target = frame
    Gui.set_style(dragger, { height = 24, horizontally_stretchable = true })

    flow.add {
      type = 'sprite-button',
      name = SpawnShop.close_button_name,
      sprite = 'utility/close',
      clicked_sprite = 'utility/close_black',
      style = 'close_button',
      tooltip = {'gui.close-instruction'}
    }
  end

  local idf = frame.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }
  local sp = idf.add { type = 'scroll-pane', style = 'text_holding_scroll_pane' }
  Gui.set_style(sp, {
    horizontally_stretchable = true,
    vertically_stretchable = true,
    vertically_squashable = false,
    maximal_height = 860,
  })
  sp.vertical_scroll_policy = 'always'

  local player_inventory = player.get_main_inventory()
  local pockets = Table.array_to_dict(player_inventory.get_contents(), 'name')

  local function add_upgrade(parent, p)
    local data = this.spawn_shop_upgrades[p.name]
    if not data then
      return
    end

    local upgrade_frame = parent.add { type = 'frame', name = p.name, direction = 'vertical' }
    Gui.set_style(upgrade_frame, { horizontally_stretchable = true, bottom_padding = 4 })

    local row = upgrade_frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(row, { horizontal_spacing = 10, vertical_align = 'center' })

    local col_1 = row.add { type = 'sprite-button', sprite = p.sprite, style = 'transparent_slot' }
    Gui.set_style(col_1, { padding = -2, size = 48 })

    local col_2 = row.add { type = 'flow', direction = 'vertical' }
    Gui.set_style(col_2, { natural_width = 180 })
    col_2.add { type = 'label', style = 'caption_label', caption = p.caption }
    col_2.add { type = 'label', caption = 'Level: ' .. (data.level or 0) }
    col_2.add { type = 'label', caption = p.tooltip }

    Gui.add_pusher(row)

    local col_3 = row.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(col_3, { natural_width = 360, vertical_align = 'center', horizontal_align = 'right' })
    local col_3_1 = col_3.add { type = 'flow', direction = 'vertical' }
    local table = col_3_1 .add { type = 'frame', style = 'inside_deep_frame' }.add { type = 'table', style = 'filter_slot_table', column_count = 5 }

    if data.price then
      for _, item_stack in pairs(data.price) do
        local satisfied = (item_stack.count <= (pockets[item_stack.name] and pockets[item_stack.name].count or 0))
        table.add {
          type = 'sprite-button',
          sprite = 'item/'..item_stack.name,
          style = satisfied and 'slot_button' or 'yellow_slot_button',
          number = item_stack.count,
          tooltip = {'frontier.tt_shop_item_stack', {'?', {'item-name.'..item_stack.name}, {'entity-name.'..item_stack.name}, item_stack.name}, item_stack.count, (satisfied and 'green' or 'yellow') }
        }
      end
    end
    Gui.add_pusher(col_3)
    local col_3_2 = col_3.add { type = 'flow', direction = 'vertical' }
    local upgrade_button = col_3_2.add { type = 'button', name = SpawnShop.upgrade_button_name, style = 'confirm_button', caption = 'Upgrade', tags = { name = p.name } }
    upgrade_button.enabled = SpawnShop.can_purchase(player, p.name)
  end

  for _, params in pairs(SpawnShop.upgrades) do
    add_upgrade(sp, params)
  end

  local subfooter = idf.add { type = 'frame', style = 'subfooter_frame' }.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(subfooter, { horizontally_stretchable = true, horizontal_align = 'right', vertical_align = 'center', right_padding = 10 })

  subfooter.add { type = 'label', caption = 'Team funds ', style = 'caption_label' }
  local coin_button = subfooter.add {
    type = 'sprite-button',
    sprite = 'item/coin',
    style = 'transparent_slot',
    number = this.spawn_shop_funds,
    tooltip = {'frontier.tt_shop_funds_label'}
  }
  Gui.set_style(coin_button, { size = 28, right_margin = 8 })
  subfooter.add { type = 'label', caption = 'Refresh prices ', style = 'caption_label' }
  local refresh_button = subfooter.add {
    type = 'sprite-button',
    name = SpawnShop.refresh_button_name,
    sprite = 'utility/refresh',
    style = 'tool_button',
    tooltip = this.spawn_shop_funds > 0 and {'frontier.tt_shop_refresh_button'} or {'frontier.tt_shop_disabled_refresh_button'}
  }
  refresh_button.enabled = this.spawn_shop_funds > 0
  local tick = this.spawn_shop_cooldown[player.index]
  if tick and tick > game.tick then
    refresh_button.enabled = false
    refresh_button.tooltip = {'frontier.tt_shop_refresh_button_cooldown'}
  end

  frame.force_auto_center()
  frame.auto_center = true
  player.opened = frame
end

function SpawnShop.destroy_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    frame.destroy()
  end
end

function SpawnShop.update_gui(player)
  local frame = player.gui.screen[SpawnShop.main_frame_name]
  if frame then
    frame.destroy()
    SpawnShop.draw_gui(player)
  end
end

function SpawnShop.update_all_guis()
  for _, player in pairs(game.players) do
    SpawnShop.update_gui(player)
  end
end

function SpawnShop.refresh_price(id)
  local upgrade = SpawnShop.get_upgrade_by_id(id)
  if not upgrade then
    return
  end

  local this = Public.get()
  local nominal_cost = math_floor(Public.VALUE_7_PACKS * Public.PROD_PENALTY * upgrade.packs)
  local item_stacks = PriceRaffle.roll(nominal_cost, 5, this.banned_items)
  if this._DEBUG_SHOP then
    item_stacks = {{ name = 'iron-plate', count = 1 }}
  end

  do
    local cost_map = {}
    for _, is in pairs(item_stacks) do
      cost_map[is.name] = (cost_map[is.name] or 0) + is.count
    end
    item_stacks = {}
    for k, v in pairs(cost_map) do
      table.insert(item_stacks, { name = k, count = v })
    end
  end

  this.spawn_shop_upgrades[id] = this.spawn_shop_upgrades[id] or { level = 0 }
  this.spawn_shop_upgrades[id].price = item_stacks
end

function SpawnShop.refresh_all_prices(by_request)
  if by_request then
    ScoreTracker.change_for_global('coins-spent', 1)
  end
  for _, upgrade in pairs(SpawnShop.upgrades) do
    SpawnShop.refresh_price(upgrade.name)
  end
end

function SpawnShop.earn_coin()
  local this = Public.get()
  this.spawn_shop_funds = this.spawn_shop_funds + 1
  ScoreTracker.set_for_global(Public.scores.shop_funds.name, this.spawn_shop_funds)
  Toast.toast_all_players(20, {'frontier.earn_coin'})
end

function SpawnShop.can_purchase(player, id)
  if not (player and player.valid) then
    return false
  end

  local data = Public.get().spawn_shop_upgrades[id]
  if not (data and data.price) then
    return false
  end

  local inv = player.get_main_inventory()
  if inv.is_empty() then
    return false
  end

  local function can_purchase(request, available)
    for item, required in pairs(request) do
      if not available[item] or (available[item].count < required) then
        return false
      end
    end
    return true
  end

  local available = Table.array_to_dict(inv.get_contents(), 'name')
  local request = {}
  for _, item_stack in pairs(data.price) do
    request[item_stack.name] = item_stack.count
  end

  return can_purchase(request, available)
end

function SpawnShop.get_upgrade_by_id(id)
  for _, v in pairs(SpawnShop.upgrades) do
    if v.name == id then
      return v
    end
  end
end

function SpawnShop.on_player_purchase(player, id)
  if not (player and player.valid) then
    return
  end

  local data = Public.get().spawn_shop_upgrades[id]
  if not (data and data.price) then
    return
  end

  if not SpawnShop.can_purchase(player, id) then
    player.print({'frontier.shop_purchase_fail'}, { sound_path = 'utility/cannot_build' })
    return
  end

  local inv = player.get_main_inventory()
  for _, item_stack in pairs(data.price) do
    inv.remove(item_stack)
  end

  data.level = data.level + 1
  SpawnShop.upgrade_perk(id)
  SpawnShop.refresh_price(id)
  SpawnShop.update_all_guis()
  game.print({'frontier.shop_purchase_success', player.name, SpawnShop.get_upgrade_by_id(id).caption, data.level}, { sound_path = 'utility/new_objective' })
end

function SpawnShop.on_player_refresh(player)
  local this = Public.get()
  this.spawn_shop_funds = this.spawn_shop_funds - 1
  if not player.admin then
    this.spawn_shop_cooldown[player.index] = game.tick + 40 * SECOND
  end
  ScoreTracker.set_for_global(Public.scores.shop_funds.name, this.spawn_shop_funds)
  player.print('[color=orange][Bard][/color] ' .. bard_refresh_messages[math_random(#bard_refresh_messages)], { sound_path = 'utility/scenario_message', color = Color.dark_grey })
  if this.spawn_shop_funds <= 5 then
    game.print({'frontier.shop_funds_alert', player.name, this.spawn_shop_funds})
  end
  SpawnShop.refresh_all_prices(true)
  SpawnShop.update_all_guis()
end

function SpawnShop.upgrade_perk(id, levels)
  local data = Public.get().spawn_shop_upgrades[id]
  if not data then
    return
  end

  local players = game.forces.player

  local function apply_bonus(source, name, modifier)
    local types = {
      ammo   = { get = players.get_ammo_damage_modifier,   set = players.set_ammo_damage_modifier   },
      gun    = { get = players.get_gun_speed_modifier,     set = players.set_gun_speed_modifier     },
      turret = { get = players.get_turret_attack_modifier, set = players.set_turret_attack_modifier },
    }
    local force = types[source]
    force.set(name, force.get(name) + modifier)
  end

  local function scan_entities(source, target, modifier)
    for _, category in pairs({'entity'}) do
      for name, p in pairs(prototypes[category]) do
        if p.attack_parameters then
          local params = p.attack_parameters
          if params.ammo_type and params.ammo_type == target then
            apply_bonus(source, name, modifier)
          elseif params.ammo_type and params.ammo_type.category and params.ammo_type.category == target then
            apply_bonus(source, name, modifier)
          elseif params.ammo_categories and Table.contains(params.ammo_categories, target) then
            apply_bonus(source, name, modifier)
          end
        end
      end
    end
  end

  levels = levels or 1
  data.level = (data.level or 0) + levels
  -- local target_types = { 'acid', 'electric', 'explosion', 'fire', 'impact', 'laser', 'physical', 'poison' }
  if id == 'mining_productivity' then
    players.mining_drill_productivity_bonus = players.mining_drill_productivity_bonus + 0.01 * levels
  elseif id == 'energy_damage' then
    apply_bonus('ammo', 'laser', 0.07 * levels)
    apply_bonus('ammo', 'electric', 0.07 * levels)
    apply_bonus('ammo', 'beam', 0.03 * levels)
  elseif id == 'projectile_damage' then
    apply_bonus('ammo', 'bullet', 0.04 * levels)
    apply_bonus('ammo', 'shotgun-shell', 0.04 * levels)
    apply_bonus('ammo', 'cannon-shell', 0.10 * levels)
    scan_entities('turret', 'bullet', 0.07 * levels)
  elseif id == 'explosive_damage' then
    apply_bonus('ammo', 'rocket', 0.05 * levels)
    apply_bonus('ammo', 'grenade', 0.02 * levels)
    apply_bonus('ammo', 'landmine', 0.02 * levels)
  elseif id == 'flammables_damage' then
    apply_bonus('ammo', 'flamethrower', 0.02 * levels)
    scan_entities('turret', 'flamethrower', 0.02 * levels)
  elseif id == 'artillery_range' then
    players.artillery_range_modifier = players.artillery_range_modifier + 0.03 * levels
  elseif id == 'artillery_speed' then
    apply_bonus('gun', 'artillery-shell', 0.1 * levels)
  elseif id == 'robot_cargo' then
    players.worker_robots_storage_bonus = players.worker_robots_storage_bonus + 1 * levels
  elseif id == 'robot_speed' then
    players.worker_robots_speed_modifier = players.worker_robots_speed_modifier + 0.065 * levels
  elseif id == 'robot_battery' then
    players.worker_robots_battery_modifier = players.worker_robots_battery_modifier + 0.05 * levels
  elseif id == 'braking_force' then
    players.train_braking_force_bonus = players.train_braking_force_bonus + 0.02 * levels
  elseif id == 'inserter_capacity' then
    players.inserter_stack_size_bonus = players.inserter_stack_size_bonus + 1 * levels
    players.bulk_inserter_capacity_bonus = players.bulk_inserter_capacity_bonus + 1 * levels
  elseif id == 'lab_productivity' then
    players.laboratory_productivity_bonus = players.laboratory_productivity_bonus + 0.005 * levels
  elseif id == 'p_crafting_speed' then
    players.manual_crafting_speed_modifier = players.manual_crafting_speed_modifier + 0.02 * levels
  elseif id == 'p_health_bonus' then
    local HP = prototypes.entity.character.get_max_health()
    players.character_health_bonus = players.character_health_bonus + math_ceil(0.02 * HP)  * levels
  elseif id == 'p_inventory_size' then
    players.character_inventory_slots_bonus = players.character_inventory_slots_bonus + 5 * levels
  elseif id == 'p_mining_speed' then
    players.manual_mining_speed_modifier = players.manual_mining_speed_modifier + 0.02 * levels
  elseif id == 'p_reach' then
    players.character_build_distance_bonus = players.character_build_distance_bonus + 1 * levels
    players.character_item_drop_distance_bonus = players.character_item_drop_distance_bonus + 1 * levels
    players.character_reach_distance_bonus = players.character_reach_distance_bonus + 1 * levels
    players.character_resource_reach_distance_bonus = players.character_resource_reach_distance_bonus + 1 * levels
    players.character_item_pickup_distance_bonus = players.character_item_pickup_distance_bonus + 1 * levels
  elseif id == 'p_running_speed' then
    players.character_running_speed_modifier = players.character_running_speed_modifier + 0.02 * levels
  elseif id == 'p_trash_size' then
    players.character_trash_slot_count = players.character_trash_slot_count + 5  * levels
  end
end

function SpawnShop.on_entity_damaged(event)
  local entity = event.entity
  if not (entity and entity.valid) then
    return
  end
  local this = Public.get()
  if this.spawn_shop and this.spawn_shop.valid and entity.unit_number == this.spawn_shop.unit_number then
    local cause = event.cause
    local players = game.forces.player
    if cause and cause.valid and cause.force == players or event.force == players then
      if entity.health < 1 then
        entity.health = 1
      end
    end
  end
end

return SpawnShop
