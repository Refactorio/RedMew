local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Config = require 'config'.player_shortcuts

local AutoStash = require 'features.auto_stash'
local ClearCorpses = require 'features.clear_corpses'
local BatteryCharge = require 'features.battery_charge'

local player_preferences = {}
Global.register(player_preferences, function(tbl) player_preferences = tbl end)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local settings_button_name = Gui.uid_name()
local checkbox_action_name = Gui.uid_name()
local shortcut_action_name = Gui.uid_name()

local shortcut_buttons = {
  auto_stash = {
    name = 'auto_stash',
    caption = {'player_shortcuts.auto_stash_caption'},
    sprite = 'item/wooden-chest',
    tooltip = {'player_shortcuts.auto_stash_tooltip'},
    action = AutoStash.auto_stash,
  },
  battery_charge = {
    name = 'battery_charge',
    caption = {'player_shortcuts.battery_charge_caption'},
    sprite = 'item/battery-mk2-equipment',
    tooltip = {'player_shortcuts.battery_charge_tooltip'},
    action = BatteryCharge.recharge,
  },
  clear_corpses = {
    name = 'clear_corpses',
    caption = {'player_shortcuts.clear_corpses_caption'},
    sprite = 'entity/big-biter',
    tooltip = {'player_shortcuts.clear_corpses_tooltip'},
    action = ClearCorpses.clear_corpses,
  },
}

local Public = {}
Public.main_button_name = main_button_name
Public.main_frame_name = main_frame_name

local function enabled_shortcuts()
  local shortcuts = {}
  for k, v in pairs(shortcut_buttons) do
    if Config.shortcuts[k] then
      shortcuts[k] = v
    end
  end
  return shortcuts
end

local function get_player_preferences(player)
  local player_data = player_preferences[player.name]
  if not player_data then
    player_data = {}
    player_preferences[player.name] = player_data
  end
  return player_data
end

local function add_shortcut_selection_row(player, parent, child)
  local player_data = get_player_preferences(player)
  if player_data[child.name] == nil then
    player_data[child.name] = true
  end

  local row = parent.add { type = 'frame', style = 'shortcut_selection_row' }
  Gui.set_style(row, { horizontally_stretchable = true, vertically_stretchable = false })

  local icon = row.add {
    type = 'sprite-button',
    style = 'transparent_slot',
    sprite = child.sprite,
    tooltip = child.tooltip,
  }
  Gui.set_style(icon, { width = 20, height = 20 })

  local checkbox = row.add {
    type = 'checkbox',
    caption = child.caption,
    state = player_data[child.name],
    tags = { action = checkbox_action_name, name = child.name },
  }
  Gui.set_style(checkbox, { minimal_width = 160, horizontally_stretchable = true })
end

function Public.on_player_created(player)
  if not Config.enabled then
    return
  end

  local b = Gui.add_top_element(player, {
    type = 'sprite-button',
    name = main_button_name,
    sprite = 'utility/hand_black',
    tooltip = {'player_shortcuts.info_tooltip'},
  })
  b.style.padding = 2
end

function Public.toggle_main_button(player)
  local main_frame = Gui.get_panel(player, main_frame_name)
  local button = Gui.get_top_element(player, main_button_name)
  if main_frame then
    button.toggled = false
    Gui.destroy(main_frame)
  else
    button.toggled = true
    Public.get_main_frame(player)
  end
end

function Public.toggle_shortcuts_settings(player)
  local settings_pane = Gui.get_data(Public.get_main_frame(player)).settings_pane
  settings_pane.visible = not settings_pane.visible
end

function Public.get_main_frame(player)
  local main_frame = Gui.get_panel(player, main_frame_name)
  if main_frame then
    return main_frame
  end

  local content
  main_frame, content = Gui.add_panel(player, {
    name = main_frame_name,
    caption = {'player_shortcuts.frame_title'},
    toggle_name = main_button_name,
    -- floating, it's dragged by a strip down its side, as the bar was, rather than growing wider
    side_dragger = true,
    frameless = true,
    add_header_buttons = function(header)
      header.add {
        type = 'sprite-button',
        name = settings_button_name,
        style = 'frame_action_button',
        sprite = 'utility/expand_dots',
        tooltip = {'player_shortcuts.settings_tooltip'},
        mouse_button_filter = { 'left' },
        auto_toggle = true,
      }
    end,
  })

  local settings_pane = content.add {
    type = 'scroll-pane',
    style = 'shortcut_bar_selection_scroll_pane',
  }
  Gui.set_style(settings_pane, { horizontally_squashable = false, minimal_width = 40 * table_size(enabled_shortcuts()) })

  for _, s in pairs(enabled_shortcuts()) do
    add_shortcut_selection_row(player, settings_pane, s)
  end
  settings_pane.visible = false

  -- the buttons sit on slots like the game's own shortcut bar
  local bar = content.add { type = 'frame', style = 'shortcut_bar_inner_panel' }
  local table = bar.add {
    type = 'table',
    column_count = table_size(enabled_shortcuts()),
    style = 'filter_slot_table',
  }

  local player_data = get_player_preferences(player)
  for button_name, s in pairs(enabled_shortcuts()) do
    local button = table.add {
      type = 'sprite-button',
      style = 'slot_button', --quick_bar_page_button
      sprite = s.sprite,
      hovered_sprite = s.hovered_sprite,
      tooltip = s.tooltip,
      tags = { action = shortcut_action_name, name = button_name },
    }
    if player_data[button_name] == nil then
      player_data[button_name] = true
    end
    button.visible = player_data[button_name]
  end

  Gui.set_data(main_frame, { settings_pane = settings_pane, table = table })

  return main_frame
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, function(event)
  Public.toggle_main_button(event.player)
end)

Gui.on_click(settings_button_name, function(event)
  Public.toggle_shortcuts_settings(event.player)
end)

Event.add(defines.events.on_gui_checked_state_changed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local action_name = element.tags and element.tags.action
  if action_name and action_name == checkbox_action_name then
    local name = element.tags.name
    local frame = Public.get_main_frame(player)
    for _, button in pairs(Gui.get_data(frame).table.children) do
      if button.tags.name == name then
        local player_data = get_player_preferences(player)
        player_data[name] = element.state
        button.visible = element.state
      end
    end
  end
end)

Event.add(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  local action_name = element.tags and element.tags.action
  if action_name and action_name == shortcut_action_name then
    local name = element.tags.name
    local shortcut = shortcut_buttons[name]
    if shortcut and shortcut.action then
      shortcut.action(player, event)
    end
  end
end)

Event.add(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  Public.on_player_created(player)
end)

Event.add(defines.events.on_pre_player_removed, function(event)
  local player = game.get_player(event.player_index)
  if player then
    player_preferences[player.name] = nil
  end
end)

return Public
