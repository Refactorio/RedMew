local Event = require 'utils.event'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'

local type = type
local tonumber = tonumber
local pairs = pairs
local size = table.size

local Public = {}

local active_toasts = {}
local id_counter = {0}

local on_tick

Global.register(
    {active_toasts = active_toasts, id_counter = id_counter},
    function(tbl)
        active_toasts = tbl.active_toasts
        id_counter = tbl.id_counter
    end,
    'toast'
)

local toast_frame_name = Gui.uid_name()
local toast_container_name = Gui.uid_name()
local toast_progress_name = Gui.uid_name()
local close_toast_name = Gui.uid_name()

---Creates a unique ID for a toast message
local function autoincrement()
    local id = id_counter[1] + 1
    id_counter[1] = id
    return id
end

---Attempts to get a toast based on the element, will traverse through parents to find it.
---@param element LuaGuiElement
local function get_toast(element)
    if not element or not element.valid then
        return nil
    end

    if element.name == toast_frame_name then
        return element.parent
    end

    return get_toast(element.parent)
end

--- Closes the toast for the element.
--@param element LuaGuiElement
function Public.close_toast(element)
    local toast = get_toast(element)
    if not toast then
        return
    end

    local data = Gui.get_data(toast)
    active_toasts[data.toast_id] = nil
    Gui.destroy(toast)
end

---Toast to a specific player
---@param player LuaPlayer
---@param duration number in seconds
local function toast_to(player, duration)
    local frame_holder = player.gui.left.add({type = 'flow'})
    local frame_holder_style = frame_holder.style
    frame_holder_style.left_padding = 0
    frame_holder_style.top_padding = 0
    frame_holder_style.right_padding = 0
    frame_holder_style.bottom_padding = 0

    local frame =
        frame_holder.add({type = 'frame', name = toast_frame_name, direction = 'vertical', style = 'captionless_frame'})
    frame.style.width = 300

    local container = frame.add({type = 'flow', name = toast_container_name, direction = 'horizontal'})
    container.style.horizontally_stretchable = true

    local progressbar = frame.add({type = 'progressbar', name = toast_progress_name})
    local style = progressbar.style
    style.width = 290
    style.height = 3
    style.color = Color.grey
    progressbar.value = 1 -- it starts full

    local id = autoincrement()
    local tick = game.tick
    if not duration then
        duration = 15
    end

    Gui.set_data(
        frame_holder,
        {
            toast_id = id,
            progressbar = progressbar,
            start_tick = tick,
            end_tick = tick + duration * 60
        }
    )

    if not next(active_toasts) then
        Event.add_removable_nth_tick(2, on_tick)
    end

    active_toasts[id] = frame_holder

    return container
end

local close_toast = Public.close_toast
local function on_click_close_toast(event)
    close_toast(event.element)
end

Gui.on_click(toast_frame_name, on_click_close_toast)
Gui.on_click(toast_container_name, on_click_close_toast)
Gui.on_click(toast_progress_name, on_click_close_toast)
Gui.on_click(close_toast_name, on_click_close_toast)

local function update_toast(id, frame, tick)
    if not frame.valid then
        active_toasts[id] = nil
        return
    end

    local data = Gui.get_data(frame)
    local end_tick = data.end_tick

    if tick > end_tick then
        Gui.destroy(frame)
        active_toasts[data.toast_id] = nil
    else
        local limit = end_tick - data.start_tick
        local current = end_tick - tick
        data.progressbar.value = current / limit
    end
end

on_tick =
    Token.register(
    function(event)
        if not next(active_toasts) then
            Event.remove_removable_nth_tick(2, on_tick)
            return
        end

        local tick = event.tick

        for id, frame in pairs(active_toasts) do
            update_toast(id, frame, tick)
        end
    end
)

---Toast a specific player, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param player LuaPlayer|number
---@param duration table
---@param template function
function Public.toast_player_template(player, duration, template)
    local container = toast_to(player, duration)
    if container then
        template(container, player)
    end
end

---Toast all players of the given force, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param force LuaForce
---@param duration number
---@param template function
function Public.toast_force_template(force, duration, template)
    local players = force.connected_players
    for i = 1, #players do
        local player = players[i]
        template(toast_to(player, duration), player)
    end
end

---Toast all players, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param duration number
---@param template function
function Public.toast_all_players_template(duration, template)
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        template(toast_to(player, duration), player)
    end
end

---Toast a message to a specific player
---@param player LuaPlayer|number
---@param duration number
---@param message string
function Public.toast_player(player, duration, message)
    Public.toast_player_template(
        player,
        duration,
        function(container)
            local label = container.add({type = 'label', name = close_toast_name, caption = message})
            label.style.single_line = false
        end
    )
end

---Toast a message to all players of a given force
---@param force LuaForce
---@param duration number
---@param message string
function Public.toast_force(force, duration, message)
    local players = force.connected_players
    for i = 1, #players do
        local player = players[i]
        Public.toast_player(player, duration, message)
    end
end

---Toast a message to all players
---@param duration number
---@param message string
function Public.toast_all_players(duration, message)
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Public.toast_player(player, duration, message)
    end
end

return Public
