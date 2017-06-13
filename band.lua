-- Give players the option to set their preferred role as a tag
-- Version 0.1.6
-- https://github.com/Befzz/factorio_random/tree/master/scenarios/befzz_test

-- Requires event.lua to work ( https://github.com/3RaGaming/utils )

-- SETTINGS
local option_band_change_interval = 60 * 3 -- in ticks

-- Role list: "band_roles.lua"
local band_roles = require "band_roles"
local to_print, roles = band_roles.to_print, band_roles.roles

do
  local i = 1
  for _, roledata in pairs(roles) do
    roledata.index = i
    i = i + 1
  end
end


local expand_band_gui
local band_last_change = -option_band_change_interval

-- store current role
local local_role

local function create_band_gui(event)
  local player = game.players[event.player_index]
  if player.gui.top.band_toggle_btn == nil then
    local button = player.gui.top.add { name = "band_toggle_btn", type = "sprite-button", caption = "Tag", style = "dialog_button_style" }
    button.style.font = "default-bold"
    button.style.minimal_height = 38
    button.style.minimal_width = 38
    button.style.top_padding = 2
    button.style.left_padding = 4
    button.style.right_padding = 4
    button.style.bottom_padding = 2

    -- expand_band_gui(player)
  end
end


-- Make a list of random names with roles
local function test_fake_players( t )
  local limit =  math.random(20,120)
  
  local roles_ind = {}
  for role in pairs(roles) do
    table.insert( roles_ind, role)
  end
  
  for i = 1,limit do
    local rolei = math.random(1, #roles_ind)
    local role = roles_ind[rolei]

    table.insert(t[role], 
      {
        "Fake#" .. (tostring(math.random())):sub(3,-math.random(1,10)),
        {
          r=math.random(),
          g=math.random(),
          b=math.random()
        }
      }
    )
  end
end

local function get_random_from_table(tbl)
  return tbl[math.random(1,#tbl)]
end

local function subgui_update_role_counter(gui_parent, count_diff)
  local count_label
  if gui_parent["role_counter"] then
    count_label = gui_parent["role_counter"]
  else 
    count_label = gui_parent.add {type = "label", caption = 0, name = "role_counter", single_line = false}
    count_label.style.font = "default-small-bold"
    count_label.style.maximal_height = 10  
    count_label.style.top_padding = 0
    count_label.style.left_padding = 0
    count_label.style.right_padding = 0
    count_label.style.bottom_padding = 0
    count_label.style.font_color = {r=.55,g=.55,b=.55}
  end
  
  local new_count = tonumber(count_label.caption) + count_diff
  count_label.caption = new_count
  if new_count == 0 then
    count_label.style.visible = false
  else
    count_label.style.visible = true
  end
end

local function subgui_add_player_label(gui_parent, pname, pcolor)
  local color_k = 0.6

  local name_label = gui_parent.add {type = "label", name = "list_players_"..pname, caption = pname, want_ellipsis = true, single_line = false}
  name_label.style.font = "default"
  name_label.style.top_padding = 0
  name_label.style.right_padding = 4
  name_label.style.left_padding = 2
  name_label.style.bottom_padding = 0
  name_label.style.maximal_height = 11
  name_label.style.minimal_height = 11
  name_label.style.maximal_width = 120
  name_label.style.minimal_width = 120
  name_label.style.font_color = {
   r = .4 + pcolor.r * color_k,
   g = .4 + pcolor.g * color_k,
   b = .4 + pcolor.b * color_k,
  }
end

-- dev_icons(ctrl + click): show icon-choose buttons
-- dev_addfakes(alt + click): add random number of player names w/ color
expand_band_gui = function(player, dev_icons, dev_addfakes, right_click)
	player.gui.left.direction = "horizontal"
  local frame = player.gui.left["band_panel"]
  if (frame) then
    frame.destroy()
    
    if player.gui.center["textfield_item_icon_frame"] then
      player.gui.center["textfield_item_icon_frame"].destroy()
    end
    if player.tag ~= "" then
      player.gui.top.band_toggle_btn.tooltip = "Tag: "..player.tag.."\n Right Click to show offline players with tags."
      if player.admin then
        player.gui.top.band_toggle_btn.tooltip = player.gui.top.band_toggle_btn.tooltip.."\n CTRL + Click to explore icons.\n ALT + Click to add fake names"
      end
    end
    return
  end
  
  local player_role = player.tag:sub(2,-2)

  -- Will be filled: { roleN = {{name,color},...} , ...}
  local players_by_role = {}
  
  for role in pairs(roles) do
    players_by_role[role] = {}
  end
  
  if right_click then
    for _, oplayer in pairs(game.players) do
      local prole = oplayer.tag:sub(2,-2)
      if prole ~= "" then
        if oplayer.connected then
          table.insert( players_by_role[prole], {oplayer.name, oplayer.color})
        else
          table.insert( players_by_role[prole], {oplayer.name, {r=0,g=0,b=0}})
        end
      end
    end
  else
    for _, oplayer in pairs(game.connected_players) do
      local prole = oplayer.tag:sub(2,-2)
      if prole ~= "" then
          table.insert( players_by_role[prole], {oplayer.name, oplayer.color})
      end
    end
  end
  

  if dev_addfakes then
    test_fake_players(players_by_role)
  end
  
  player.gui.top.band_toggle_btn.tooltip = ""
  
  local button--reusable variable :D
  local frame = player.gui.left.add { type = "frame", direction = "vertical", name = "band_panel", caption = "Choose your role:"}
  	frame.style.font = "default-listbox"
	frame.style.font_color = { r=0.98, g=0.66, b=0.22}
  
  if dev_icons then
    local choose
    local chooselist = frame.add { type = "flow", direction = "horizontal" }
    -- ["signal"] = {type = "virtual", name = "signal-A"}
    for itype, ivalue in pairs({["item"] = "green-wire", ["entity"] = "medium-spitter", ["tile"] = "grass"}) do
      choose = chooselist.add { type = "choose-elem-button", elem_type = itype, [itype] = ivalue, name = "help_item_icon_choose_"..itype }
      choose.style.minimal_height = 36
      choose.style.minimal_width = 36
      choose.style.top_padding = 2
      choose.style.left_padding = 2
      choose.style.right_padding = 2
      choose.style.bottom_padding = 2
    end
  end
  
  local scroll = frame.add{type = "scroll-pane", name = "scroll", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
  scroll.style.maximal_height = 600
  scroll.style.minimal_width = 250
  scroll.style.bottom_padding = 10
  
  local table_roles = scroll.add{type = "table", name = "table_roles", colspan = 2}
  table_roles.style.horizontal_spacing = 15
  table_roles.style.vertical_spacing = 4
        
        
  local name_label
  local pname
  local pcolor
  
  local show_role_tooltip = math.random() > .5
  
  for role, role_icons in pairs(roles) do
  
    local role_line = table_roles.add { type = "flow", direction = "horizontal" }

    button = role_line.add { type = "sprite-button", sprite = get_random_from_table(role_icons), name = "band_role_"..role, style = "recipe_slot_button_style"}
    button.style.top_padding = 4
    button.style.left_padding = 0
    button.style.right_padding = 0
    button.style.bottom_padding = 4
    if show_role_tooltip and role_icons.tooltip then
      button.tooltip = get_random_from_table( role_icons.tooltip )
    end
    
    local role_cap_line = role_line.add { type = "flow", name = "role_cap_line", direction = "horizontal" }
    role_cap_line.style.max_on_row = 1
         
    local role_label = role_cap_line.add { type = "label", caption = role, single_line = true}
    -- role_label.style.minimal_width = 0
    role_label.style.minimal_height = 0
    role_label.style.maximal_height = 12  
    role_label.style.top_padding = 0
    role_label.style.left_padding = 0
    role_label.style.right_padding = 0
    role_label.style.bottom_padding = 0
    role_label.style.font = "default-bold"
    if role == player_role then
      role_label.style.font_color = {r=.7,g=1,b=.7}
    end
    
    subgui_update_role_counter(role_cap_line, #players_by_role[role])

    local list_players = table_roles.add { type = "flow", direction = "horizontal" }
    list_players.style.max_on_row = 3
    list_players.style.top_padding = 0
    list_players.style.bottom_padding = 7

    if players_by_role[role] then
      for _,pdata in pairs(players_by_role[role]) do
        pname = pdata[1]
        pcolor = pdata[2]
        subgui_add_player_label(list_players, pname, pcolor)
      end
    end
  end
  
  local close_btn_flow = frame.add { type = "flow", direction = "horizontal" }
  button = close_btn_flow.add { type = "button", caption = "Close", name = "band_close" }
  button.style.font = "default-bold"
  button.style.minimal_width = 80
  button.style.maximal_height = 26
  button.style.top_padding = 0
  button.style.left_padding = 2
  button.style.right_padding = 2
  button.style.bottom_padding = 0
  
  button = close_btn_flow.add { type = "button", caption = "Clear tag", name = "band_clear" }
  button.style.font = "default-bold"
  button.style.font_color = {r=1, g=.7, b=.7}
  button.style.minimal_width = 80
  button.style.maximal_height = 28
  button.style.top_padding = 0
  button.style.left_padding = 2
  button.style.right_padding = 2
  button.style.bottom_padding = 0
end

local function print_role_change(name, role)
  local str = nil
  if role then
    if roles[role].verbs and math.random() > 0.7 then
      str = (get_random_from_table(to_print))
    else
      str = ("[%band] squad has `" .. get_random_from_table(roles[role].verbs) .. "` with %name.")
    end
    str = str:gsub('%%band', role)
  --[[elseif local_role then
    str = "%name is not in a squad anymore"
    if math.random() > .9 then
      str = str .. " (["..local_role.."] squad will miss you)."
    end]]--
  end
  
  if str then
    str = str:gsub('%%name', name)
    game.print(str)
  end
end

-- messy (bcs WIP)
local function update_player_role(player, role)

	global.update_player_name = player
	global.update_player_role_name = role
	
  if global.update_player_role_name then
    global.update_player_name.tag = "[" .. global.update_player_role_name .. "]"
  else
    global.update_player_name.tag = ""
  end
    
  -- update other player gui (counter & label)
 --[[
  for _,cplayer in pairs( game.connected_players ) do
    if cplayer.gui.left.band_panel then
      local troles = cplayer.gui.left.band_panel.scroll.table_roles

      if local_role then
        local player_label = troles.children[roles[local_role].index*2]["list_players_" .. cplayer.name]
        if player_label then
          player_label.destroy()
        end
      end
      
      if global.update_player_role_name then
        subgui_add_player_label( troles.children[roles[global.update_player_role_name].index*2], cplayer.name, cplayer.color)
        subgui_update_role_counter( troles.children[roles[global.update_player_role_name].index*2 - 1].role_cap_line, 1)
      end
      
      if local_role then
        subgui_update_role_counter( troles.children[roles[local_role].index*2 - 1].role_cap_line, -1)
      end
    end
  end

  
  -- update local player gui (role label color)
  local troles_local = player.gui.left.band_panel.scroll.table_roles
  
  if local_role then
    troles_local.children[roles[local_role].index*2 - 1].children[2].children[1].style.font_color = {r=1,g=1,b=1}
  end
  
  if global.update_player_role_name then
    troles_local.children[roles[global.update_player_role_name].index*2 - 1].children[2].children[1].style.font_color = {r=.7,g=1,b=.7}
  end
--]]
 
  print_role_change(global.update_player_name.name, global.update_player_role_name)
  expand_band_gui(player)
  expand_band_gui(player)
  
  local_role = role
end

local function on_gui_click(event)
  if not (event and event.element and event.element.valid) then return end
  local player = game.players[event.element.player_index]
  local name = event.element.name
  
  if (name == "band_toggle_btn") then
    --player, dev_icons, dev_addfakes
    expand_band_gui(player, 
      player.admin and event.control, 
      player.admin and event.alt,
      event.button == defines.mouse_button_type.right)
  end

  if (name == "band_close") then
    expand_band_gui(player)
    return
  end
  
  if (name == "band_clear") then
  
    update_player_role(player, nil)
    
    player.gui.top.band_toggle_btn.caption = "Tag"
    player.gui.top.band_toggle_btn.tooltip = ""
    player.gui.top.band_toggle_btn.sprite = ""
    -- expand_band_gui(player)
    return
  end
  
  --role button clicked
  if name:find("band_role_") == 1 then
    if not player.admin and event.tick - band_last_change < option_band_change_interval then
      player.print("Too fast! Please wait... " .. math.floor(1+(band_last_change + option_band_change_interval - event.tick)/60).." s.")
      return
    end
    local _,role_ind_start = name:find("band_role_")
    local name_role = name:sub(role_ind_start + 1)
    
    if player.tag:find(name_role) then
      -- current tag = new tag
      return
    end
    
    for role, role_icons in pairs(roles) do
      if (name_role == role) then
        band_last_change = event.tick
               
        player.gui.top.band_toggle_btn.caption = ""
        player.gui.top.band_toggle_btn.sprite = event.element.sprite  --get_random_from_table(role_icons)
		
        update_player_role(player, role)        
        -- expand_band_gui(player)
      end
    end
  end
end

--handle choose-item button
local function on_gui_elem_changed(event)
  if not (event and event.element and event.element.valid) then return end
  local player = game.players[event.element.player_index]
  local name = event.element.name
  if name:find("help_item_icon_choose") then
    if player.gui.center["textfield_item_icon_frame"] then
      player.gui.center["textfield_item_icon_frame"].destroy()
    end
    if event.element.elem_type and event.element.elem_value then
      local frame = player.gui.center.add{ type = "frame", name = "textfield_item_icon_frame", caption = "SpritePath"}
      frame.style.minimal_width = 310
      local textfield 
      -- if type(event.element.elem_value ) == 'table' then
        -- textfield = frame.add { name = "textfield_item_icon", type = "textfield", text = "virtual-signal/" .. event.element.elem_value.name }
      -- else
        textfield = frame.add { name = "textfield_item_icon", type = "textfield", text = event.element.elem_type .. "/" .. event.element.elem_value }
      -- end
      
      --buggy
      textfield.style.minimal_width = 300
    end
  end
  
end

Event.register(defines.events.on_gui_elem_changed, on_gui_elem_changed)
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, create_band_gui)
