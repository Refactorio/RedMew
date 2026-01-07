local AdminPanel = require 'features.gui.admin_panel.core'
local Color = require 'resources.color_presets'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Ranks = require 'resources.ranks'

local string_match = string.match
local string_lower = string.lower

local ModerationPages = {
    ranks      = { name = Gui.uid_name(), caption = 'Ranks',      tooltip = 'The rank system and its permissions', size = { 400, 400 } },
    moderation = { name = Gui.uid_name(), caption = 'Moderation', tooltip = 'Moderation 101 for Admins & Mods',    size = { 400, 400 } },
    commands   = { name = Gui.uid_name(), caption = 'Commands',   tooltip = 'Raw list of chat commands',           size = { 400, 400 } },
    server     = { name = Gui.uid_name(), caption = 'Server',     tooltip = 'Impacting the world/server state',    size = { 400, 400 } },
    resources  = { name = Gui.uid_name(), caption = 'Resources',  tooltip = 'How to act fairly and safely',        size = { 400, 400 } },
}

-- == UTILS ===================================================================

local PALETTE = {
    title = { 238, 232, 170 }
}

local function font(parent, caption, color)
    local label = parent.add { type = 'label', caption = caption }
    if color then
        label.style.font_color = color
    end
    return label
end

local function bold(parent, caption, color)
    local label = parent.add { type = 'label', style = 'bold_label', caption = caption }
    if color then
        label.style.font_color = color
    end
    return label
end

local function empty(parent)
    return parent.add { type = 'empty-widget' }
end

local function text(tbl)
    return table.concat(tbl, '\n')
end

local function textbox(parent, caption)
    local tbox = parent.add {
        type = 'text-box',
        style = 'console_input_textfield',
        vertical_scroll_policy = 'never',
        horizontal_scroll_policy = 'never',
        text = caption,
    }
    Gui.set_style(tbox, { width = 456, natural_width = 456, height = 32, font = 'default-small' })
    return tbox
end

local function line(parent)
    local element = parent.add { type = 'line', style = 'tooltip_category_line' }
    Gui.set_style(element, { left_margin = -11, right_margin = -11, horizontally_stretchable = true })
    return element
end

local function inline(parent)
    local flow = parent.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { vertical_align = 'center' })
    return flow
end

-- == RANKS ===================================================================

ModerationPages.ranks.draw = function(parent)
    font(parent, text{
        'Ranks are a simple system to help preventing griefing and manage servers.',
        'Lower ranks cannot outrule/demote higher ranks, but it is always possible',
        'for an higher rank to promote/demote below.',
        'Tooltips in the table headers will show which perks each rank comes with.',
    }).style.single_line = false

    local grid = parent.add { type = 'table', style = 'finished_game_table', column_count = 8 }
    for i = 2, 8 do
        grid.style.column_alignments[i] = 'center'
    end
    -- Title
    bold(grid, 'Rank',  PALETTE.title)
    bold(grid, 'Value', PALETTE.title).tooltip = 'Internal value assigned to this role'
    bold(grid, 'Chat',  PALETTE.title).tooltip = 'Can: \n- chat in console'
    bold(grid, 'Move',  PALETTE.title).tooltip = 'Can: \n- move character around \n- interact with the world \n- do inventory transfers \n- rotate, access, open entities'
    bold(grid, 'GUIs',  PALETTE.title).tooltip = 'Can: \n- use GUIs'
    bold(grid, 'BPs',   PALETTE.title).tooltip = 'Can: \n- use BPs ([img=item.deconstruction-planner], [img=item.blueprint]) \n- use game commands \n- create tasks \n- use nukes'
    bold(grid, 'Mod',   PALETTE.title).tooltip = 'Can: \n- moderate the map \n- promote/demote \n- jail/unjail \n- mute/unmute \n- kick/invoke/spank \n- change surface settings \n- use announcements \n- manage toasts, tags \n- access Admin panel (limited)'
    bold(grid, 'Admin', PALETTE.title).tooltip = 'Can: \n- use editor \n- use lua console/commands \n- manage permissions \n- manage mod reports \n- ban players across RedMew servers \n- manage server settings \n- access servers web interface \n- start/stop/pause/rollback servers \n- access Admin panel (fully)'

    do -- admin
        bold(grid, 'Admin', Color.admin)
        font(grid, Ranks.admin)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
    end

    do -- moderator
        bold(grid, 'Moderator', Color.moderator)
        font(grid, Ranks.moderator)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        empty(grid)
    end

    do -- regular
        bold(grid, 'Regular', Color.regular)
        font(grid, Ranks.regular)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        empty(grid)
        empty(grid)
    end

    do -- auto trusted
        bold(grid, 'Auto Trusted', Color.auto_trusted)
        font(grid, Ranks.auto_trusted)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        empty(grid)
        empty(grid)
    end

    do -- guest
        bold(grid, 'Guest', Color.guest)
        font(grid, Ranks.guest)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        empty(grid)
        empty(grid)
        empty(grid)
    end

    do -- probation
        bold(grid, 'Probation', Color.guest)
        font(grid, Ranks.probation)
        bold(grid, 'X')
        bold(grid, 'X')
        bold(grid, 'X')
        empty(grid)
        empty(grid)
        empty(grid)
    end

    do -- jail
        bold(grid, 'Jail', Color.probation)
        empty(grid)
        bold(grid, 'X')
        empty(grid)
        empty(grid)
        empty(grid)
        empty(grid)
        empty(grid)
    end
end

-- == MODERATION ==============================================================

local known_paths = {
    admin = '[img=item/power-armor-mk2] Admin panel',
    guide = '[img=utility/custom_tag_icon] Moderation guide',
    player = '[img=entity/character] Player manager',
    map = '[img=utility/surface_editor_icon] Map manager',
    lua = '[img=utility/scripting_editor_icon] Lua console',
}

local function path(parent, paths)
    local caption = known_paths.admin
    for _, p in pairs(paths) do
        caption = caption .. ' / ' .. (known_paths[p] or p)
    end
    return parent.add { type = 'label', style = 'semibold_caption_label', caption = caption }
end

ModerationPages.moderation.draw = function(parent)
    path(parent, {'guide', 'General actions', 'Cheat mode'})
    path(parent, {'guide', 'General actions', 'Show reports'})
    path(parent, {'guide', 'General actions', 'Blueprints ON/OFF'})
end

-- == COMMANDS ================================================================

local search_field_name = Gui.uid_name()

local base_commands = {
    { command = 'admin', help = 'Opens the player management GUI.', rank = 'Admin' },
    { command = 'admins', help = 'Prints a list of game admins (parameter online/o prints only admins that are online.)' },
    { command = 'alerts <enable/disable/mute/unmute> <alert>', help = 'Enables, disables, mutes, or unmutes the given alert type.' },
    { command = 'ban <player> <reason>', help = 'Bans the specified player.', rank = 'Admin' },
    { command = 'banlist <add/remove/get/clear> <player>', help = 'Adds or removes a player from the banlist. Same as /ban or /unban.', rank = 'Admin' },
    { command = 'bans', help = 'Prints a list of banned players.' },
    { command = 'cheat <all>', help = 'Researches all technologies and enables cheat mode. Using the <all> option also gives the player some additional items.\n <planet-name> - moves the player to the specified planet.\n <platform-name> - moves the player to the specified platform.\n <off> - turns the cheat mode off.', rank = 'Admin' },
    { command = 'clear', help = 'Clears the console.' },
    { command = 'color <color>', help = 'Changes your color. Can either be one of the predefined colors or RGBA values in the format of "# # # #".' },
    { command = 'command <command>', help = '/c executes a Lua command.', rank = 'Admin' },
    { command = 'config', help = 'Opens the server configuration GUI.', rank = 'Admin' },
    { command = 'delete-blueprint-library <player>', help = 'Deletes the blueprint library storage for the given offline player from the save file. Enter "everybody confirm" to delete the storage of all offline players.', rank = 'Admin' },
    { command = 'demote <player> ', help = 'Demotes the player from admin.', rank = 'Admin' },
    { command = 'editor', help = 'Toggles the map editor.', rank = 'Admin' },
    { command = 'evolution <surface>', help = 'Prints info about the alien evolution factor.' },
    { command = 'help-description', help = 'Type /h <command> to get details of it.' },
    { command = 'help-list', help = 'Available commands are:' },
    { command = 'help <command>', help = 'Prints a list of available commands. The optional argument can specify the command that should be described.' },
    { command = 'ignore <player> ', help = 'Prevents the chat from showing messages from this player. Admin messages are still shown.' },
    { command = 'ignores', help = 'Prints a list of ignored players.' },
    { command = 'kick <player> <reason>', help = 'Kicks the specified player.', rank = 'Admin' },
    { command = 'large-blueprint-size <set/get> <number>', help = 'Sets or reads the threshold for what is a "large" blueprint (in bytes). Copying large blueprints will use the "large" version of the input action which can be optionally allowed/disabled through the permissions system.', rank = 'Admin' },
    { command = 'measured-command <command>', help = '/mc executes a Lua command and measures time it took.', rank = 'Admin' },
    { command = 'mute-programmable-speaker <mute/unmute> <local/everyone>', help = 'Mutes or unmutes global and surface sounds created by the Programmable Speaker. Use "local" to mute just the local client. Admins can use "everyone" to mute the sounds for everyone on the server.' },
    { command = 'mute <player>', help = 'Prevents the player from saying anything in chat.', rank = 'Admin' },
    { command = 'mutes', help = 'Prints a list of all players that are muted (cannot talk in chat).' },
    { command = 'open <player>', help = '/o opens another player\'s inventory.', rank = 'Admin' },
    { command = 'perf-avg-frames', help = 'Number of ticks/updates used to average performance counters. The default is 100. A value of 5-10 is recommended for fast convergence, but numbers will jitter more rapidly.' },
    { command = 'permissions', help = 'Opens the permissions GUI.', rank = 'Admin' },
    { command = 'players', help = 'Prints a list of players in the game. (parameter online/o prints only players that are online. count/c prints only count)' },
    { command = 'promote <player>', help = 'Promotes the player to admin.', rank = 'Admin' },
    { command = 'purge <player> ', help = 'Clears all the messages from this player from the chat log.', rank = 'Admin' },
    { command = 'reply <message> ', help = '/r replies to the last player that whispered to you.' },
    { command = 'reset-tips', help = 'Resets the state of the tips and tricks as if the game was just started for the first time.' },
    { command = 'screenshot <x resolution> <y resolution> <zoom>', help = 'Takes a screenshot with your current view settings, or with the specified resolution. Zoom is optional and defaults to 1.' },
    { command = 'seed', help = 'Prints the starting map seed.' },
    { command = 'server-commands', help = 'Server console commands.' },
    { command = 'server-save', help = 'Saves the game on the server in a multiplayer game.', rank = 'Admin' },
    { command = 'shout <message>', help = 'Sends a message to all players including other forces.' },
    { command = 'silent-command <command>', help = '/sc executes a Lua command without printing it to the console.', rank = 'Admin' },
    { command = 'space-platform-delete-time <number>', help = 'Sets the number of ticks between requesting a space platform be deleted and it actually being deleted.', rank = 'Admin' },
    { command = 'swap-players <player> <player>', help = 'Swaps characters between the specified players. If not given, the second player is yourself.', rank = 'Admin' },
    { command = 'time', help = 'Prints info about how old the map is.' },
    { command = 'toggle-action-logging', help = 'Toggles logging of all input actions performed by the game. This value doesn\'t persist following game restarts and only effects your local game in multiplayer sessions.', rank = 'Admin' },
    { command = 'toggle-heavy-mode', help = 'This command is to be used with caution as it will make the game multiplayer unplayable once set. The game starts to save and compare the game with itself every tick to search for inconsistencies in the determinism. This command is advised to be used when there is a desync loop when a new player joins the server. The heavy mode will run until it outputs something. Please provide it to us so we can investigate and fix the problem.', rank = 'Admin' },
    { command = 'unban <player>', help = 'Unbans the specified player.', rank = 'Admin' },
    { command = 'unignore <player>', help = 'Allows the chat to show messages from this player.' },
    { command = 'unlock-shortcut-bar', help = 'Unlocks all shortcut bar items.' },
    { command = 'unlock-tips', help = 'Unlocks all tips and trick entries.' },
    { command = 'unmute <player>', help = 'Allows the player to talk in chat again.', rank = 'Admin' },
    { command = 'version', help = 'Prints the current game version.' },
    { command = 'whisper <player> <message>', help = '/w sends a message to the specified player only.' },
    { command = 'whitelist <enable/disable/add/remove/get/clear> <player>', help = 'Enables, disables, adds or removes a player from the whitelist, where only whitelisted players can join the game. Enter nothing for \'player\' when using \'get\' to print a list of all whitelisted players.' },
}

local redmew_commands = {
    { command = 'a <message>', help = {'command_description.a'}, rank = 'Admin' },
    { command = 'abort', help = {'command_description.abort'}, rank = 'Admin' },
    { command = 'af-debug', help = {'command_description.af_debug'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'af-max', help = {'command_description.af_max'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'af-reset', help = {'command_description.af_reset'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'afk', help = {'command_description.afk'} },
    { command = 'apocalypse', help = {'command_description.apocalypse'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'barrage <location>', help = {'command_description.crash_site_barrage'}, rank = 'Guest', info = {'command_custom_help.module_only'} },
    { command = 'calculator-technology <technology>', help = {'command_description.calculator_tech'}, rank = 'Guest', info = {'command_custom_help.module_only'} },
    { command = 'calculator-technology-for-player <technology> <player>', help = {'command_description.calculator_tech_player'}, rank = 'Moderator', info = {'command_custom_help.module_only'} },
    { command = 'config-restart', help = {'command_description.config_restart'}, rank = 'Admin' },
    { command = 'corpses <surface>', help = {'command_description.clear_corpses'}, rank = 'Regular' },
    { command = 'dataset-copy <dataset> <destination>', help = {'command_description.dataset_copy'}, rank = 'Admin' },
    { command = 'dataset-delete <dataset>', help = {'command_description.dataset_delete'}, rank = 'Admin' },
    { command = 'dataset-move <dataset> <destination>', help = {'command_description.dataset_move'}, rank = 'Admin' },
    { command = 'debug-reveal <radius>', help = {'command_description.reveal'}, rank = 'Admin' },
    { command = 'destroy', help = {'command_description.destroy'}, rank = 'Admin' },
    { command = 'donator-death-message <add|delete|list> <value>', help = {'command_description.donator_death_message'}, info = 'Donators only' },
    { command = 'donator-welcome-message <add|delete|list> <value>', help = {'command_description.donator_welcome_message'}, info = 'Donators only' },
    { command = 'find <player>', help = {'command_description.find'} },
    { command = 'generate-desc', help = {'command_description.generate_desc'}, rank = 'Admin' },
    { command = 'get-pollution-multiplier', help = {'command_description.get_pollution_multiplier'}, rank = 'Guest', info = {'command_custom_help.module_only'} },
    { command = 'hax', help = {'command_description.hax'}, rank = 'Admin' },
    { command = 'invoke <player>', help = {'command_description.invoke'}, rank = 'Moderator' },
    { command = 'jail <player>', help = {'command_description.jail'}, rank = 'Moderator' },
    { command = 'kill <player>', help = {'command_description.kill'}, rank = 'Admin' },
    { command = 'lazy-bastard-bootstrap', help = {'command_description.lazy_bastard_bootstrap'}, rank = 'Admin' },
    { command = 'market <removeall>', help = {'command_description.market'}, rank = 'Admin' },
    { command = 'meltdown-get', help = {'command_description.meltdown_get'}, info = {'command_custom_help.module_only'} },
    { command = 'meltdown-set <on/off>', help = {'command_description.meltdown_set'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'moderator <player>', help = {'command_description.moderator'}, rank = 'Admin' },
    { command = 'moderator-remove <player>', help = {'command_description.moderator_remove'}, rank = 'Admin' },
    { command = 'particle-scale <fraction>', help = {'command_description.particle_scale'}, rank = 'Admin' },
    { command = 'performance-scale-get', help = {'command_description.performance_scale_get'} },
    { command = 'performance-scale-set <scale>', help = {'command_description.performance_scale_set'}, rank = 'Moderator' },
    { command = 'perks', help = {'command_description.perks'} },
    { command = 'permissions-reset', help = {'command_description.permissions_reset'}, rank = 'Admin' },
    { command = 'permissions-set-scenario', help = {'command_description.permissions_set_scenario'}, rank = 'Admin' },
    { command = 'ping-silo', help = {'command_description.frontier_ping_silo'}, info = {'command_custom_help.module_only'} },
    { command = 'poll <poll>', help = {'command_description.poll'}, rank = 'Admin', info = {'command_custom_help.poll'} },
    { command = 'poll-result <poll>', help = {'command_description.poll_result'} },
    { command = 'pool', help = {'command_description.pool'}, rank = 'Moderator' },
    { command = 'popup <message>', help = {'command_description.popup'}, rank = 'Moderator' },
    { command = 'popup-player <player> <message>', help = {'command_description.popup_player'}, rank = 'Moderator' },
    { command = 'popup-update <version>', help = {'command_description.popup_update'}, rank = 'Admin' },
    { command = 'probation <player>', help = {'command_description.probation'}, rank = 'Moderator' },
    { command = 'probation-remove <player>', help = {'command_description.probation_remove'}, rank = 'Moderator' },
    { command = 'quick-bar-delete', help = {'command_description.quick_bar_delete'}, rank = 'Regular' },
    { command = 'quick-bar-load', help = {'command_description.quick_bar_load'}, rank = 'Regular' },
    { command = 'quick-bar-save', help = {'command_description.quick_bar_save'}, rank = 'Regular' },
    { command = 'radio', help = {'command_description.radio'}, info = {'command_custom_help.module_only'} },
    { command = 'redmew-version', help = {'command_description.redmew_version'} },
    { command = 'regular <player>', help = {'command_description.regular'}, rank = 'Moderator' },
    { command = 'regular-all', help = {'command_description.regular-all'}, rank = 'Admin' },
    { command = 'regular-remove <player>', help = {'command_description.regular_remove'}, rank = 'Moderator' },
    { command = 'replay', help = {'cutscene_controller.replay'}, info = {'command_custom_help.module_only'} },
    { command = 'report <player> <reason>', help = {'command_description.report'} },
    { command = 'restart <str>', help = {'command_description.restart'}, rank = 'Guest' },
    { command = 'revive-ghosts <radius>', help = {'command_description.revive_ghosts'}, rank = 'Moderator' },
    { command = 'reward <target> <quantity> <reason>', help = {'command_description.reward'}, rank = 'Admin' },
    { command = 'rich-text', help = {'command_description.rich_text'} },
    { command = 'rpg-leaderboard', help = {'command_description.rpg_leaderboard'}, info = {'command_custom_help.module_only'} },
    { command = 'rpg-stats <player>', help = {'command_description.rpg_stats'}, info = {'command_custom_help.module_only'} },
    { command = 'rpg-update', help = {'command_description.rpg_update'}, rank = 'Moderator', info = {'command_custom_help.module_only'} },
    { command = 'seeds', help = {'command_description.seeds'} },
    { command = 'server-time', help = {'command_description.server_time'} },
    { command = 'set-pollution-multiplier <multiplier>', help ={'command_description.set_pollution_multiplier'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'show-rail-block', help = {'command_description.show_rail_block'} },
    { command = 'show-reports', help = {'command_description.showreports'}, rank = 'Admin' },
    { command = 'skip', help = {'cutscene_controller.skip'}, info = {'command_custom_help.module_only'} },
    { command = 'spy <location>', help = {'command_description.crash_site_spy'}, rank = 'Guest', info = {'command_custom_help.module_only'} },
    { command = 'strike <location>', help = {'command_description.crash_site_airstrike'}, rank = 'Guest', info = {'command_custom_help.module_only'} },
    { command = 'tag <player> <tag>', help = {'command_description.tag'}, rank = 'Moderator' },
    { command = 'task <task:sentence>', help = {'command_description.task'}, rank = 'Regular' },
    { command = 'toast <message>', help = {'command_description.toast'}, rank = 'Moderator' },
    { command = 'toast-player <player< <message>', help = {'command_description.toast_player'}, rank = 'Moderator' },
    { command = 'toggle-debug-ai', help = {'command_description.frontier_toggle_debug_ai'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'toggle-debug-shop', help = {'command_description.frontier_toggle_debug_shop'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'toggle-log-global', help = {'command_description.frontier_log_global'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'toggle-print-global', help = {'command_description.frontier_print_global'}, rank = 'Admin', info = {'command_custom_help.module_only'} },
    { command = 'tp <mode/player>', help = {'command_description.tp'}, rank = 'Admin', info = {'command_custom_help.tp'} },
    { command = 'unjail <player>', help = {'command_description.unjail'}, rank = 'Moderator' },
    { command = 'watch <target>', help = {'command_description.watch'} },
    { command = 'whois <player> <inventory>', help = {'command_description.whois'} },
    { command = 'zoom <zoom>', help = {'command_description.zoom'}, rank = 'Admin' },
}

local commands_list = {}
do
    for _, list in pairs{ base_commands, redmew_commands } do
        for _, e in pairs(list) do
            table.insert(commands_list, e)
        end
    end
    table.sort(commands_list, function(a, b) return a.command < b.command end)
end

ModerationPages.commands.draw = function(parent)
    local flow = inline(parent)
    bold(flow, 'Search: ')
    local search_field = flow.add { type = 'text-box', name = search_field_name, text = '', style = 'search_popup_textfield' }
    Gui.set_style(search_field, { width = 456 - 48 - 4 - 34 - 4 + 2 + 12 })

    local result_count = flow.add { type = 'sprite-button', style = 'button', caption = #commands_list, tooltip = 'Results count' }
    Gui.set_style(result_count, { height = 26, width = 34, padding = 0 })

    local command_table = parent.add { type = 'table', style = 'finished_game_table', column_count = 1 }
    Gui.set_data(search_field, { command_table = command_table, result_count = result_count })

    for i, cmd in pairs(commands_list) do
        local grid = command_table.add { type = 'table', style = 'player_input_table', column_count = 2 }

        grid.style.column_alignments[1] = 'top-center'
        grid.style.column_alignments[2] = 'top-left'
        Gui.set_style(grid, { vertical_spacing = 4 })

        local icon = font(grid, '[img=developer]')
        Gui.set_style(icon, { minimal_width = 20, left_padding = 6 })

        local command = bold(grid, '/' .. cmd.command, Color.light_cyan)
        Gui.set_style(command, { maximal_width = 420, single_line = false })

        if cmd.rank then
            font(grid, '[img=quality_info]')
            font(grid, cmd.rank, Color.khaki)
        end
        if cmd.help then
            font(grid, '[img=info]')
            local help = font(grid, cmd.help)
            Gui.set_style(help, { maximal_width = 420, single_line = false })
        end
        if cmd.info then
            font(grid, '[img=warning-white]')
            local info = font(grid, cmd.info)
            Gui.set_style(info, { maximal_width = 420, single_line = false })
        end
    end
end

local function match_pattern(grid, pattern)
    local labels = grid.children
    for i = 2, 8, 2 do
        if labels[i] and (labels[i].caption ~= nil and type(labels[i].caption) == 'string') and string_match(string_lower(labels[i].caption), pattern) then
            return true
        end
    end
    return false
end

local function filter_commands(command_table, pattern)
    local count = 0
    for _, child in pairs(command_table.children) do
        local visible = match_pattern(child, pattern)
        child.visible = visible
        count = count + (visible and 1 or 0)
    end
    return count
end

Gui.on_text_changed(search_field_name, function(event)
    local element = event.element
    local data = Gui.get_data(element)
    local pattern = string_lower(element.text):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') -- escape magic chars
    data.result_count.caption = filter_commands(data.command_table, pattern)
end)

-- == SERVER ==================================================================

ModerationPages.server.draw = function(parent)
    parent.add { type = 'label', caption = 'TODO:'}
end

-- == RESOURCES ===============================================================

ModerationPages.resources.draw = function(parent)
    font(parent, 'Admins and Moderators onboarding URL: ')
    textbox(parent, 'github.com/Refactorio/RedMew/wiki/Moderator-and-Admin-Guide')

    line(parent)

    bold(parent, 'RedMew\'s mission statement', PALETTE.title)
    font(parent, text{
        '  RedMew aims to provide entertaining maps for players on our servers.',
        'We want to foster an inclusive atmosphere where nobody feels',
        'harassed or persecuted. Within those boundaries, players should feel',
        'able to be as silly as they want to be.',
        'While we don\'t have a policy of being family-friendly,',
        'we discourage people going over the top in their vulgarity.',
        '',
        '  In line with an inclusive atmosphere: hate speech is absolutely',
        'forbidden and grounds for an immediate ban.',
        'Personal attacks, personal insults, and the like are cause for',
        'warnings and escalated actions if the behaviour continues',
        '(escalated actions being /kick, etc. before a full ban).',
        '',
        '  The other case for immediate ban is clear and intentional griefing.',
        'Defining griefing can be difficult, a general rule of thumb would be:',
        'intentionally trying to reduce the productivity of the base,',
        'especially by means of stopping belt, fluid, or electricity flow.',
    }).style.single_line = false
end

-- ============================================================================

Event.add(AdminPanel.events.on_admin_gui_closed, function(event)
    local screen = event.player.gui.screen
    for _, page in pairs(ModerationPages) do
        local window = screen[page.name]
        if window then
            Gui.destroy(window)
        end
    end
end)

return ModerationPages
