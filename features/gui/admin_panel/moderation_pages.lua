local Color = require 'resources.color_presets'
local Command = require 'utils.command'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'

local string_match = string.match
local string_lower = string.lower

local ModerationPages = {
    ranks      = { name = Gui.uid_name(), index = 'ranks',      caption = 'Ranks',      tooltip = 'The rank system and its permissions', size = { 600, 600 } },
    moderation = { name = Gui.uid_name(), index = 'moderation', caption = 'Moderation', tooltip = 'Moderation 101 for Admins & Mods',    size = { 700, 700 } },
    commands   = { name = Gui.uid_name(), index = 'commands',   caption = 'Commands',   tooltip = 'Raw list of chat commands',           size = { 600, 600 } },
    server     = { name = Gui.uid_name(), index = 'server',     caption = 'Server',     tooltip = 'Impacting the world/server state',    size = { 600, 600 } },
    resources  = { name = Gui.uid_name(), index = 'resources',  caption = 'Resources',  tooltip = 'How to act fairly and safely',        size = { 500, 600 } },
}

-- == UTILS ===================================================================

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

local function textbox(parent, caption, width)
    local tbox = parent.add {
        type = 'text-box',
        style = 'console_input_textfield',
        vertical_scroll_policy = 'never',
        horizontal_scroll_policy = 'never',
        text = caption,
    }
    tbox.read_only = true
    tbox.word_wrap = true
    width = width or 420
    Gui.set_style(tbox, {
        width = width,
        natural_width = width,
        minimal_height = 32,
        font = 'default-small',
        rich_text_setting = defines.rich_text_setting.disabled,
        vertically_stretchable = true,
        horizontally_stretchable = false,
    })
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
    local window = parent
        .add { type = 'frame', style = 'inside_shallow_frame_with_padding' }
        .add { type = 'flow', direction = 'vertical' }
    Gui.set_style(window, { vertical_spacing = 6 })

    font(window, text{
        'Ranks are a simple system to help preventing griefing and manage servers.',
        'Lower ranks cannot outrule/demote higher ranks, but it is always possible',
        'for an higher rank to promote/demote below.',
        'Tooltips in the table headers will show which perks each rank comes with.',
    }).style.single_line = false

    local grid = window.add { type = 'table', style = 'finished_game_table', column_count = 8 }
    for i = 2, 8 do
        grid.style.column_alignments[i] = 'center'
    end
    -- Title
    bold(grid, 'Rank',  Color.pale_golden_rod)
    bold(grid, 'Value', Color.pale_golden_rod).tooltip = 'Internal value assigned to this role'
    bold(grid, 'Chat',  Color.pale_golden_rod).tooltip = 'Can: \n- chat in console'
    bold(grid, 'Move',  Color.pale_golden_rod).tooltip = 'Can: \n- move character around \n- interact with the world \n- do inventory transfers \n- rotate, access, open entities'
    bold(grid, 'GUIs',  Color.pale_golden_rod).tooltip = 'Can: \n- use GUIs'
    bold(grid, 'BPs',   Color.pale_golden_rod).tooltip = 'Can: \n- use BPs ([img=item.deconstruction-planner], [img=item.blueprint]) \n- use game commands \n- create tasks \n- use nukes'
    bold(grid, 'Mod',   Color.pale_golden_rod).tooltip = 'Can: \n- moderate the map \n- promote/demote \n- jail/unjail \n- mute/unmute \n- kick/invoke/spank \n- change surface settings \n- use announcements \n- manage toasts, tags \n- access Admin panel (limited)'
    bold(grid, 'Admin', Color.pale_golden_rod).tooltip = 'Can: \n- use editor \n- use lua console/commands \n- manage permissions \n- manage mod reports \n- ban players across RedMew servers \n- manage server settings \n- access servers web interface \n- start/stop/pause/rollback servers \n- access Admin panel (fully)'

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

local guide_listbox_name = Gui.uid_name()

--TODO: implement subpages info in locale & add the entries here
local wiki = {
    {
        name = '[img=item/power-armor-mk2] Admin panel',
        pages = {
            {
                name = '[img=utility/custom_tag_icon] Moderation guide',
                pages = {
                    { name = 'Ranks', contents = {{ 'redmew_wiki.guide_ranks' }} },
                    { name = 'Moderation', contents = {{ 'redmew_wiki.guide_moderation' }} },
                    { name = 'Commands', contents = {{ 'redmew_wiki.guide_commands' }} },
                    { name = 'Server', contents = {{ 'redmew_wiki.guide_server' }} },
                    { name = 'Resources', contents = {{ 'redmew_wiki.guide_resources' }} },
                },
                contents = {{ 'redmew_wiki.moderation_guide' }}
            },
            {
                name = '[img=entity/character] Player manager',
                pages = {
                    { name = 'General actions', pages = {}, contents = {{ 'redmew_wiki.player_general_actions' }} },
                    { name = 'Players management', pages = {}, contents = {{ 'redmew_wiki.player_management' }} },
                    { name = 'Players kick & ban', pages = {}, contents = {{ 'redmew_wiki.player_kick_and_ban' }} },
                },
                contents = {{ 'redmew_wiki.player_manager' }}
            },
            {
                name = '[img=utility/surface_editor_icon] Map manager',
                pages = {
                    { name = 'Game speed', pages = {}, contents = {{ 'redmew_wiki.map_game_speed' }} },
                    { name = 'Pollution', pages = {}, contents = {{ 'redmew_wiki.map_pollution' }} },
                    { name = 'Evolution', pages = {}, contents = {{ 'redmew_wiki.map_evolution' }} },
                    { name = 'Exploration', pages = {}, contents = {{ 'redmew_wiki.map_expansion' }} },
                },
                contents = {{ 'redmew_wiki.map_manager' }}
            },
            {
                name = '[img=utility/scripting_editor_icon] Lua console',
                pages = {
                    { name = 'Description', contents = {{ 'redmew_wiki.lua_description' }} },
                    { name = 'Input', contents = {{ 'redmew_wiki.lua_input' }} },
                    { name = 'Output', contents = {{ 'redmew_wiki.lua_output' }} },
                },
                contents = {{ 'redmew_wiki.lua_console' }}
            }
        },
        contents = {{ 'redmew_wiki.admin_panel' }}
    }
}

local function build_entries(tree)
    local entries = {}

    local function walk(nodes, path, depth)
        for _, node in ipairs(nodes) do
            local newPath = { table.unpack(path) }
            table.insert(newPath, node.name)

            table.insert(entries, {
                node  = node,
                path  = newPath,
                depth = depth,
            })

            if node.pages and #node.pages > 0 then
                walk(node.pages, newPath, depth + 1)
            end
        end
    end

    walk(tree, {}, 0)
    return entries
end

local function get_indented_name(entry)
    local indent = string.rep(' ', entry.depth * 4)
    local name   = entry.path[#entry.path]
    return indent .. name
end

local function get_full_path(entry)
    return table.concat(entry.path, ' / ')
end

local function build_display_data(tree)
    local entries = build_entries(tree)

    -- items     : { 'Indented Name', ... }
    -- full_paths: { 'A / B / C', ... }
    -- contents  : { {...}, ... }

    local items      = {}
    local full_paths = {}
    local contents   = {}

    for i, entry in pairs(entries) do
        items[i]      = get_indented_name(entry)
        full_paths[i] = get_full_path(entry)
        contents[i]   = entry.node.contents or {}
    end

    return items, full_paths, contents
end

ModerationPages.moderation.draw = function(parent)
    local items, full_paths, contents = build_display_data(wiki)
    local data = {
        selected_index = 0,
        full_paths = full_paths,
        contents = contents,
    }

    local grid = parent.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(grid, { horizontal_spacing = 12 })
    local listbox = grid.add { type = 'list-box', items = items, name = guide_listbox_name }
    local display = grid.add { type = 'frame', style = 'inside_deep_frame', direction = 'vertical' }

    Gui.set_style(display, { natural_width = 450 })

    local content = display.add { type = 'flow', direction = 'vertical' }
    Gui.set_style(content, { vertically_stretchable = true, padding = 0 })

    do -- subheader
        local subheader = content.add { type = 'frame', style = 'subheader_frame' }
        Gui.set_style(subheader, { use_header_filler = true, horizontally_stretchable = true })

        local flow = subheader.add{ type = 'flow', style = 'horizontal_flow', direction = 'horizontal' }
        Gui.set_style(flow, { padding = 4 })

        data.title = flow.add { type = 'label', style = 'subheader_caption_label' }
    end

    do -- canvas
        data.canvas = content.add { type = 'scroll-pane', style = 'naked_scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space' }
        Gui.set_style(data.canvas, { maximal_height = 700, right_padding = 12, left_padding = 12, maximal_width = 450 })

        data.canvas.add { type = 'label', caption = { 'redmew_wiki.empty_entry' } }
    end

    Gui.set_data(listbox, data)
end

Gui.on_selection_state_changed(guide_listbox_name, function(event)
    local listbox = event.element
    local idx = listbox.selected_index
    local data = Gui.get_data(listbox)
    local canvas = data.canvas
    canvas.clear()

    if data.selected_index == idx then
        idx = 0
        listbox.selected_index = idx
        canvas.add { type = 'label', caption = { 'redmew_wiki.empty_entry' } }
    end

    data.selected_index = idx
    data.title.caption = data.full_paths[idx] or ''

    local contents = data.contents[idx] or {}
    for i, content in pairs(contents) do
        local label = canvas.add { type = 'label', caption = content }
        label.style.single_line = false

        if i < #contents then
            canvas.add { type = 'line', direction = 'horizontal' }
        end
    end
end)

-- == COMMANDS ================================================================

---@type ModCommand
---@field command string|LocalisedString
---@field help? string|LocalisedString
---@field rank? number
---@field extra? string|localisedString

---@type table<ModCommand>
local mod_commands = {}
Global.register(mod_commands, function(tbl) mod_commands = tbl end)

local mod_commands_search_name = Gui.uid_name()

local function build_mod_commands()
    -- Base commands generated from Wiki and localisation files
    local base_commands = {
        { command = 'admin', help = 'Opens the player management GUI.', rank = Ranks.admin },
        { command = 'admins', help = 'Prints a list of game admins (parameter online/o prints only admins that are online.)' },
        { command = 'alerts <enable/disable/mute/unmute> <alert>', help = 'Enables, disables, mutes, or unmutes the given alert type.' },
        { command = 'ban <player> <reason>', help = 'Bans the specified player.', rank = Ranks.admin },
        { command = 'banlist <add/remove/get/clear> <player>', help = 'Adds or removes a player from the banlist. Same as /ban or /unban.', rank = Ranks.admin },
        { command = 'bans', help = 'Prints a list of banned players.' },
        { command = 'cheat <all>', help = 'Researches all technologies and enables cheat mode. Using the <all> option also gives the player some additional items.\n <planet-name> - moves the player to the specified planet.\n <platform-name> - moves the player to the specified platform.\n <off> - turns the cheat mode off.', rank = Ranks.admin },
        { command = 'clear', help = 'Clears the console.' },
        { command = 'color <color>', help = 'Changes your color. Can either be one of the predefined colors or RGBA values in the format of "# # # #".' },
        { command = 'command <command>', help = '/c executes a Lua command.', rank = Ranks.admin },
        { command = 'config', help = 'Opens the server configuration GUI.', rank = Ranks.admin },
        { command = 'delete-blueprint-library <player>', help = 'Deletes the blueprint library storage for the given offline player from the save file. Enter "everybody confirm" to delete the storage of all offline players.', rank = Ranks.admin },
        { command = 'demote <player> ', help = 'Demotes the player from admin.', rank = Ranks.admin },
        { command = 'editor', help = 'Toggles the map editor.', rank = Ranks.admin },
        { command = 'evolution <surface>', help = 'Prints info about the alien evolution factor.' },
        { command = 'help-description', help = 'Type /h <command> to get details of it.' },
        { command = 'help-list', help = 'Available commands are:' },
        { command = 'help <command>', help = 'Prints a list of available commands. The optional argument can specify the command that should be described.' },
        { command = 'ignore <player> ', help = 'Prevents the chat from showing messages from this player. Admin messages are still shown.' },
        { command = 'ignores', help = 'Prints a list of ignored players.' },
        { command = 'kick <player> <reason>', help = 'Kicks the specified player.', rank = Ranks.admin },
        { command = 'large-blueprint-size <set/get> <number>', help = 'Sets or reads the threshold for what is a "large" blueprint (in bytes). Copying large blueprints will use the "large" version of the input action which can be optionally allowed/disabled through the permissions system.', rank = Ranks.admin },
        { command = 'measured-command <command>', help = '/mc executes a Lua command and measures time it took.', rank = Ranks.admin },
        { command = 'mute-programmable-speaker <mute/unmute> <local/everyone>', help = 'Mutes or unmutes global and surface sounds created by the Programmable Speaker. Use "local" to mute just the local client. Admins can use "everyone" to mute the sounds for everyone on the server.' },
        { command = 'mute <player>', help = 'Prevents the player from saying anything in chat.', rank = Ranks.admin },
        { command = 'mutes', help = 'Prints a list of all players that are muted (cannot talk in chat).' },
        { command = 'open <player>', help = '/o opens another player\'s inventory.', rank = Ranks.admin },
        { command = 'perf-avg-frames', help = 'Number of ticks/updates used to average performance counters. The default is 100. A value of 5-10 is recommended for fast convergence, but numbers will jitter more rapidly.' },
        { command = 'permissions', help = 'Opens the permissions GUI.', rank = Ranks.admin },
        { command = 'players', help = 'Prints a list of players in the game. (parameter online/o prints only players that are online. count/c prints only count)' },
        { command = 'promote <player>', help = 'Promotes the player to admin.', rank = Ranks.admin },
        { command = 'purge <player> ', help = 'Clears all the messages from this player from the chat log.', rank = Ranks.admin },
        { command = 'reply <message> ', help = '/r replies to the last player that whispered to you.' },
        { command = 'reset-tips', help = 'Resets the state of the tips and tricks as if the game was just started for the first time.' },
        { command = 'screenshot <x resolution> <y resolution> <zoom>', help = 'Takes a screenshot with your current view settings, or with the specified resolution. Zoom is optional and defaults to 1.' },
        { command = 'seed', help = 'Prints the starting map seed.' },
        { command = 'server-commands', help = 'Server console commands.' },
        { command = 'server-save', help = 'Saves the game on the server in a multiplayer game.', rank = Ranks.admin },
        { command = 'shout <message>', help = 'Sends a message to all players including other forces.' },
        { command = 'silent-command <command>', help = '/sc executes a Lua command without printing it to the console.', rank = Ranks.admin },
        { command = 'space-platform-delete-time <number>', help = 'Sets the number of ticks between requesting a space platform be deleted and it actually being deleted.', rank = Ranks.admin },
        { command = 'swap-players <player> <player>', help = 'Swaps characters between the specified players. If not given, the second player is yourself.', rank = Ranks.admin },
        { command = 'time', help = 'Prints info about how old the map is.' },
        { command = 'toggle-action-logging', help = 'Toggles logging of all input actions performed by the game. This value doesn\'t persist following game restarts and only effects your local game in multiplayer sessions.', rank = Ranks.admin },
        { command = 'toggle-heavy-mode', help = 'This command is to be used with caution as it will make the game multiplayer unplayable once set. The game starts to save and compare the game with itself every tick to search for inconsistencies in the determinism. This command is advised to be used when there is a desync loop when a new player joins the server. The heavy mode will run until it outputs something. Please provide it to us so we can investigate and fix the problem.', rank = Ranks.admin },
        { command = 'unban <player>', help = 'Unbans the specified player.', rank = Ranks.admin },
        { command = 'unignore <player>', help = 'Allows the chat to show messages from this player.' },
        { command = 'unlock-shortcut-bar', help = 'Unlocks all shortcut bar items.' },
        { command = 'unlock-tips', help = 'Unlocks all tips and trick entries.' },
        { command = 'unmute <player>', help = 'Allows the player to talk in chat again.', rank = Ranks.admin },
        { command = 'version', help = 'Prints the current game version.' },
        { command = 'whisper <player> <message>', help = '/w sends a message to the specified player only.' },
        { command = 'whitelist <enable/disable/add/remove/get/clear> <player>', help = 'Enables, disables, adds or removes a player from the whitelist, where only whitelisted players can join the game. Enter nothing for \'player\' when using \'get\' to print a list of all whitelisted players.' },
    }

    -- RedMew commands generated from command module
    local redmew_commands = {}
    do
        for _, cmd in pairs(Command.list()) do
            local name = cmd.name or ''
            if cmd.argument_list then
                name = name .. ' ' .. cmd.argument_list
            end

            local help = nil
            if cmd.help and (#cmd.help >= 3) then
                help = cmd.help[3]
            end
            if help == '' then
                help = nil
            end

            local extra = cmd.extra or {''}
            -- Remove required rank (displayed separatedly)
            if extra[1] == 'command.required_rank' then
                extra = {''}
            end
            -- Append second help string if it's a table (remove string arguments displayed with name)
            if type(cmd.help) == 'table' and type(cmd.help[2]) == 'table' then
                table.insert(extra, cmd.help[2])
            end
            -- Set extra to nil if it contains only an empty string
            if (#extra == 1 and extra[1] == '') then
                extra = nil
            end

            table.insert(redmew_commands, {
                command = name,
                help = help,
                rank = cmd.rank,
                extra = extra,
            })
        end
    end

    for _, list in pairs{ base_commands, redmew_commands } do
        for _, e in pairs(list) do
            table.insert(mod_commands, e)
        end
    end
    table.sort(mod_commands, function(a, b) return a.command < b.command end)
end

ModerationPages.commands.draw = function(parent)
    if #mod_commands == 0 then
        build_mod_commands()
    end

    local window = parent
        .add { type = 'frame', style = 'inside_shallow_frame_with_padding' }
        .add { type = 'scroll-pane', style = 'naked_scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space' }
    Gui.set_style(window, { maximal_height = 700, right_padding = 4 })

    local flow = inline(window)
    bold(flow, 'Search: ')
    local search_field = flow.add { type = 'text-box', name = mod_commands_search_name, text = '', style = 'search_popup_textfield' }
    Gui.set_style(search_field, { width = 456 - 48 - 4 - 34 - 4 + 2 + 12 })

    local result_count = flow.add { type = 'sprite-button', style = 'button', caption = #mod_commands, tooltip = 'Results count' }
    Gui.set_style(result_count, { height = 26, width = 34, padding = 0 })

    local command_table = window.add { type = 'table', style = 'finished_game_table', column_count = 1 }
    Gui.set_data(search_field, { command_table = command_table, result_count = result_count })

    for i, cmd in pairs(mod_commands) do
        local grid = command_table.add { type = 'table', style = 'player_input_table', column_count = 2 }

        grid.style.column_alignments[1] = 'top-center'
        grid.style.column_alignments[2] = 'top-left'
        Gui.set_style(grid, { vertical_spacing = 4 })

        local icon = font(grid, '[img=developer]')
        Gui.set_style(icon, { minimal_width = 20, left_padding = 6 })

        local command = bold(grid, '/' .. cmd.command, Color.light_cyan)
        Gui.set_style(command, { maximal_width = 420, single_line = false })

        do -- rank
            font(grid, '[img=quality_info]')
            font(grid, Rank.get_rank_name(cmd.rank or Ranks.guest), Color.khaki)
        end
        if cmd.help then
            font(grid, '[img=info]')
            local help = font(grid, cmd.help)
            Gui.set_style(help, { maximal_width = 420, single_line = false })
        end
        if cmd.extra then
            font(grid, '[img=warning-white]')
            local extra = font(grid, cmd.extra)
            Gui.set_style(extra, { maximal_width = 420, single_line = false })
        end
    end
end

local function match_command_pattern(grid, pattern)
    local labels = grid.children
    for i = 2, 8, 2 do
        local obj = labels[i]
        if obj and obj.valid then
            local content = obj.caption
            if (content ~= nil) and (type(content) == 'string') and string_match(string_lower(content), pattern) then
                return true
            end
        end
    end
    return false
end

local function filter_commands(command_table, pattern)
    local count = 0
    for _, child in pairs(command_table.children) do
        local visible = match_command_pattern(child, pattern)
        child.visible = visible
        count = count + (visible and 1 or 0)
    end
    return count
end

Gui.on_text_changed(mod_commands_search_name, function(event)
    local element = event.element
    local data = Gui.get_data(element)
    local pattern = string_lower(element.text):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') -- escape magic chars
    data.result_count.caption = filter_commands(data.command_table, pattern)
end)

-- == SERVER ==================================================================

local server_commands_search_name = Gui.uid_name()

--[[
    Tags collection:
    - Script: requires console command
    - Error: server related
    - Bug: scenario related
    - Moderation: player/map related
]]

local maps = {
    af = 'April Fools',
    cs = 'Crash Site',
    ds = 'Danger Ores',
    dy = 'Diggy',
    ex = 'Expanse',
    fr = 'Frontier',
    va = 'Vanilla',
}

---@type ServerCommand
---@field command string|LocalisedString
---@field help? string|LocalisedString
---@field snippet? string
---@field tags? table<string|LocalisedString>

---@type table<ServerCommand>
local server_commands = {
    { command = 'Auto stash into furnaces', help = 'Enable auto stashing directly into furnaces from auto-stash module (default: OFF)', snippet = '/sc _G.package.loaded[\'__level__/features/auto_stash.lua\']\n.insert_into_furnace(true)', tags = { 'Script' } },
    { command = 'Cleanup items on ground', help = 'Clears all items dropped on ground (poop, chestplosion, coins) causing UPS lag', snippet = '/sc for _, corpse in pairs(game.player.surface.find_entities_filtered{ name = \'item-on-ground\' }) do corpse.destroy() end ', tags = { 'Script', 'Moderation' } },
    { command = 'Error: transport line groups are not consistent', help = 'If when trying to join/load a game this error pops up, this is how to fix it: \n- Download the map from web interface \n- Load the map in single player by pressing "ALT + SHIFT" when hitting "Load" \n- Save the map with fixed transport groups \n- Replace save on the server', tags = { 'Error' } },
    { command = 'Find and ping enemies', help = 'Useful to locate last enemies standing in Crash Site', snippet = '/sc for _, e in pairs(game.player.surface.find_entities_filtered{ force = \'enemy\', name = { \'gun-turret\', \'small-worm-turret\' }}) do local p = entity.position game.print(\'[gps=\'..p.x..\',\'..p.y..\',game.player.surface.name]\') end', tags = { maps.cs, 'Script' } },
    { command = 'Market::add item', help = 'Adds a new item to the spawn Market', snippet = '/sc local r = package.loaded[\'__level__/features.retailer\'] r.set_item(\'fish_market\', { price = 20, name = \'logistic-robot\'} )', tags = { 'Script' } },
    { command = 'Market::remove item', help = 'Removes an item from the spawn Market', snippet = '/sc local r = package.loaded[\'__level__/features.retailer\'] r.add_item(\'fish_market\', \'logistic-robo\')', tags = { 'Script' } },
    { command = 'Recreate the endless rock in expanse', help = 'Sometimes the endless rock bugs, needs to be restored via command', snippet = '/sc game.player.surface.create_entity{name = \'huge-rock\', position = {0,8}, move_stuck_players = true}', tags = { 'Script', 'Bug', maps.ex } },
    { command = 'Require runtime file', help = 'Correct syntax for requiring files in console at runtime', snippet = '/sc _G.package.loaded[\'__level__/map_gen/shared/entity_placement_restriction.lua\'].add_allowed({\'pipe\', \'pumpjack\', })', tags = { 'Script'} },
    { command = 'Reset progression', help = 'Reset recipes, bonuses, technologies and whatnot to default', snippet = '/sc game.forces.player.reset_technology_effects()', tags = { 'Script' } },
    { command = 'Technology multiplier', help = 'Change the technology cost multiplier at runtime', snippet = '/sc game.difficulty_settings.technology_price_multiplier = 25', tags = { 'Script'} },
    { command = 'Unlock nearby chunks', help = 'Spawn more pollution when players are deadlocked in terraforming module. Works with remote view too.', snippet = '/sc game.player.surface.pollute(game.player.position, 1e6)', tags = { 'Moderation', maps.ds } },
}

ModerationPages.server.draw = function(parent)
    local window = parent
        .add { type = 'frame', style = 'inside_shallow_frame_with_padding' }
        .add { type = 'scroll-pane', style = 'naked_scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space' }
    Gui.set_style(window, { maximal_height = 700, right_padding = 4 })

    local flow = inline(window)
    bold(flow, 'Search: ')
    local search_field = flow.add { type = 'text-box', name = server_commands_search_name, text = '', style = 'search_popup_textfield' }
    Gui.set_style(search_field, { width = 456 - 48 - 4 - 34 - 4 + 2 + 12 })

    local result_count = flow.add { type = 'sprite-button', style = 'button', caption = #server_commands, tooltip = 'Results count' }
    Gui.set_style(result_count, { height = 26, width = 34, padding = 0 })

    local command_table = window.add { type = 'table', style = 'finished_game_table', column_count = 1 }
    Gui.set_data(search_field, { command_table = command_table, result_count = result_count })

    for i, cmd in pairs(server_commands) do
        local grid = command_table.add { type = 'table', style = 'player_input_table', column_count = 2 }

        grid.style.column_alignments[1] = 'top-center'
        grid.style.column_alignments[2] = 'top-left'
        Gui.set_style(grid, { vertical_spacing = 4 })

        -- Title
        local icon = font(grid, '[img=developer]')
        Gui.set_style(icon, { minimal_width = 20, left_padding = 6 })

        local command = bold(grid, cmd.command, Color.light_cyan)
        Gui.set_style(command, { maximal_width = 420, single_line = false })

        -- Tags
        if cmd.tags and (#cmd.tags > 0) then
            font(grid, '[img=quality_info]')
            font(grid, table.concat(cmd.tags, ', '), Color.khaki)
        end

        -- Help
        if cmd.help then
            font(grid, '[img=info]')
            local desc = font(grid, cmd.help)
            Gui.set_style(desc, {
                single_line = false,
                maximal_width = 420,
            })
        end

        -- Snippet
        if cmd.snippet then
            empty(grid)
            textbox(grid, cmd.snippet, 420)
        end
    end
end

local function match_server_pattern(grid, pattern)
    local labels = grid.children
    for i = 2, 8, 2 do
        local obj = labels[i]
        local content
        if obj and obj.valid then
            if obj.type == 'label' then
                content = obj.caption
            elseif (obj.type == 'textfield') or (obj.type == 'text-box') then
                content = obj.text
            end
            if (content ~= nil) and (type(content) == 'string') and string_match(string_lower(content), pattern) then
                return true
            end
        end
    end
    return false
end

local function filter_server(server_table, pattern)
    local count = 0
    for _, child in pairs(server_table.children) do
        local visible = match_server_pattern(child, pattern)
        child.visible = visible
        count = count + (visible and 1 or 0)
    end
    return count
end

Gui.on_text_changed(server_commands_search_name, function(event)
    local element = event.element
    local data = Gui.get_data(element)
    local pattern = string_lower(element.text):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') -- escape magic chars
    data.result_count.caption = filter_server(data.command_table, pattern)
end)

-- == RESOURCES ===============================================================

ModerationPages.resources.draw = function(parent)
    local window = parent
        .add { type = 'frame', style = 'inside_shallow_frame_with_padding' }
        .add { type = 'flow', direction = 'vertical' }
    Gui.set_style(window, { vertical_spacing = 6 })

    font(window, 'Admins and Moderators onboarding URL: ')
    textbox(window, 'github.com/Refactorio/RedMew/wiki/Moderator-and-Admin-Guide', 456)

    line(window)

    bold(window, 'RedMew\'s mission statement', Color.pale_golden_rod)
    font(window, text{
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

return ModerationPages
