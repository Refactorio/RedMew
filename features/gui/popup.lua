local Gui = require 'utils.gui'
local Utils = require 'utils.core'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Ranks = require 'resources.ranks'

local close_name = Gui.uid_name()

local icons = {
    "utility/ammo_icon",                            -- 1
    "utility/danger_icon",                          -- 2
    "utility/destroyed_icon",                       -- 3
    "utility/warning_icon",                         -- 4
    "utility/electricity_icon",                     -- 5
    "utility/electricity_icon_unplugged",           -- 6
    "utility/fluid_icon",                           -- 7
    "utility/fuel_icon",                            -- 8
    "utility/no_building_material_icon",            -- 9
    "utility/no_storage_space_icon",                -- 10
    "utility/not_enough_construction_robots_icon",  -- 11
    "utility/not_enough_repair_packs_icon",         -- 12
    "utility/recharge_icon",                        -- 13
    "utility/too_far_from_roboport_icon"            -- 14
}

local function show_popup(player, message, title_text, sprite_path, popup_name)
    --Default title and icon
    title_text = (title_text ~= nil) and title_text or {'popup.default_title'}
    if type(sprite_path) == 'number' then
        sprite_path = (sprite_path ~= nil) and icons[sprite_path] or icons[4]
    else
        sprite_path = (sprite_path ~= nil) and sprite_path or icons[4]
    end

    local name
    if popup_name ~= nil then
        name = 'Popup.' .. popup_name
        local popup = player.gui.screen[name]
        if (popup) then
            Gui.destroy(popup)
        end
    end

    local frame, content, title_close_button = Gui.add_dialog(player, {name = name, caption = title_text, close_button_name = close_name})
    Gui.set_data(title_close_button, frame)
    Gui.set_style(frame, {minimal_width = 300})

    local content_flow = content.add {type = 'flow', direction = 'horizontal'}
    Gui.set_style(content_flow, {vertical_align = 'center', horizontal_spacing = 16})

    content_flow.add {type = 'sprite', sprite = sprite_path}

    local label = content_flow.add {type = 'label', caption = message}
    Gui.set_style(label, {single_line = false, font = 'default-large-bold'})

    local buttons = Gui.add_dialog_buttons(frame, nil, {
        {name = close_name, caption = {'popup.confirm_btn'}},
    })
    Gui.set_data(buttons[close_name], frame)
end

Gui.on_click(
        close_name,
        function(event)
            local frame = Gui.get_data(event.element)

            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
)

-- Creates a popup dialog for all players
local function popup(args)
    local message = args.message:gsub('\\n', '\n')

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message)
    end

    Game.player_print('Popup sent')
    Utils.print_admins(Utils.get_actor() .. ' sent a popup to all players', nil)
end

-- Creates a popup dialog for all players, specifically for the server upgrading factorio versions
local function popup_update(args)
    local message = 'Server is updating to ' .. args.version .. '\nWe will be back in a minute'

    for _, p in ipairs(game.connected_players) do
        show_popup(p, message, "Incoming update!", 11)
    end

    Game.player_print('Popup sent')
    Utils.print_admins(Utils.get_actor() .. ' sent a popup to all players', nil)
end

-- Creates a popup dialog for the specifically targetted player
local function popup_player(args)
    local target_name = args.player
    local target = game.get_player(target_name)
    if not target then
        Game.player_print('Player ' .. target_name .. ' not found.')
        return
    end

    local message = args.message:gsub('\\n', '\n')

    show_popup(target, message)
    Game.player_print('Popup sent')
end

Command.add(
    'popup',
    {
        description = {'command_description.popup'},
        arguments = {'message'},
        required_rank = Ranks.admin,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    popup
)

Command.add(
    'popup-update',
    {
        description = {'command_description.popup_update'},
        arguments = {'version'},
        required_rank = Ranks.moderator,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    popup_update
)

Command.add(
    'popup-player',
    {
        description = {'command_description.popup_player'},
        arguments = {'player', 'message'},
        required_rank = Ranks.moderator,
        capture_excess_arguments = true,
        allowed_by_server = true
    },
    popup_player
)

local Public = {}

--[[--
    Shows a popup dialog.

    @param player LuaPlayer
    @param message string
    @param title string
    @param sprite_path string, see format in icons table
    @param popup_name string, assign to have a popup only exist once.
]]
function Public.player(player, message, title, sprite_path, popup_name)
    show_popup(player, message, title, sprite_path, popup_name)
end

--[[--
    Shows a popup dialog to all connected players.

    @param message string
    @param title string
    @param sprite_path string, see format in icons table
    @param popup_name string, assign to have a popup only exist once.
]]
function Public.all_online(message, title, sprite_path, popup_name)
    for _, p in ipairs(game.connected_players) do
        show_popup(p, message, title, sprite_path, popup_name)
    end
end

--[[--
    Shows a popup dialog to all players.

    @param message string
    @param title string
    @param sprite_path string, see format in icons table
    @param popup_name string, assign to have a popup only exist once.
]]
function Public.all(message, title, sprite_path, popup_name)
    for _, p in pairs(game.players) do
        show_popup(p, message, title, sprite_path, popup_name)
    end
end

return Public
