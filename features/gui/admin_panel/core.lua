local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local Config = require 'config'.admin_panel
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

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

local Public = {
  events = {
    on_admin_gui_closed = Event.generate_event_name('on_admin_gui_closed')
  }
}

Public._main_frame_name = main_frame_name

function Public.get_pages()
  return pages
end

function Public.get_canvas(player)
  return Gui.get_data(Public.get_main_frame(player)).right
end

function Public.get_main_frame(player)
  local frame = Gui.get_panel(player, main_frame_name)
  if frame then
    return frame
  end

  local content
  frame, content = Gui.add_panel(player, {
    name = main_frame_name,
    caption = 'Admin panel',
    toggle_name = main_button_name,
    frameless = true,
  })

  local data = {}

  local main_flow = content.add { type = 'flow', name = 'flow', direction = 'horizontal' }
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
      local element = left.add(page)
      if page.tags and page.tags.admin_only then
        Public.admin_only(element)
      end
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

  -- open on the first page the player can see, rather than on an empty canvas
  for _, button in pairs(data.left.children) do
    if button.visible then
      button.toggled = true
      Gui.raise_click(button, player)
      break
    end
  end
end

--- Where to open a window beside the panel, or nil when the panel is docked.
function Public.get_main_frame_location(player, offset)
  if not offset then
    offset = { x = 500, y = -100 }
  end
  local frame = Gui.get_panel(player, main_frame_name)
  if frame and frame.parent == player.gui.screen then
    return {
      x = frame.location.x + 500 + offset.x,
      y = frame.location.y + offset.y
    }
  end
  return nil
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
  button.visible = Rank.equal_or_greater_than(player.name, Ranks.moderator)
end

function Public.toggle_main_button(player)
  local main_frame = Gui.get_panel(player, main_frame_name)
  local button = Gui.get_top_element(player, main_button_name)
  if main_frame then
    button.toggled = false
    Gui.destroy(main_frame)
    script.raise_event(Public.events.on_admin_gui_closed, {
      player = player,
    })
  else
    button.toggled = true
    Public.get_main_frame(player)
  end
end

function Public.close_all_pages(player)
  local frame = Gui.get_panel(player, main_frame_name)
  if not frame then
    return
  end

  for _, button in pairs(Gui.get_data(frame).left.children) do
    if button.type == 'button' or button.type == 'sprite-button' then
      button.toggled = false
    end
  end
end

function Public.admin_only(element)
  local player = game.get_player(element.player_index)
  element.visible = Rank.equal_or_greater_than(player.name, Ranks.admin)
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
  local frame = Gui.get_panel(player, main_frame_name)
  if (frame and not player.admin) then
    Gui.destroy(frame)
    Gui.get_top_element(player, main_button_name).toggled = false
  end
end)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Gui.on_click(main_button_name, function(event)
  Public.toggle_main_button(event.player)
end)

Gui.on_player_show_top(main_button_name, function(event)
  Public.update_top_button(event.player)
end)

return Public
