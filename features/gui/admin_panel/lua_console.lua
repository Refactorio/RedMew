local Gui = require 'utils.gui'
local Global = require 'utils.global'
local AdminPanel = require 'features.gui.admin_panel.core'

local main_button_name = Gui.uid_name()
local clear_button_name = Gui.uid_name()
local dry_run_button_name = Gui.uid_name()
local confirm_button_name = Gui.uid_name()

local this = {
  last_lua_input = {},
  last_lua_output = {},
}

Global.register(this, function(tbl) this = tbl end)

local pages = AdminPanel.get_pages()
pages[#pages +1] = {
  type = 'sprite-button',
  sprite = 'utility/scripting_editor_icon',
  tooltip = '[font=default-bold]Lua console[/font]',
  name = main_button_name,
  auto_toggle = true,
}

local function draw_gui(player)
  local canvas = AdminPanel.get_canvas(player)
  Gui.clear(canvas)

  this.last_lua_input[player.index] = this.last_lua_input[player.index] or ''
  this.last_lua_output[player.index] = this.last_lua_output[player.index] or ''

  local info = canvas.add { type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
  Gui.set_style(info, { padding = 12, horizontally_stretchable = true })
  info.add { type = 'label', caption = '[font=default-bold][color=green]Input:[/color][/font]' }
  info.add { type = 'label', caption = '  -  no need to append `/c` at the beginning of the code' }
  info.add { type = 'label', caption = '  -  can accept pure strings instead of commands' }
  info.add { type = 'label', caption = '[font=default-bold][color=red]Output:[/color][/font]' }
  info.add { type = 'label', caption = '  -  errors of the code will be displayed here, if any' }

  local input = canvas
  .add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Input' }
  .add { type = 'text-box', name = 'input' }
  input.word_wrap = true
  input.text = this.last_lua_input[player.index]
  Gui.set_style(input, { minimal_height = 240, minimal_width = 460, maximal_height = 800 })

  local output = canvas
  .add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Output' }
  .add { type = 'text-box', name = 'output' }
  output.word_wrap = true
  output.text = this.last_lua_output[player.index]
  Gui.set_style(output, { minimal_height = 60, minimal_width = 460, maximal_height = 120 })

  local button_flow = canvas.add { type = 'flow', direction = 'horizontal' }
  Gui.add_pusher(button_flow)
  button_flow.add { type = 'button', name = clear_button_name, style = 'red_back_button', caption = 'Clear' }
  local dry_run = button_flow.add { type = 'button', name = dry_run_button_name, style = 'forward_button', caption = 'Dry run' }
  local confirm = button_flow.add { type = 'button', name = confirm_button_name, style = 'confirm_double_arrow_button', caption = 'Confirm', tooltip = 'Run input code' }
  Gui.set_style(confirm, { left_margin = -9 })

  Gui.set_data(dry_run, { input = input, output = output })
  Gui.set_data(confirm, { input = input, output = output })
end

local function process_command(event)
  local player = event.player
  local data = Gui.get_data(event.element)
  local input, output = data.input, data.output

  local cmd = input.text
  this.last_lua_input[player.index] = cmd
  rawset(game, 'player', player)

  local f, err, _
  f, err = loadstring(cmd)
  if not f then
    cmd = 'game.players[' .. player.index .. '].print(' .. cmd .. ')'
    f, err = loadstring(cmd)
  end

  if event.element.name ~= dry_run_button_name then
    _, err = pcall(f)
  end
  rawset(game, 'player', nil)

  if err then
    local text = ''
    text = text .. cmd .. '\n'
    text = text .. '----------------------------------------------------------------------\n'
    text = text .. err:sub(1, err:find('\n'))
    output.text = text
    this.last_lua_output[player.index] = text
  end
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

Gui.on_click(dry_run_button_name, process_command)
Gui.on_click(confirm_button_name, process_command)

Gui.on_click(clear_button_name, function(event)
  local player = event.player
  this.last_lua_input[player.index] = ''
  this.last_lua_output[player.index] = ''
  draw_gui(player)
end)
