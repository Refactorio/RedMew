-- Player List Soft Mod
-- Adds a player list sidebar that displays online players along with their online time.
-- @author Denis Zholob (DDDGamer)
-- github: https://github.com/DDDGamer/factorio-dz-softmod
-- ======================================================= --

-- Dependencies
require "gui-2"
require "Time"
require "Colors"



local OWNER = "chpich"

-- Roles
local ROLES = {
    owner = {tag = "Owner", color = Colors.black}, -- server owner
    admin = {tag = "Admin", color = Colors.gray} -- server admin
}

-- Regular player ranks (time in hrs)
local RANKS =
{lvl1 = {time = 0, color = Colors.white, tag = "Engineer Trainee", }, 
lvl2 = {time = 1, color = Colors.green, tag = "Jr. Engineer"}, 
lvl3 = {time = 2, color = Colors.cyan, tag = "Associate Engineer"}, 
lvl4 = {time = 3, color = Colors.blue, tag = "Engineer I"}, 
lvl5 = {time = 4, color = Colors.darkblue, tag = "Intermediate Engineer"}, 
lvl6 = {time = 5, color = Colors.yellow, tag = "Engineer II"}, 
lvl7 = {time = 7, color = Colors.orange, tag = "Sr. Engineer"}, 
lvl8 = {time = 9, color = Colors.darkorange, tag = "Engineer III"}, 
lvl9 = {time = 12, color = Colors.red, tag = "Engineering Specialist"}, 
lvl10 = {time = 15, color = Colors.darkred, tag = "Chief Engineer"}, 
lvl11 = {time = 20, color = Colors.grey, tag = "Sr. Chief Engineer", }}



-- When new player joins add the playerlist btn to their GUI
-- Redraw the playerlist frame to update with the new player
-- @param event on_player_joined_game
function on_player_join(event)
    local player = game.players[event.player_index]
    draw_playerlist_btn(player)
    draw_playerlist_frame()
end

-- On Player Leave
-- Clean up the GUI in case this mod gets removed next time
-- Redraw the playerlist frame to update
-- @param event on_player_left_game
function on_player_leave(event)
    local player = game.players[event.player_index]
    if player.gui.left["frame_playerlist"] ~= nil then
        player.gui.left["frame_playerlist"].destroy()
    end
    if player.gui.top["btn_menu_playerlist"] ~= nil then
        player.gui.top["btn_menu_playerlist"].destroy()
    end
    draw_playerlist_frame()
end

-- Toggle playerlist is called if gui element is playerlist button
-- @param event on_gui_click
local function on_gui_click(event)
    local player = game.players[event.player_index]
    local el_name = event.element.name
    
    if el_name == "btn_menu_playerlist" then
        GUI.toggle_element(player.gui.left["frame_playerlist"])
    end
end


-- Add a player to the GUI list
-- @param player
-- @param p_online
-- @param color
-- @param tag
function add_player_to_list(player, p_online, color, tag)
    local played_hrs = tostring(Time.tick_to_hour(p_online.online_time))
    player.gui.left["frame_playerlist"].add {type = "label", style = "caption_label_style", name = p_online.name, caption = {"", played_hrs, " hr - ", p_online.name, " ", "[" .. tag .. "]"}}
    player.gui.left["frame_playerlist"][p_online.name].style.font_color = color
 p_online.tag = "[" .. tag .. "]"
end

-- Refresh the playerlist after 10 min
-- @param event on_tick
function on_tick(event)
    global.last_refresh = global.last_refresh or 0
    local cur_time = game.tick / 60
    local refresh_period = 10 -- 600 seconds (10 min)
    local refresh_time_passed = cur_time - global.last_refresh
    if refresh_time_passed > refresh_period then
        draw_playerlist_frame()
        global.last_refresh = cur_time
    end
end

-- Event Handlers
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, on_player_join)
Event.register(defines.events.on_player_left_game, on_player_leave)
Event.register(defines.events.on_tick, on_tick)

