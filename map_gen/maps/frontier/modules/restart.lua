local AdminPanel = require 'features.gui.admin_panel.core'
local Color = require 'resources.color_presets'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Public = require 'map_gen.maps.frontier.shared.core'

local Restart = {}
local main_button_name = Gui.uid_name()
local textbox_tag_name = Gui.uid_name()
local reset_button_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local apply_button_name = Gui.uid_name()
local abort_button_name = Gui.uid_name()
local restart_button_name = Gui.uid_name()

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

  local headers = canvas.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(headers, { right_padding = 14 })
  Gui.add_pusher(headers)
  Gui.set_style(headers.add { type = 'label', caption = 'Current' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })
  Gui.set_style(headers.add { type = 'label', caption = 'Modifier' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })
  Gui.set_style(headers.add { type = 'label', caption = 'Predicted' }, { width = 80, font = 'heading-2', font_color = { 255, 230, 192 } })

  local sp = canvas.add { type = 'scroll-pane', horizontal_scroll_policy = 'auto', vertical_scroll_policy = 'always', style = 'naked_scroll_pane' }
  Gui.set_style(sp, { maximal_height = 400, right_padding = 4 })

  local data = {}

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
  show_values(row_3, data, { feature = 'spawn_enemy_wave', caption = 'Rocket spawn enemy waves' })

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

  canvas.add { type = 'line', direction = 'horizontal' }
  local restart = canvas.add { type = 'frame', caption = 'Restart', style = 'bordered_frame', direction = 'horizontal' }
  restart.add {
    type = 'label',
    caption = 'Restart scenario from scratch'
  }
  Gui.add_pusher(restart)
  restart.add {
    type = 'button',
    name = abort_button_name,
    style = 'red_back_button',
    caption = 'Abort',
    tooltip = 'Abort any restart action'
  }
  restart.add {
    type = 'button',
    name = restart_button_name,
    style = 'red_confirm_button',
    caption = 'Restart',
    tooltip = 'A save of current map will be automatically\ncreated before restarting'
  }
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
  if not tag or tag ~= textbox_tag_name then
    return
  end

  local data = Gui.get_data(element)
  local current, modifier = data.current, data.modifier
  data.predicted.text = tostring(safe_add(current.text, modifier.text))
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
  Restart.reset()
  draw_gui(event.player)
end)

Gui.on_click(abort_button_name, function()
  Public.get().abort = true
  game.print({'frontier.abort'}, Color.warning)
end)

Gui.on_click(restart_button_name, function()
  game.auto_save('pre-reset')
  Task.set_timeout( 1, Restart.restart_message_token, 10)
  Task.set_timeout(11, raise_event_token, { name = Public.events.on_game_finished })
end)

Restart.restart_message_token = Token.register(function(seconds)
  game.print({'frontier.restart', seconds}, Color.success)
end)

function Restart.set_game_state(player_won)
  Public.get().scenario_finished = true
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

function Restart.reset()
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

function Restart.apply()
  local this = Public.get()
  for k, v in pairs(restart_modifiers) do
    this[k] = safe_add(this[k], v)
  end
  Restart.reset()
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

function Restart.on_game_finished()
  Task.set_timeout(10, raise_event_token, { name = Public.events.on_game_started })
end

return Restart
