-- Dependencies
require "gui-2"
require "Time"

-- Master button controlls the visibility of the readme window
local MASTER_BTN = {name = "btn_readme", caption = "Read Me", tooltip = "Server rules, information, and more"}
-- Master frame(window), holds all the contents
local MASTER_FRAME = {name = "frame_readme"}

-- Tabs and the corresponding buttons to put in the master frame
local FRAME_TABS = {
    rules = {btn = {name = "btn_readme_rules", caption = "Server Rules", tooltip = ""}, win = {name = "win_readme_rules"}},
    comm = {btn = {name = "btn_readme_help", caption = "Info", tooltip = ""}, win = {name = "win_readme_help"}},
    resources = {btn = {name = "btn_readme_resources", caption = "Changelog", tooltip = ""}, win = {name = "win_readme_resources"}},
    players = {btn = {name = "btn_readme_players", caption = "Players", tooltip = ""}, win = {name = "win_readme_players"}},
    about = {btn = {name = "btn_readme_about", caption = "About", tooltip = ""}, win = {name = "win_readme_about"}},
    close = {
        btn = {name = "btn_readme_close", caption = "Close", tooltip = ""},
        win = {name = "win_readme_close"} -- no window created, just for consistency to use in loop
    }
}

-- Static Content
local CONTENT = {
					rules = {""}, 
					comm = {""}, 
					resources = {""}, 
					about = {""}
				}

-- On Player Join
-- Display the master button, and show rules if new player
-- @param event on_player_joined_game
function on_player_join(event)
    local player = game.players[event.player_index]
    draw_master_readme_btn(player)
    -- Force a gui refresh in case there where updates
    if player.gui.center[MASTER_FRAME.name] ~= nil then
        player.gui.center[MASTER_FRAME.name].destroy()
    end
    -- Show readme window (rules) when player (not admin) first joins, but not at later times
    if not player.admin and Time.tick_to_min(player.online_time) < 1 then
        draw_master_readme_frame(player, FRAME_TABS.rules.win.name)
    end
end

-- On Player Leave
-- Clean up the GUI in case this mod gets removed next time
-- @param event on_player_left_game
function on_player_leave(event)
    local player = game.players[event.player_index]
    if player.gui.center[MASTER_FRAME.name] ~= nil then
        player.gui.center[MASTER_FRAME.name].destroy()
    end
    if player.gui.top[MASTER_BTN.name] ~= nil then
        player.gui.top[MASTER_BTN.name].destroy()
    end
end

-- On GUI Click
-- Depending of what button was click open a different tab
-- @param event on_gui_click
function on_gui_click(event)
    local player = game.players[event.player_index]
    local el_name = event.element.name
    -- Master frame gui button?
    if el_name == MASTER_BTN.name then
        -- Call toggle if frame has been created
        if (player.gui.center[MASTER_FRAME.name] ~= nil) then
            GUI.toggle_element(player.gui.center[MASTER_FRAME.name])
        else
            -- Call create if it hasnt
            draw_master_readme_frame(player, FRAME_TABS.rules.win.name)
        end
    end
    -- One of the tabs?
    for i, frame_tab in pairs(FRAME_TABS) do
        if el_name == frame_tab.btn.name then
            draw_master_readme_frame(player, frame_tab.win.name)
        end
    end
end

-- Draws the master readme button on the top of the screen
-- @param player
function draw_master_readme_btn(player)
    if player.gui.top[MASTER_BTN.name] == nil then
        player.gui.top.add {type = "button", name = MASTER_BTN.name, caption = MASTER_BTN.caption, tooltip = MASTER_BTN.tooltip}
    end
end

-- Draws the master frame and a tab inside it base on arg
-- *Recursive (only 1 deep)
-- @param player
-- @param window_name - which window to display in the frame
function draw_master_readme_frame(player, window_name)
    -- Master frame is already created, just draw a new tab
    if player.gui.center[MASTER_FRAME.name] ~= nil then
        -- Rules
        if window_name == FRAME_TABS.rules.win.name then
            -- Comm
            draw_static_content(player.gui.center[MASTER_FRAME.name]["scroll_content"], CONTENT.rules)
        elseif window_name == FRAME_TABS.comm.win.name then
            -- Resourses
            draw_static_content(player.gui.center[MASTER_FRAME.name]["scroll_content"], CONTENT.comm)
        elseif window_name == FRAME_TABS.resources.win.name then
            -- About
            draw_static_content(player.gui.center[MASTER_FRAME.name]["scroll_content"], CONTENT.resources)
        elseif window_name == FRAME_TABS.about.win.name then
            -- Players
            draw_static_content(player.gui.center[MASTER_FRAME.name]["scroll_content"], CONTENT.about)
        elseif window_name == FRAME_TABS.players.win.name then
            -- Close
            draw_players(player.gui.center[MASTER_FRAME.name]["scroll_content"])
        elseif window_name == FRAME_TABS.close.win.name then
            GUI.toggle_element(player.gui.center[MASTER_FRAME.name])
        end
    else
        -- create the master frame and call function again to draw specific tab
        local frame = player.gui.center.add {type = "frame", direction = "vertical", name = MASTER_FRAME.name}
        -- make a nav container and add nav buttons
        frame.add {type = "flow", name = "readme_nav", direction = "horizontal"}
        draw_frame_nav(frame.readme_nav)
        -- make a tab content container
        frame.add {type = "scroll-pane", name = "scroll_content", direction = "vertical", vertical_scroll_policy = "always", horizontal_scroll_policy = "auto"}
        -- Style config for nav
        frame.readme_nav.style.maximal_width = 600
        frame.readme_nav.style.minimal_width = 600
        -- Style config for content
        frame.scroll_content.style.maximal_height = 500
        frame.scroll_content.style.minimal_height = 500
        frame.scroll_content.style.maximal_width = 600
        frame.scroll_content.style.minimal_width = 600
        -- Recursive call
        draw_master_readme_frame(player, window_name)
    end
end

-- Draws the nav buttons for readme frame
-- @param nav_container GUI element to add the buttons to
function draw_frame_nav(nav_container)
    for i, frame_tab in pairs(FRAME_TABS) do
        nav_container.add {type = "button", name = frame_tab.btn.name, caption = frame_tab.btn.caption, tooltip = frame_tab.btn.tooltip}
    end
end

-- Draws a list of labels from content passed in
-- @param container - gui element to add to
-- @param content - array list of string to display
function draw_static_content(container, content)
    GUI.clear_element(container) -- Clear the current info before adding new
    for i, text in pairs(content) do
        container.add {type = "label", name = i, caption = text}
    end
end

-- Draws a list of players on the server with their playtime
-- @param container - gui element to add to
function draw_players(container)
    GUI.clear_element(container) -- Clear the current info before adding new
    
    local table_name = "tbl_readme_players"
    container.add {type = "label", name = "lbl_player_tile", caption = "=== ALL TIME PLAYERS ==="}
    container.add {type = "table", name = table_name, colspan = 2}
    container[table_name].style.minimal_width = 500
    container[table_name].style.maximal_width = 500
    container[table_name].add {type = "label", name = "lbl_hours", caption = "Time (h:m)"}
    container[table_name].add {type = "label", name = "lbl_name", caption = "Name"}
    
    -- Copy player list into local list
    local player_list = {}
    for i, player in pairs(game.players) do
        table.insert(player_list, {name = player.name, online_time = player.online_time})
    end
    
    -- Sort players based on time played
    table.sort(
        player_list,
        function(a, b)
            return a.online_time > b.online_time
        end
    )
    
    -- Add in gui list
    for i, player in pairs(player_list) do
        local total_min = Time.tick_to_min(player.online_time)
        local time_str = math.floor(total_min / 60) .. ":" .. math.floor(total_min % 60)
        container[table_name].add {type = "label", name = "lbl_" .. player.name .. "_time", caption = time_str}
        container[table_name].add {type = "label", name = "lbl_" .. player.name .. "_name", caption = player.name}
    end
end

-- Event Handlers
Event.register(defines.events.on_gui_click, on_gui_click)
Event.register(defines.events.on_player_joined_game, on_player_join)
Event.register(defines.events.on_player_left_game, on_player_leave)
