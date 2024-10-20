local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Config = require 'config'.admin_panel

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local close_button_name = Gui.uid_name()

local pages = {
  --[[
  {
    type = 'sprite-button',
    sprite = 'item/programmable-speaker',
    tooltip = 'First page',
  },
  {
    type = 'sprite-button',
    sprite = 'utility/spawn_flag',
    tooltip = 'Second page',
  },
  {
    type = 'sprite-button',
    sprite = 'utility/scripting_editor_icon',
    tooltip = 'Third page',
  },
  {
    type = 'sprite-button',
    sprite = 'utility/surface_editor_icon',
    tooltip = 'Fourth page',
  },
  ]]
}

Global.register(pages, function(tbl) pages = tbl end)

local Public = {}

function Public.get_pages()
  return pages
end

function Public.get_canvas(player)
  return Gui.get_data(Public.get_main_frame(player)).right
end

function Public.get_main_frame(player)
  local frame = player.gui.screen[main_frame_name]
  if frame and frame.valid then
    return frame
  end

  frame = player.gui.screen.add {
    type = 'frame',
    name = main_frame_name,
    direction = 'vertical',
    style = 'frame',
  }
  frame.auto_center = true
  player.opened = frame
  Gui.set_style(frame, {
    horizontally_stretchable = true,
    vertically_stretchable = true,
    natural_width = 400,
    natural_height = 400,
    top_padding = 8,
    bottom_padding = 8,
  })

  local data = {}

  do -- title
    local flow = frame.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

    local label = flow.add { type = 'label', caption = 'Admin panel', style = 'frame_title' }
    label.drag_target = frame

    local dragger = flow.add { type = 'empty-widget', style = 'draggable_space_header' }
    dragger.drag_target = frame
    Gui.set_style(dragger, { height = 24, horizontally_stretchable = true })

    flow.add {
      type = 'sprite-button',
      name = close_button_name,
      sprite = 'utility/close',
      clicked_sprite = 'utility/close_black',
      style = 'close_button',
      tooltip = {'gui.close-instruction'}
    }
  end

  local main_flow = frame.add { type = 'flow', name = 'flow', direction = 'horizontal' }
  Gui.set_style(main_flow, { horizontal_spacing = 12 })

  do -- left
    local left = main_flow
    .add { type = 'flow', name = 'left', direction = 'vertical' }
    .add { type = 'frame', direction = 'vertical', style = 'inside_deep_frame' }
    .add { type = 'flow', direction = 'vertical' }
    Gui.set_style(left, {
      vertically_stretchable = true,
      horizontal_align = 'center',
      padding = 10,
      vertical_spacing = 5,
    })

    for _, page in pairs(pages) do
      left.add(page)
    end
    data.left = left
  end

  do -- right
    local right = main_flow
    .add { type = 'frame', name = 'right', style = 'inside_shallow_frame_with_padding' }
    .add { type = 'flow', name = 'flow', direction = 'vertical' }
    Gui.set_style(right, {
      minimal_width = 300,
      minimal_height = 300,
      vertically_stretchable = true,
      horizontally_stretchable = true,
    })
    data.right = right
  end

  Gui.set_data(frame, data)
end

function Public.update_top_button(player)
  if not Config.enabled then
    return
  end

  local button = Gui.add_top_element(player, {
    type = 'sprite-button',
    name = main_button_name,
    sprite = 'item/power-armor-mk2',
    tooltip = {'admin_panel.info_tooltip'},
  })
  button.visible = player.admin
end

function Public.toggle_main_button(player)
  local main_frame = player.gui.screen[main_frame_name]
  if main_frame then
    Gui.destroy(main_frame)
  else
    Public.get_main_frame(player)
  end
end

function Public.close_all_pages(player)
  local frame = player.gui.screen[main_frame_name]
  if not (frame and frame.valid) then
    return
  end

  for _, button in pairs(Gui.get_data(frame).left.children) do
    if button.type == 'button' or button.type == 'sprite-button' then
      button.toggled = false
    end
  end
end

Event.add(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end
  Public.update_top_button(player)
end)

Event.add(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end
  Public.update_top_button(player)
  local frame = player.gui.screen[main_frame_name]
  if (frame and frame.valid and not player.admin) then
    Gui.destroy(frame)
  end
end)

Event.add(defines.events.on_gui_closed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local player = game.get_player(event.player_index)
  if not (player and player.valid) then
    return
  end

  if element.name == main_frame_name then
    Public.toggle_main_button(player)
  end
end)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, function(event)
  Public.toggle_main_button(event.player)
end)

Gui.on_click(close_button_name, function(event)
  Public.toggle_main_button(event.player)
end)

Gui.on_player_show_top(main_button_name, function(event)
  Public.update_top_button(event.player)
end)

return Public
