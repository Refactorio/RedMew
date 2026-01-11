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
  local main_frame = player.gui.screen[main_frame_name]
  if main_frame then
    main_frame.destroy()
  else
    Public.get_main_frame(player)
  end
end

function Public.toggle_shortcuts_settings(player)
  local frame = Public.get_main_frame(player)
  frame.children[1].qbip.qbsp.visible = not frame.children[1].qbip.qbsp.visible
end

function Public.get_main_frame(player)
  local main_frame = player.gui.screen[main_frame_name]
  if main_frame and main_frame.valid then
    return main_frame
  end

  main_frame = player.gui.screen.add {
    type = 'frame',
    name = main_frame_name,
    direction = 'horizontal',
    style = 'quick_bar_slot_window_frame',
  }
  main_frame.auto_center = true
  Gui.set_style(main_frame, { minimal_width = 20 })

  do -- shortcuts
    local left_flow = main_frame.add { type = 'flow', direction = 'vertical' }
    Gui.set_style(left_flow, { horizontally_stretchable = true })

    local settings_scroll_pane = left_flow
    .add {
      type = 'frame',
      name = 'qbip',
      style = 'quick_bar_inner_panel'
    }.
    add {
      type = 'scroll-pane',
      name = 'qbsp',
      style = 'shortcut_bar_selection_scroll_pane',
    }
    Gui.set_style(settings_scroll_pane, { horizontally_squashable = false, minimal_width = 40 * table_size(enabled_shortcuts()) })

    for _, s in pairs(enabled_shortcuts()) do
      add_shortcut_selection_row(player, settings_scroll_pane, s)
    end
    settings_scroll_pane.visible = false

    local table_frame = left_flow.add {
      type = 'frame',
      name = 'table_frame',
      direction = 'horizontal',
      style = 'quick_bar_inner_panel',
    }
    Gui.set_style(table_frame, { horizontally_stretchable = true, margin = 0 })

    local table = table_frame.add {
      type = 'table',
      name = 'table',
      column_count = table_size(enabled_shortcuts()),
      style = 'filter_slot_table',
    }
    Gui.set_style(table, { horizontally_stretchable = true })

    local button
    local player_data = get_player_preferences(player)
    for button_name, s in pairs(enabled_shortcuts()) do
      button = table.add {
        type = 'sprite-button',
        style = 'slot_button', --quick_bar_page_button
        sprite = s.sprite,
        hovered_sprite = s.hovered_sprite,
        tooltip = s.tooltip,
        tags = { action = shortcut_action_name, name = button_name },
      }
      Gui.set_style(button, { font_color = { 165, 165, 165 } })
      if player_data[button_name] == nil then
        player_data[button_name] = true
      end
      button.visible = player_data[button_name]
    end
  end

  do -- settings
    local right_flow = main_frame.add {
      type = 'flow',
      direction = 'vertical',
    }
    Gui.set_style(right_flow, { horizontal_align = 'center', padding = 0 })
    right_flow.drag_target = main_frame

    right_flow.add {
      type = 'sprite-button',
      name = settings_button_name,
      style = 'shortcut_bar_expand_button',
      sprite = 'utility/expand_dots',
      tooltip = {'player_shortcuts.settings_tooltip'},
      mouse_button_filter = { 'left' },
      auto_toggle = true,
    }

    local widget = right_flow.add { type = 'empty-widget', style = 'draggable_space', ignored_by_interaction = true }
    Gui.set_style(widget, { vertically_stretchable = true, width = 8, margin = 0 })
  end

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
    for _, button in pairs(frame.children[1].table_frame.table.children) do
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
