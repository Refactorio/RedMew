local AdminPanel = require 'features.gui.admin_panel.core'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local math = require 'utils.math'
local Surface = require 'features.gui.admin_panel.functions'.surface
local RS = require 'map_gen.shared.redmew_surface'

local main_button_name = Gui.uid_name()
local slider_tag_name = Gui.uid_name()

local on_performance_speed = Gui.uid_name()
local on_slow_down = Gui.uid_name()
local on_speed_up = Gui.uid_name()
local on_pollution_ageing = Gui.uid_name()
local on_pollution_diffusion = Gui.uid_name()
local on_pollution_attack_modifier = Gui.uid_name()
local on_evolution_value = Gui.uid_name()
local on_evolution_destroy_factor= Gui.uid_name()
local on_evolution_time_factor = Gui.uid_name()
local on_map_chart = Gui.uid_name()
local on_map_hide = Gui.uid_name()
local on_map_reveal = Gui.uid_name()
local on_map_rechart = Gui.uid_name()

local pages = AdminPanel.get_pages()
pages[#pages +1] = {
  type = 'sprite-button',
  sprite = 'utility/surface_editor_icon',
  tooltip = '[font=default-bold]Map manager[/font]',
  name = main_button_name,
  auto_toggle = true,
}

local function make_button(parent, params)
  local button = parent.add {
    type = 'button',
    caption = params.caption,
    name = params.name,
    tooltip = params.tooltip,
  }
  Gui.set_style(button, {
    horizontally_stretchable = true,
  })
  return button
end

local function make_slider(parent, params)
  local flow = parent.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(flow, { vertical_align = 'center', maximal_width = 467 })
  local button = flow.add(params.button)
  Gui.set_style(button, { width = 150 })
  params.slider.value = math.clamp(params.value, params.slider.minimum_value, params.slider.maximum_value)
  local slider = flow.add(params.slider)
  slider.tags = { name = slider_tag_name }
  slider.tooltip = string.format(params.format, slider.slider_value)
  Gui.set_style(slider, { width = 250 })
  local label = flow.add { type = 'label', caption = string.format(params.format, params.value), tooltip = params.tooltip or 'Current value' }
  Gui.set_style(label, { width = 52, horizontal_align = 'right' })

  local data = { button = button, slider = slider, label = label, format = params.format }
  Gui.set_data(button, data)
  Gui.set_data(slider, data)
end

local function update_slider(element)
  local data = Gui.get_data(element)
  data.label.caption = string.format(data.format, data.slider.slider_value)
  return data.slider.slider_value
end

local function draw_gui(player)
  local canvas = AdminPanel.get_canvas(player)
  Gui.clear(canvas)

  local ms = game.map_settings
  local evolution = ms.enemy_evolution
  local pollution = ms.pollution

  local row_1 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Game speed' }
  make_slider(row_1, {
    button = {
      type = 'button',
      name = on_performance_speed,
      caption = 'Performance speed',
      tooltip = {'command_description.performance_scale_set'},
    },
    slider = {
      type = 'slider',
      minimum_value = 0.05,
      maximum_value = 1,
      value_step = 0.05,
    },
    format = '%.2f',
    value = game.speed,
  })
  make_slider(row_1, {
    button = {
      type = 'button',
      name = on_slow_down,
      caption = 'Slow down'
    },
    slider = {
      type = 'slider',
      minimum_value = 0.05,
      maximum_value = 1,
      value_step = 0.05,
    },
    format = '%.2f',
    value = game.speed,
  })
  make_slider(row_1, {
    button = {
      type = 'button',
      name = on_speed_up,
      caption = 'Speed up'
    },
    slider = {
      type = 'slider',
      minimum_value = 1,
      maximum_value = 10,
      value_step = 0.5,
    },
    format = '%.2f',
    value = game.speed,
  })

  local row_2 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Pollution' }
  make_slider(row_2, {
    button = {
      type = 'button',
      name = on_pollution_ageing,
      caption = 'Ageing'
    },
    slider = {
      type = 'slider',
      style = 'notched_slider',
      minimum_value = 0.1,
      maximum_value = 1,
      value_step = 0.1,
    },
    format = '%.2f',
    value = pollution.ageing,
  })
  make_slider(row_2, {
    button = {
      type = 'button',
      name = on_pollution_diffusion,
      caption = 'Diffusion ratio'
    },
    slider = {
      type = 'slider',
      style = 'notched_slider',
      minimum_value = 0,
      maximum_value = 0.1,
      value_step = 0.02,
    },
    format = '%.2f',
    value = pollution.diffusion_ratio,
  })
  make_slider(row_2, {
    button = {
      type = 'button',
      name = on_pollution_attack_modifier,
      caption = 'Atk. modifier'
    },
    slider = {
      type = 'slider',
      style = 'notched_slider',
      minimum_value = 0.1,
      maximum_value = 1,
      value_step = 0.1,
    },
    format = '%.2f',
    value = pollution.enemy_attack_pollution_consumption_modifier,
  })

  local row_3 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Evolution' }
  make_slider(row_3, {
    button = {
      type = 'button',
      name = on_evolution_value,
      caption = 'Enemy evolution'
    },
    slider = {
      type = 'slider',
      minimum_value = 0,
      maximum_value = 100,
      value_step = 0.01,
    },
    format = '%.2f',
    value = game.forces.enemy.get_evolution_factor(RS.get_surface_name()) * 100,
    tooltip = 'Current value, %',
  })
  make_slider(row_3, {
    button = {
      type = 'button',
      name = on_evolution_destroy_factor,
      caption = 'Destroy factor'
    },
    slider = {
      type = 'slider',
      style = 'notched_slider',
      minimum_value = 0.00,
      maximum_value = 1.00,
      value_step = 0.05,
    },
    format = '%.2f',
    value = evolution.destroy_factor * 100,
    tooltip = 'Current value, x100',
  })
  make_slider(row_3, {
    button = {
      type = 'button',
      name = on_evolution_time_factor,
      caption = 'Time factor'
    },
    slider = {
      type = 'slider',
      minimum_value = 0.000,
      maximum_value = 0.100,
      value_step = 0.002,
    },
    format = '%.3f',
    value = evolution.time_factor * 1000,
    tooltip = 'Current value, x1000',
  })

  local row_4 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Exploration' }
  make_slider(row_4, {
    button = {
      type = 'button',
      name = on_map_chart,
      caption = 'Chart map'
    },
    slider = {
      type = 'slider',
      minimum_value = 1,
      maximum_value = 5000,
      value_step = 1,
    },
    format = '%d',
    value = 0,
  })
  local table_4 = row_4.add { type = 'table', column_count = 3 }
  for _, button in pairs({
    { name = on_map_hide, caption = 'Hide all' },
    { name = on_map_reveal, caption = 'Reveal all' },
    { name = on_map_rechart, caption = 'Re-chart all' },
  }) do make_button(table_4, button) end
end

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

Event.add(defines.events.on_gui_value_changed, function(event)
  local element = event.element
  if not (element and element.valid) then
    return
  end

  local tag = element.tags and element.tags.name
  if not tag or tag ~= slider_tag_name then
    return
  end

  local data = Gui.get_data(element)
  data.slider.tooltip = string.format(data.format, data.slider.slider_value)
end)

Gui.on_click(on_performance_speed, function(event)
  local element = event.element
  local value = update_slider(element)
  Surface.performance_scale_set(value)
end)

Gui.on_click(on_slow_down, function(event)
  local element = event.element
  local value = update_slider(element)
  game.speed = value
  game.print(string.format('Game speed: %.2f', game.speed))
end)

Gui.on_click(on_speed_up, function(event)
  local element = event.element
  local value = update_slider(element)
  game.speed = value
  game.print(string.format('Game speed: %.2f', game.speed))
end)

Gui.on_click(on_pollution_ageing, function(event)
  local element = event.element
  local value = update_slider(element)
  game.map_settings.pollution.ageing = value
end)

Gui.on_click(on_pollution_diffusion, function(event)
  local element = event.element
  local value = update_slider(element)
  game.map_settings.pollution.diffusion_ratio = value
end)

Gui.on_click(on_pollution_attack_modifier, function(event)
  local element = event.element
  local value = update_slider(element)
  game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = value
end)

Gui.on_click(on_evolution_value, function(event)
  local element = event.element
  local value = update_slider(element)
  game.forces.enemy.set_evolution_factor(value / 100, RS.get_surface_name())
end)

Gui.on_click(on_evolution_destroy_factor, function(event)
  local element = event.element
  local value = update_slider(element)
  game.map_settings.enemy_evolution.destroy_factor = value / 100
end)

Gui.on_click(on_evolution_time_factor, function(event)
  local element = event.element
  local value = update_slider(element)
  game.map_settings.enemy_evolution.time_factor = value / 1000
end)

Gui.on_click(on_map_chart, function(event)
  local element = event.element
  local player = event.player
  local value = update_slider(element)
  Surface.chart_map(player, value)
end)

Gui.on_click(on_map_hide, function(event)
  local player = event.player
  Surface.hide_all(player)
end)

Gui.on_click(on_map_reveal, function(event)
  local player = event.player
  Surface.reveal_all(player)
end)

Gui.on_click(on_map_rechart, function(event)
  local player = event.player
  Surface.rechart_all(player)
end)
