local AdminPanel = require 'features.gui.admin_panel.core'
local Color = require 'resources.color_presets'
local Core = require 'utils.core'
local Discord = require 'resources.discord'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local PlayerStats = require 'features.player_stats'
local ScoreTracker = require 'utils.score_tracker'
local Server = require 'features.server'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Public = require 'map_gen.maps.frontier.shared.core'
local format_number = require 'util'.format_number

local Restart = {}
local main_button_name = Gui.uid_name()
local textbox_tag_name = Gui.uid_name()
local reset_button_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local apply_button_name = Gui.uid_name()
local mode_dropdown_name = Gui.uid_name()
local abort_button_name = Gui.uid_name()
local restart_button_name = Gui.uid_name()
local switch_save_button_name = Gui.uid_name()
local switch_mod_pack_button_name = Gui.uid_name()
local load_clear_button_name = Gui.uid_name()
local load_confirm_button_name = Gui.uid_name()

---@type table<string>
local DEFAULT_MODIFIERS = {
  'rounds',

  -- Map gen
  'height',            -- in chunks, height of the ribbon world
  'left_boundary',     -- in chunks, distance to water body
  'right_boundary',    -- in chunks, distance to wall/biter presence
  'wall_width',        -- in tiles
  'rock_richness',     -- how many rocks/chunk
  'ore_base_quantity', -- base ore quantity, everything is scaled up from this
  'ore_chunk_scale',   -- sets how fast the ore will increase from spawn, lower = faster
  'kraken_distance',   -- where the kraken lives past the left boundary

  -- Rocket silo position
  'silo_starting_x',
  'move_buffer',
  'rocket_step',       -- rocket/tiles ratio
  'min_step',          -- minimum tiles to move
  'max_distance',      -- maximum x distance of rocket silo
  'rockets_to_win',
  'rockets_launched',
  'rockets_per_death', -- how many extra launch needed for each death

  -- Enemy data
  'spawn_enemy_outpost',
  'spawn_enemy_wave',

  -- Markets
  'loot_budget',
  'loot_richness',

  -- Spawn shop
  'spawn_shop_funds',
}
---@type table<string, any>
local restart_modifiers = {}
Global.register(restart_modifiers, function(tbl) restart_modifiers = tbl end)

local pages = AdminPanel.get_pages()
pages[#pages +1] = {
  type = 'sprite-button',
  sprite = 'utility/map',
  tooltip = '[font=default-bold]Scenario manager[/font]',
  name = main_button_name,
  auto_toggle = true,
}

local restart_mode_text = { 'None', 'Reset map', 'Restart server', 'Load save/mods' }

local function is_number(value)
  if type(value) == 'number' then return true end
  return tonumber(value) ~= nil
end

local function is_boolean(value)
  if type(value) == 'boolean' then return true end
  return value == 'true' or value == 'false'
end

local function parse_value(value)
  if is_boolean(value) then
    return value == 'true' and true or false
  end

  if is_number(value) then
    return tonumber(value)
  end

  return value
end

local function safe_add(value1, value2)
  if type(value1) ~= type(value2) then
    return
  end

  if is_boolean(value1) and is_boolean(value2) then
    return value2 == 'true' and true or false
  end

  if is_number(value1) and is_number(value2) then
    return tonumber(value1) + tonumber(value2)
  end

  return value2
end

local function show_values(parent, parent_data, params)
  local flow = parent.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(flow, { vertical_align = 'center', width = 444 })

  local this = Public.get()
  local key = params.feature
  local current_value = this[key]
  local modifier_value = restart_modifiers[key]
  local predicted_value = safe_add(current_value, modifier_value)

  flow.add { type = 'label', caption = params.caption }
  Gui.add_pusher(flow)
  local current = flow.add {
    type = 'text-box',
    style = 'short_number_textfield',
    tags = { name = textbox_tag_name },
    text = current_value,
  }
  local modifier = flow.add {
    type = 'text-box',
    style = 'short_number_textfield',
    tags = { name = textbox_tag_name },
    text = modifier_value,
  }
  local predicted = flow.add {
    type = 'text-box',
    style = 'short_number_textfield',
    text = predicted_value,
  }
  predicted.enabled = false

  local data = { current = current, modifier = modifier, predicted = predicted }
  table.insert(parent_data, { feature = key, data = data })
  Gui.set_data(current, data)
  Gui.set_data(modifier, data)
  return flow
end

local function draw_gui(player)
  local canvas = AdminPanel.get_canvas(player)
  Gui.clear(canvas)

  do -- Scenario settings
    local data = {}

    local headers = canvas.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(headers, { right_padding = 14 })
    Gui.add_pusher(headers)
    Gui.set_style(headers.add { type = 'label', caption = 'Current' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })
    Gui.set_style(headers.add { type = 'label', caption = 'Modifier' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })
    Gui.set_style(headers.add { type = 'label', caption = 'Predicted' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })

    local sp = canvas.add { type = 'scroll-pane', horizontal_scroll_policy = 'auto', vertical_scroll_policy = 'always', style = 'naked_scroll_pane' }
    Gui.set_style(sp, { maximal_height = 400, right_padding = 4 })

    local row_1 = sp.add { type = 'frame', caption = 'Map generation', style = 'bordered_frame', direction = 'vertical' }
    show_values(row_1, data, { feature = 'height', caption = 'Map height' })
    show_values(row_1, data, { feature = 'left_boundary', caption = 'Left boundary' })
    show_values(row_1, data, { feature = 'right_boundary', caption = 'Right boundary' })
    show_values(row_1, data, { feature = 'wall_width', caption = 'Wall width' })
    show_values(row_1, data, { feature = 'rock_richness', caption = 'Rocks frequency' })
    show_values(row_1, data, { feature = 'ore_base_quantity', caption = 'Base resources richness' })
    show_values(row_1, data, { feature = 'ore_chunk_scale', caption = 'Ore chunk scale' })
    show_values(row_1, data, { feature = 'kraken_distance', caption = 'Kraken distance' })

    local row_2 = sp.add { type = 'frame', caption = 'Rocket silo', style = 'bordered_frame', direction = 'vertical' }
    show_values(row_2, data, { feature = 'silo_starting_x', caption = 'Silo starting X' })
    show_values(row_2, data, { feature = 'move_buffer', caption = 'Moving buffer' })
    show_values(row_2, data, { feature = 'rocket_step', caption = 'Moving step' })
    show_values(row_2, data, { feature = 'min_step', caption = 'Min. moving step' })
    show_values(row_2, data, { feature = 'max_distance', caption = 'Max. silo distance' })
    show_values(row_2, data, { feature = 'rockets_to_win', caption = 'Rockets to win' })
    show_values(row_2, data, { feature = 'rockets_launched', caption = 'Rockets launched' })
    show_values(row_2, data, { feature = 'rockets_per_death', caption = 'Rockets per death' })

    local row_3 = sp.add { type = 'frame', caption = 'Enemies', style = 'bordered_frame', direction = 'vertical' }
    show_values(row_3, data, { feature = 'spawn_enemy_outpost', caption = 'Turrets under rocks' })
    show_values(row_3, data, { feature = 'spawn_enemy_wave', caption = 'Waves after launches' })

    local row_4 = sp.add { type = 'frame', caption = 'Markets', style = 'bordered_frame', direction = 'vertical' }
    show_values(row_4, data, { feature = 'loot_budget', caption = 'Loot budget' })
    show_values(row_4, data, { feature = 'loot_richness', caption = 'Loot richness' })

    local row_5 = sp.add { type = 'frame', caption = 'Spawn Shop', style = 'bordered_frame', direction = 'vertical' }
    show_values(row_5, data, { feature = 'spawn_shop_funds', caption = 'Team funds' })

    local button_flow = canvas.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(button_flow, { right_padding = 8 })
    Gui.add_pusher(button_flow)
    button_flow.add {
      type = 'button',
      name = reset_button_name,
      style = 'red_back_button',
      caption = 'Reset',
      tooltip = 'Resets all values to previous configuration',
    }
    local save = button_flow.add {
      type = 'button',
      name = save_button_name,
      style = 'forward_button',
      caption = 'Save',
      tooltip = 'Save modifiers configuration for later',
    }
    local apply = button_flow.add {
      type = 'button',
      name = apply_button_name,
      style = 'confirm_double_arrow_button',
      caption = 'Apply',
      tooltip = 'Apply modifiers to current configuration now',
    }
    Gui.set_style(apply, { left_margin = -9 })
    Gui.set_data(save, data)
    Gui.set_data(apply, data)
  end

  canvas.add { type = 'line', direction = 'horizontal' }

  do -- Restart settings
    local mode = Public.get('server_commands').mode
    local restart_settings = canvas.add { type = 'frame', caption = 'Restart settings', style = 'bordered_frame', direction = 'vertical' }

    local row_1 = restart_settings.add { type = 'flow', direction = 'horizontal' }
    row_1.add { type = 'label', caption = 'Map restart mode' }
    Gui.add_pusher(row_1)
    row_1.add {
      type = 'drop-down',
      name = mode_dropdown_name,
      items = restart_mode_text,
      selected_index = mode
    }

    local row_2 = restart_settings.add { type = 'flow', direction = 'horizontal' }
    row_2.add {
      type = 'label',
      caption = 'Restart scenario'
    }
    Gui.add_pusher(row_2)
    row_2.add {
      type = 'button',
      name = abort_button_name,
      style = 'red_back_button',
      caption = 'Abort',
      tooltip = 'Abort any restart action'
    }
    row_2.add {
      type = 'button',
      name = restart_button_name,
      style = 'red_confirm_button',
      caption = 'Restart',
      tooltip = 'A save of current map will be automatically\ncreated before restarting'
    }
  end

  do -- Load settings
    local server_commands = Public.get('server_commands')
    local switch_map = server_commands.switch_map
    local mode = server_commands.mode

    if switch_map.name == '' then
      switch_map.name = nil
    end
    if switch_map.mod_pack == '' then
      switch_map.mod_pack = nil
    end

    local load_settings = canvas.add { type = 'frame', caption = 'Load settings', style = 'bordered_frame', direction = 'vertical' }

    local row_1 = load_settings.add { type = 'flow', direction = 'vertical' }
    local table_1 = row_1.add { type = 'table', column_count = 2 }
    table_1.add {
      type = 'label',
      caption = 'Save name',
    }
    local t12 = table_1.add {
      type = 'textfield',
      name = switch_save_button_name,
      text = switch_map.name or 'i.e. frontier-special.zip',
    }
    table_1.add {
      type = 'label',
      caption = 'Mod pack name',
    }
    local t22 = table_1.add {
      type = 'textfield',
      name = switch_mod_pack_button_name,
      text = switch_map.mod_pack or 'i.e. frontier_modpack',
    }

    local row_2 = load_settings.add { type = 'flow', direction = 'horizontal' }
    Gui.add_pusher(row_2)
    row_2.add {
      type = 'button',
      name = load_clear_button_name,
      style = 'red_back_button',
      caption = 'Clear',
      tooltip = 'Clear load settings',
    }
    local confirm = row_2.add {
      type = 'button',
      name = load_confirm_button_name,
      style = 'confirm_button',
      caption = 'Confirm',
      tooltip = 'Confirm load settings',
    }

    Gui.set_data(confirm, { name = t12, mod_pack = t22 })

    load_settings.visible = (mode == Public.restart_mode.switch)
  end
end

local raise_event_token = Token.register(function(params)
  script.raise_event(params.name, params.data or {})
end)

Gui.on_click(main_button_name, function(event)
  local player = event.player
  local element = event.element
  if element.toggled then
    AdminPanel.close_all_pages(player)
    event.element.toggled = true
    draw_gui(player)
  else
    Gui.clear(AdminPanel.get_canvas(player))
  end
end)

Event.add(defines.events.on_gui_text_changed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local tag = element.tags and element.tags.name
  if not tag then
    return
  end

  if tag == textbox_tag_name then
    local data = Gui.get_data(element)
    local current, modifier = data.current, data.modifier
    data.predicted.text = tostring(safe_add(current.text, modifier.text))
  end
end)

Gui.on_click(reset_button_name, function(event)
  draw_gui(event.player)
end)

Gui.on_click(save_button_name, function(event)
  local data = Gui.get_data(event.element)
  for _, v in pairs(data) do
    restart_modifiers[v.feature] = parse_value(v.data.modifier.text)
  end
  draw_gui(event.player)
end)

Gui.on_click(apply_button_name, function(event)
  local this = Public.get()
  local data = Gui.get_data(event.element)
  for _, v in pairs(data) do
    this[v.feature] = safe_add(v.data.current.text, v.data.modifier.text)
  end
  Restart.reset_modifiers()
  draw_gui(event.player)
end)

Gui.on_selection_state_changed(mode_dropdown_name, function(event)
  local mode = event.element.selected_index
  Public.get().server_commands.mode = mode
  event.player.print('Restart mode changed to: '..restart_mode_text[mode], {color = Color.info})
  draw_gui(event.player)
end)

Gui.on_click(abort_button_name, function(event)
  local cmd = Public.get('server_commands')
  if not cmd.restarting then
    event.player.print('No restart action in progress', {color = Color.info})
    return
  else
    cmd.restarting = false
    game.print({'frontier.abort'}, {color = Color.warning})
  end
end)

Gui.on_click(restart_button_name, function()
  local this = Public.get()
  this.server_commands.restarting = true
  game.auto_save('pre-reset')
  Task.set_timeout( 1, Restart.restart_message_token, 10)
  Task.set_timeout(11, raise_event_token, { name = Public.events.on_game_finished })
end)

Gui.on_click(load_clear_button_name, function(event)
  local switch_map = Public.get('server_commands').switch_map
  switch_map.name = nil
  switch_map.mod_pack = nil
  draw_gui(event.player)
end)

Gui.on_click(load_confirm_button_name, function(event)
  local data = Gui.get_data(event.element)
  local switch_map = Public.get('server_commands').switch_map
  switch_map.name = data.name.text
  switch_map.mod_pack = data.mod_pack.text
  draw_gui(event.player)
end)

Restart.restart_message_token = Token.register(function(seconds)
  game.print({'frontier.restart', seconds}, {color = Color.success})
end)

function Restart.set_game_state(player_won)
  local this = Public.get()
  this.scenario_finished = true
  this.server_commands.restarting = true
  game.set_game_state {
    game_finished = true,
    player_won = player_won or false,
    can_continue = true,
    victorious_force = player_won and 'player' or 'enemy'
  }

  Task.set_timeout( 1, Restart.restart_message_token, 90)
  Task.set_timeout(31, Restart.restart_message_token, 60)
  Task.set_timeout(61, Restart.restart_message_token, 30)
  Task.set_timeout(81, Restart.restart_message_token, 10)
  Task.set_timeout(86, Restart.restart_message_token,  5)
  Task.set_timeout(90, raise_event_token, { name = Public.events.on_game_finished })
end

function Restart.reset_modifiers()
  local this = Public.get()
  for _, k in pairs(DEFAULT_MODIFIERS) do
    local init_value = this[k]
    if type(init_value) == 'number' then
      restart_modifiers[k] = 0
    else
      restart_modifiers[k] = init_value
    end
  end
end

function Restart.apply_modifiers()
  local this = Public.get()
  for k, v in pairs(restart_modifiers) do
    this[k] = safe_add(this[k], v)
  end
  Restart.reset_modifiers()
end

function Restart.get(key)
  if key then
    return restart_modifiers[key]
  end
  return restart_modifiers
end

function Restart.set(key, value)
  restart_modifiers[key] = value
end

function Restart.queue_restart_event()
  Task.set_timeout(10, raise_event_token, { name = Public.events.on_game_started })
end

function Restart.execute_server_command()
  local cmd = Public.get('server_commands')
  if not cmd.restarting then
    return
  end
  local is_hosted = Server.get_current_time() ~= nil

  if is_hosted and cmd.mode == Public.restart_mode.switch then
    Server.start_game({
      type = (cmd.switch_map.name and 'save') or 'scenario',
      name = cmd.switch_map.name or 'frontier',
      mod_pack = cmd.switch_map.mod_pack,
    })
  elseif is_hosted and cmd.mode == Public.restart_mode.restart then
    Server.start_game({
      type = 'scenario',
      name = 'frontier',
      mod_pack = nil,
    })
  elseif cmd.mode ~= Public.restart_mode.none then
    Restart.queue_restart_event()
  end
  cmd.restarting = false
end

function Restart.announce_new_map()
  local map_promotion_channel = Discord.channel_names.map_promotion
  local frontier_role_mention = Discord.role_mentions.frontier

  if _DEBUG then
    map_promotion_channel = Discord.channel_names.bot_playground
    frontier_role_mention = Discord.role_mentions.test
  end

  local notification_message = frontier_role_mention .. ' **Frontier map has just restarted!**'
  Server.to_discord_named_raw(map_promotion_channel, notification_message)
end

function Restart.print_endgame_statistics()
  local map_promotion_channel = Discord.channel_names.map_promotion
  local frontier_channel = Discord.channel_names.frontier

  if _DEBUG then
    map_promotion_channel = Discord.channel_names.bot_playground
    frontier_channel = Discord.channel_names.bot_playground
  end

  local statistics = {
    time_string = Core.format_time(game.ticks_played),
    biters_killed = ScoreTracker.get_for_global(PlayerStats.aliens_killed_name),
    entities_built = ScoreTracker.get_for_global(PlayerStats.built_by_players_name),
    resources_exhausted = ScoreTracker.get_for_global(PlayerStats.resources_exhausted_name),
    total_players = #game.players,
    rounds = Public.get('rounds'),
    rockets_launched = Public.get('rockets_launched'),
    tiles_traveled = math.ceil(Public.get('x')),
  }
  do
    local resource_prototypes = prototypes.get_entity_filtered({{ filter = 'type', type = 'resource' }})
    local ore_products = {}
    for _, ore_prototype in pairs(resource_prototypes) do
      local mineable_properties = ore_prototype.mineable_properties
      if mineable_properties.minable_flag and ore_prototype.resource_category == 'basic-solid' then
        for _, product in pairs(mineable_properties.products) do
          ore_products[product.name] = true
        end
      end
    end

    local total_ore = 0
    local ore_totals_message = '('
    for ore_name in pairs(ore_products) do
      local count = game.forces.player.get_item_production_statistics(Public.surface().name).get_input_count(ore_name)
      total_ore = total_ore + count
      ore_totals_message = ore_totals_message..ore_name:gsub( '-ore', '')..': '..format_number(count, true)..', '
    end
    ore_totals_message = ore_totals_message:sub(1, -3)..')' -- remove the last ', ' and add a bracket
    statistics.ore_totals_value = format_number(total_ore, true)
    statistics.ore_totals_breakdown = ore_totals_message
  end

  local statistics_message = {
    'Frontier round '..statistics.rounds..' completed!',
    '',
    'S T A T I S T I C S:',
    'Map time: '..statistics.time_string,
    'Total entities built: '..statistics.entities_built,
    'Total ore mined: '..statistics.ore_totals_value,
    statistics.ore_totals_breakdown,
    'Total ore resources exhausted: '..statistics.resources_exhausted,
    'Players: '..statistics.total_players,
    'Rockets launched: '..statistics.rockets_launched,
    'Tiles traveled: '..statistics.tiles_traveled,
    'Enemies killed: '..statistics.biters_killed,
  }
  Server.to_discord_named_embed(map_promotion_channel, table.concat(statistics_message, '\\n'))
  Server.to_discord_named_embed(frontier_channel, table.concat(statistics_message, '\\n'))
  game.print(table.concat(statistics_message, '\n'), { sound_path = 'utility/new_objective' })
end

return Restart
