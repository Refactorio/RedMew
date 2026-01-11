local Actions = require 'features.gui.admin_panel.functions'.actions
local AdminPanel = require 'features.gui.admin_panel.core'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Table = require 'utils.table'

local main_button_name = Gui.uid_name()
local selection_switch_name = Gui.uid_name()
local selection_dropdown_name = Gui.uid_name()

local on_cheat_mode = Gui.uid_name()
local on_show_reports = Gui.uid_name()
local on_create_pool = Gui.uid_name()
local on_revive_ghosts = Gui.uid_name()
local on_save_game = Gui.uid_name()
local on_delete_blueprints = Gui.uid_name()
local on_destroy_speakers = Gui.uid_name()
local on_remove_biters = Gui.uid_name()
local on_remove_enemies = Gui.uid_name()
local on_add_regular = Gui.uid_name()
local on_add_probation = Gui.uid_name()
local on_add_moderator = Gui.uid_name()
local on_jail_player = Gui.uid_name()
local on_remove_regular = Gui.uid_name()
local on_remove_probation = Gui.uid_name()
local on_remove_moderator = Gui.uid_name()
local on_unjail_player = Gui.uid_name()
local on_trust_all = Gui.uid_name()
local on_mute_player = Gui.uid_name()
local on_unmute_player = Gui.uid_name()
local on_purge_player = Gui.uid_name()
local on_invoke_player = Gui.uid_name()
local on_goto_player = Gui.uid_name()
local on_spank_player = Gui.uid_name()
local on_ban_player = Gui.uid_name()
local on_kick_player = Gui.uid_name()
local on_create_oil_field = Gui.uid_name()
local on_toggle_blueprints = Gui.uid_name()
local on_create_pollution = Gui.uid_name()

local this = {
  ---@type table<number, table< index: number, name: string >>
  player_selection = {},
  ---@type table<number, string>
  selection_switch = {},
  ---@type table<number, table<string>>
  player_ban_items = {},
}

Global.register(this, function(tbl) this = tbl end)

local pages = AdminPanel.get_pages()
pages[#pages +1] = {
  type = 'sprite-button',
  sprite = 'entity/character',
  tooltip = '[font=default-bold]Player manager[/font]',
  name = main_button_name,
  auto_toggle = true,
  tags = { admin_only = false },
}

local BAN_ITEMS = {}
for _, text in pairs({
  'damaging base',
  'griefing',
  'insulting other players',
  'mass deconstruction',
  'offensive language',
  'resource hoarding',
  'tanking server UPS',
  'toxic behavior',
}) do table.insert(BAN_ITEMS, { name = Gui.uid_name(), caption = text }) end

local GENERAL_ACTION_ITEMS = {
  { name = on_cheat_mode,        caption = 'Cheat mode',        admin_only = true,  style = 'button',       tooltip = { 'cmd_tooltip.cheat_mode' } },
  { name = on_show_reports,      caption = 'Show reports',      admin_only = true,  style = 'button',       tooltip = { 'cmd_tooltip.show_reports' } },
  { name = on_toggle_blueprints, caption = 'Blueprints ON/OFF', admin_only = true,  style = 'button',       tooltip = { 'cmd_tooltip.toggle_blueprints' } },
  { name = on_create_pool,       caption = 'Create pool',       admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.create_pool' } },
  { name = on_create_oil_field,  caption = 'Create oil field',  admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.create_oil_field' } },
  { name = on_create_pollution,  caption = 'Spawn pollution',   admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.spawn_pollution' } },
  { name = on_save_game,         caption = 'Save game',         admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.save_game' } },
  { name = on_revive_ghosts,     caption = 'Revive ghosts',     admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.revive_ghosts' } },
  { name = on_remove_biters,     caption = 'Kill biter units',  admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.kill_units' } },
  { name = on_destroy_speakers,  caption = 'Destroy speakers',  admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.destroy_speakers' } },
  { name = on_delete_blueprints, caption = 'Destroy ghosts',    admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.destroy_ghosts' } },
  { name = on_remove_enemies,    caption = 'Kill all enemies',  admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.kill_enemies' } },
}

local PLAYER_MANAGEMENT_ITEMS = {
  { name = on_add_probation,    caption = 'Add probation',    admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.add_probation' } },
  { name = on_add_regular,      caption = 'Add regular',      admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.add_regular' } },
  { name = on_jail_player,      caption = 'Jail player',      admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.jail_player' } },
  { name = on_remove_probation, caption = 'Remove probation', admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.remove_probation' } },
  { name = on_remove_regular,   caption = 'Remove regular',   admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.remove_regular' } },
  { name = on_unjail_player,    caption = 'Unjail player',    admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.unjail_player' } },
  { name = on_mute_player,      caption = 'Mute player',      admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.mute_player' } },
  { name = on_unmute_player,    caption = 'Unmute player',    admin_only = false, style = 'green_button', tooltip = { 'cmd_tooltip.unmute_player' } },
  { name = on_purge_player,     caption = 'Purge player',     admin_only = false, style = 'red_button',   tooltip = { 'cmd_tooltip.purge_player' } },
  { name = on_add_moderator,    caption = 'Add moderator',    admin_only = true,  style = 'green_button', tooltip = { 'cmd_tooltip.add_moderator' } },
  { name = on_remove_moderator, caption = 'Remove moderator', admin_only = true,  style = 'red_button',   tooltip = { 'cmd_tooltip.remove_moderator' } },
  { name = on_trust_all,        caption = 'Trust all',        admin_only = true,  style = 'green_button', tooltip = { 'cmd_tooltip.trust_all' } },
  { name = on_invoke_player,    caption = 'Invoke player',    admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.invoke_player' } },
  { name = on_goto_player,      caption = 'Goto player',      admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.goto_player' } },
  { name = on_spank_player,     caption = 'Spank player',     admin_only = false, style = 'button',       tooltip = { 'cmd_tooltip.spank_player' } },
}

local function get_selected_player(player)
  return this.player_selection[player.index].name or '__NIL__'
end

local function get_player_list(player_index)
  local player_list = { '-- ▼ --  select player  -- ▼ --' }
  local mode = this.selection_switch[player_index] or 'none'
  if mode == 'none' then -- all
    for _, p in pairs(game.players) do
      player_list[#player_list +1] = p.name
    end
  elseif mode == 'left' then --- online
    for _, p in pairs(game.connected_players) do
      player_list[#player_list +1] = p.name
    end
  elseif mode == 'right' then -- offline
    for _, p in pairs(game.players) do
      if not p.connected then
        player_list[#player_list +1] = p.name
      end
    end
  end
  return player_list
end

local function generate_ban_text(player)
  local items = this.player_ban_items[player.index]
  return table.concat(items, ', ') .. '. To appeal ban visit refactorio.de/discord #helpdesk.'
end

local function make_button(parent, params)
  local button = parent.add {
    type = 'button',
    caption = params.caption,
    name = params.name,
    tooltip = params.tooltip,
    style = params.style or 'button'
  }
  Gui.set_style(button, {
    horizontally_stretchable = true,
  })
  return button
end

local function make_checkbox(parent, params)
  local checkbox = parent.add {
    type = 'checkbox',
    caption = params.caption,
    name = params.name,
    tooltip = params.tooltip,
    state = params.state or false,
  }
  Gui.set_style(checkbox, {
    horizontally_stretchable = true,
  })
  return checkbox
end

local function make_player_dropdown(parent)
  local player_index = parent.player_index
  local player_list = get_player_list(player_index)
  local selection_data = this.player_selection[player_index]
  if selection_data.index > #player_list then
    selection_data.index = 1
  end
  selection_data.name = player_list[selection_data.index]

  local selection_flow = parent.add { type = 'flow', direction = 'horizontal' }
  Gui.set_style(selection_flow, { vertical_align = 'center' })

  selection_flow.add { type = 'label', caption = '[font=default-small][color=255,230,192]ONLINE[/color][/font]' }
  selection_flow.add { type = 'switch', name = selection_switch_name, switch_state = this.selection_switch[player_index], allow_none_state = true }
  selection_flow.add { type = 'label', caption = '[font=default-small][color=255,230,192]OFFLINE[/color][/font]' }

  local dropdown = selection_flow.add { type = 'drop-down', name = selection_dropdown_name, selected_index = selection_data.index, items = player_list }
  Gui.set_style(dropdown, { horizontally_stretchable = true })
  return selection_flow
end

local function draw_gui(player)
  local canvas = AdminPanel.get_canvas(player)
  Gui.clear(canvas)

  this.player_selection[player.index] = this.player_selection[player.index] or { index = 1 }
  this.selection_switch[player.index] = this.selection_switch[player.index] or 'none'
  this.player_ban_items[player.index] = this.player_ban_items[player.index] or {}

  local row_1 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'General actions' }
  local table_1 = row_1.add { type = 'table', column_count = 3 }
  for _, button in pairs(GENERAL_ACTION_ITEMS) do
    local element = make_button(table_1, button)
    if button.admin_only then
      AdminPanel.admin_only(element)
    end
  end

  local row_2 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Players management' }
  local table_2 = row_2.add { type = 'table', column_count = 3 }
  for _, button in pairs(PLAYER_MANAGEMENT_ITEMS) do
    local element = make_button(table_2, button)
    if button.admin_only then
      AdminPanel.admin_only(element)
    end
  end
  make_player_dropdown(row_2)

  local row_3 = canvas.add { type = 'frame', style = 'bordered_frame', direction = 'vertical', caption = 'Players kick & ban' }
  local table_3 = row_3.add { type = 'table', column_count = 2 }
  for _, item in pairs(BAN_ITEMS) do
    make_checkbox(table_3, {
      caption = item.caption,
      name = item.name,
      state = Table.contains(this.player_ban_items[player.index], item.caption),
    })
  end
  make_player_dropdown(row_3)

  local textbox = row_3.add { type = 'text-box', text = generate_ban_text(player) }
  Gui.set_style(textbox, { minimal_width = 460, maximal_width = 460, minimal_height = 72, horizontally_stretchable = true, vertically_stretchable = true })
  textbox.word_wrap = true

  local flow_3 = row_3.add { type = 'flow', direction = 'horizontal' }
  Gui.add_pusher(flow_3)
  local kick_button = flow_3.add { type = 'button', name = on_kick_player, style = 'red_back_button', caption = 'Kick player', tooltip = { 'cmd_tooltip.kick_player' } }
  Gui.set_data(kick_button, { textbox = textbox })
  local ban_button = flow_3.add { type = 'button', name = on_ban_player, style = 'red_confirm_button', caption = 'Ban player', tooltip = { 'cmd_tooltip.ban_player' } }
  Gui.set_data(ban_button, { textbox = textbox })
  AdminPanel.admin_only(ban_button)
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

Gui.on_switch_state_changed(selection_switch_name, function(event)
  local player = event.player
  this.selection_switch[player.index] = event.element.switch_state
  this.player_selection[player.index].index = 1
  draw_gui(player)
end)

Gui.on_selection_state_changed(selection_dropdown_name, function(event)
  local player = event.player
  local element = event.element
  this.player_selection[player.index].index = element.selected_index
  draw_gui(player)
end)

for _, ban_item in pairs(BAN_ITEMS) do
  Gui.on_checked_state_changed(ban_item.name, function(event)
    local player = event.player
    local element = event.element
    if element.state then
      table.insert(this.player_ban_items[player.index], element.caption)
    else
      Table.remove_element(this.player_ban_items[player.index], element.caption)
    end
    draw_gui(player)
  end)
end

Gui.on_click(on_ban_player, function(event)
  local data = Gui.get_data(event.element)
  local target_name = get_selected_player(event.player)
  Actions.ban_player(target_name, data.textbox.text, event.player)
end)

Gui.on_click(on_kick_player, function(event)
  local data = Gui.get_data(event.element)
  local target_name = get_selected_player(event.player)
  Actions.kick_player(target_name, data.textbox.text, event.player)
end)

Gui.on_click(on_cheat_mode, function(event)
  Actions.toggle_cheat_mode(nil, event.player)
end)

Gui.on_click(on_show_reports, function(event)
  Actions.show_reports(nil, event.player)
end)

Gui.on_click(on_toggle_blueprints, function(event)
  Actions.toggle_blueprint_permissions(event.player)
end)

Gui.on_click(on_create_pool, function(event)
  Actions.create_pool(nil, event.player)
end)

Gui.on_click(on_create_oil_field, function(event)
  Actions.create_oil_field(event.player)
end)

Gui.on_click(on_create_pollution, function(event)
  Actions.create_pollution(event.player)
end)

Gui.on_click(on_revive_ghosts, function(event)
  Actions.revive_ghosts({ radius = 32 * 10 }, event.player)
end)

Gui.on_click(on_save_game, function(event)
  Actions.save_game(nil, event.player)
end)

Gui.on_click(on_delete_blueprints, function(event)
  Actions.remove_all_ghost_entities(event.player)
end)

Gui.on_click(on_destroy_speakers, function(event)
  Actions.destroy_all_speakers(event.player)
end)

Gui.on_click(on_remove_biters, function(event)
  Actions.kill_all_enemy_units(event.player)
end)

Gui.on_click(on_remove_enemies, function(event)
  Actions.kill_all_enemies(event.player)
end)

Gui.on_click(on_add_regular, function(event)
  local target_name = get_selected_player(event.player)
  Actions.regular_add({ player = target_name, actor = event.player.name }, event.player)
end)

Gui.on_click(on_add_probation, function(event)
  local target_name = get_selected_player(event.player)
  Actions.probation_add({ player = target_name, actor = event.player.name }, event.player)
end)

Gui.on_click(on_jail_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.jail_player({ player = target_name }, event.player)
end)

Gui.on_click(on_remove_regular, function(event)
  local target_name = get_selected_player(event.player)
  Actions.regular_remove({ player = target_name, actor = event.player.name }, event.player)
end)

Gui.on_click(on_remove_probation, function(event)
  local target_name = get_selected_player(event.player)
  Actions.probation_remove({ player = target_name, actor = event.player.name }, event.player)
end)

Gui.on_click(on_unjail_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.unjail_player({ player = target_name }, event.player)
end)

Gui.on_click(on_spank_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.spank(target_name, event.player)
end)

Gui.on_click(on_invoke_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.invoke_player({ player = target_name }, event.player)
end)

Gui.on_click(on_add_moderator, function(event)
  local target_name = get_selected_player(event.player)
  Actions.moderator_add({ player = target_name }, event.player)
end)

Gui.on_click(on_remove_moderator, function(event)
  local target_name = get_selected_player(event.player)
  Actions.moderator_remove({ player = target_name }, event.player)
end)

Gui.on_click(on_trust_all, function(event)
  Actions.regular_add_all({}, event.player)
end)

Gui.on_click(on_mute_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.mute_add({ player = target_name }, event.player)
end)

Gui.on_click(on_unmute_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.mute_remove({ player = target_name }, event.player)
end)

Gui.on_click(on_purge_player, function(event)
  local target_name = get_selected_player(event.player)
  Actions.purge_player({ player = target_name }, event.player)
end)

Event.add(defines.events.on_player_removed, function(event)
  this.player_selection[event.player_index] = nil
  this.selection_switch[event.player_index] = nil
  this.player_ban_items[event.player_index] = nil
end)
