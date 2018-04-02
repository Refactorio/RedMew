global.player_spy_data =
    {
        watchers = {}, -- map of target to watcher[]
        targets = {}, -- map of watcher to target
        player_list = {}-- map of list selection index to {player index, player name}
    }

local main_button_name = "player_spy_main_button"
local main_frame_name = "player_spy_main_frame"
local panel_name = "player_spy_panel"
local list_name = "player_spy_list"
local tp_button_name = "player_spy_tp_button"
local camera_name = "player_spy_camera"
local camera_zoom_in_name = "player_spy_camera_zoom_in"
local camera_zoom_out_name = "player_spy_camera_zoom_out"
local minimap_name = "player_spy_minimap"
local minimap_zoom_in_name = "player_spy_minimap_zoom_in"
local minimap_zoom_out_name = "player_spy_minimap_zoom_out"

local function create_player_list_items()
    local list = {}
    for i, p in pairs(game.players) do
        table.insert(list, {index = i, name = p.name})
    end
    
    return list
end

local function add_watcher(target, watcher)
    local data = global.player_spy_data
    local target_watchers = data.watchers[target]
    
    if not target_watchers then
        target_watchers = {watcher}
        data.watchers[target] = target_watchers
    else
        table.insert(target_watchers, watcher)
    end
    
    data.targets[watcher] = target
end

local function remove_watcher(watcher)
    local data = global.player_spy_data
    local target = data.targets[watcher]
    if target == nil then
        return
    end
    
    data.targets[watcher] = nil
    local watchers = data.watchers[target]
    if not watchers then
        return
    end
    
    table.remove_element(watchers, watcher)
end

local function create_main_button(player, event)
    if player.gui.top[main_button_name] == nil then
        local button = player.gui.top.add{name = main_button_name, type = "sprite-button", sprite = "utility/show_player_names_in_map_view"}
        button.style.font = "default-bold"
        button.style.minimal_height = 38
        button.style.minimal_width = 38
        button.style.top_padding = 2
        button.style.left_padding = 4
        button.style.right_padding = 4
        button.style.bottom_padding = 2
    end
end

local function create_main_frame(player, event)
    local data = global.player_spy_data
    local left = player.gui.left
    
    local main_frame = left.add{type = "frame", name = main_frame_name, direction = "vertical", caption = "Player Spy"}
    
    local panel = main_frame.add{type = "table", name = panel_name, column_count = 2}
    
    local list = panel.add{type = "drop-down", name = list_name}
    
    local player_list = create_player_list_items()
    data.player_list = player_list
    local names = table.map_value(player_list, function(v) return v.name end)
    
    local position = {0, 0}
    list.items = names
    if #names > 0 then
        list.selected_index = 1
        local target = player_list[1].index
        add_watcher(target, player.index)
        local target_player = game.players[target]
        if target_player then
            position = target_player.position
        end
    end
    
    local tp_button = panel.add{type = "button", name = tp_button_name, caption = "tp to player"}
    
    local camera = panel.add{type = "camera", name = camera_name, position = position, zoom = 0.25}
    camera.style.width = 256
    camera.style.height = 256
    
    local flow = panel.add{type = "flow", direction = "vertical"}
    local camera_zoom_in = flow.add{type = "button", name = camera_zoom_in_name, caption = "zoom in"}
    local camera_zoom_out = flow.add{type = "button", name = camera_zoom_out_name, caption = "zoom out"}
    
    local minimap = panel.add{type = "minimap", name = minimap_name, position = position, zoom = 1}
    minimap.style.width = 256
    minimap.style.height = 256
    
    local flow = panel.add{type = "flow", direction = "vertical"}
    local minimap_zoom_in = flow.add{type = "button", name = minimap_zoom_in_name, caption = "zoom in"}
    local minimap_zoom_out = flow.add{type = "button", name = minimap_zoom_out_name, caption = "zoom out"}
end

local function remove_main_frame(player, event)
    local main_frame = player.gui.left[main_frame_name]
    if main_frame then
        main_frame.destroy()
        remove_watcher(event.player.index)
    end
end

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end
    
    create_main_button(player, event)
end

local function get_camera(player)
    return player.gui.left[main_frame_name][panel_name][camera_name]
end

local function get_minimap(player)
    return player.gui.left[main_frame_name][panel_name][minimap_name]
end

local function get_tp_button(player)
    return player.gui.left[main_frame_name][panel_name][tp_button_name]
end

local function get_list(player)
    return player.gui.left[main_frame][panel_name][list_name]
end

local function tp_to_target(player, event)
    local data = global.player_spy_data
    local target_index = data.targets[player.index]
    
    if target_index == player_index then
        return
    end
    
    local target = game.players[target_index]
    
    if not target then
        return
    end
    
    player.teleport(target.position)
end

local function gui_click(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end
    
    local name = event.element.name
    
    if name == main_button_name then
        local main_frame = player.gui.left[main_frame_name]
        if main_frame then
            remove_main_frame(player, event)
        else
            create_main_frame(player, event)
        end
    elseif name == camera_zoom_in_name then
        local camera = get_camera(player)
        camera.zoom = math.min(camera.zoom + 0.05, 0.75)
    elseif name == camera_zoom_out_name then
        local camera = get_camera(player)
        camera.zoom = math.max(camera.zoom - 0.05, 0.10)
    elseif name == minimap_zoom_in_name then
        local minimap = get_minimap(player)
        minimap.zoom = math.min(minimap.zoom + 0.01, 0.1)
    elseif name == minimap_zoom_out_name then
        local minimap = get_minimap(player)
        minimap.zoom = math.max(minimap.zoom - 0.01, 0.01)
    elseif name == tp_button_name then
        tp_to_target(player, event)
    end
end

local function gui_selection_state_changed(event)
    local data = global.player_spy_data
    local name = event.name
    if name ~= list_name then
        return
    end
    
    local index = event.player_index
    local player = game.players[index]
    
    if not player then
        return
    end
    
    remove_watcher(index)
    
    local list = get_list(player)
    local target = data.player_list[list.selected_index].index
    add_watcher(target, index)
    
    local target_player = game.players[target]
    if not target_player then
        return
    end
    
    local pos = target_player.position
    get_camera(player).position = pos
    get_minimap(player).position = pos
end

local function player_moved(event)
    local data = global.player_spy_data
    local target = game.players[event.player_index]
    if not target then
        return
    end
    
    local watchers = data.watchers[target.index]
    if not watchers then
        return
    end
    
    for _, watcher in ipairs(watchers) do        
        local player = game.players[watcher]
        if player then
            local camera = get_camera(player)
            local minimap = get_minimap(player)
            
            if camera and minimap then
                local pos = {target.position.x, target.position.y}
                camera.position = pos
                minimap.position = pos
            end
        end
    end
end

Event.register(defines.events.on_player_joined_game, player_joined)
Event.register(defines.events.on_gui_click, gui_click)
Event.register(defines.events.on_gui_selection_state_changed, gui_selection_state_changed)
Event.register(defines.events.on_player_changed_position, player_moved)
