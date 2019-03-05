local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Token = require 'utils.token'
local Command = require 'utils.command'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Settings = require 'utils.redmew_settings'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

local pairs = pairs
local next = next

local toast_volume_name = 'toast-volume'
Settings.register(toast_volume_name, 'fraction', 1.0)

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

--- Apply this name to an element to have it close the toast when clicked.
-- Two elements in the same parent cannot have the same name. If you need your
-- own name you can use Toast.close_toast(element)
Public.close_toast_name = close_toast_name

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
---@param sound string sound to play, nil to not play anything
local function toast_to(player, duration, sound)
    local frame_holder = player.gui.left.add({type = 'flow'})

    local frame =
        frame_holder.add({type = 'frame', name = toast_frame_name, direction = 'vertical', style = 'captionless_frame'})
    frame.style.width = 300

    local container = frame.add({type = 'flow', name = toast_container_name, direction = 'horizontal'})
    container.style.horizontally_stretchable = true

    local progressbar = frame.add({type = 'progressbar', name = toast_progress_name})
    local style = progressbar.style
    style.width = 290
    style.height = 4
    style.color = Color.orange
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

    if sound then
        player.play_sound({path = sound, volume_modifier = Settings.get(player.index, toast_volume_name)})
    end

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
---@param player LuaPlayer
---@param duration table
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.toast_player_template(player, duration, template, sound)
    sound = sound or 'utility/new_objective'
    local container = toast_to(player, duration, sound)
    if container then
        template(container, player)
    end
end

---Toast all players of the given force, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param force LuaForce
---@param duration number
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.toast_force_template(force, duration, template, sound)
    sound = sound or 'utility/new_objective'
    local players = force.connected_players
    for i = 1, #players do
        local player = players[i]
        template(toast_to(player, duration, sound), player)
    end
end

---Toast all players, template is a callable that receives a LuaGuiElement
---to add contents to and a player as second argument.
---@param duration number
---@param template function
---@param sound string sound to play, nil to not play anything
function Public.toast_all_players_template(duration, template, sound)
    sound = sound or 'utility/new_objective'
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        template(toast_to(player, duration, sound), player)
    end
end

---Toast a message to a specific player
---@param player LuaPlayer
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

Command.add(
    'toast',
    {
        description = {'command_description.toast'},
        arguments = {'msg'},
        capture_excess_arguments = true,
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    function(args)
        Public.toast_all_players(15, args.msg)
        Utils.print_admins({'command_description.sent_all_toast', Utils.get_actor()})
    end
)

Command.add(
    'toast-player',
    {
        description = {'command_description.toast_player'},
        arguments = {'player', 'msg'},
        capture_excess_arguments = true,
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    function(args)
        local target_name = args.player
        local target = game.players[target_name]
        if target then
            Public.toast_player(target, 15, args.msg)
            Utils.print_admins({'command_description.sent_player_toast', Utils.get_actor(), target_name})
        else
            Game.player_print({'common.fail_no_target', target_name}, Color.yellow)
        end
    end
)

return Public
