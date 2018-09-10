local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Donators = require 'resources.donators'
local UserGroups = require 'user_groups'
local PlayerStats = require 'player_stats'
local Utils = require 'utils.utils'
local Report = require 'report'

local poke_messages = require 'resources.poke_messages'
local player_sprites = require 'resources.player_sprites'

local poke_cooldown_time = 240 -- in ticks.
local sprite_time_step = 54000 -- in ticks
local symbol_asc = ' ▲'
local symbol_desc = ' ▼'
local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}
local rank_colors = {
    {r = 1, g = 1, b = 1}, -- Guest
    {r = 0.155, g = 0.540, b = 0.898}, -- Regular
    {r = 172.6, g = 70.2, b = 215.8}, -- Donator {r = 152, g = 24, b = 206}
    {r = 0.093, g = 0.768, b = 0.172} -- Admin
}

local inv_sprite_time_step = 1 / sprite_time_step
local rank_perk_flag = Donators.donator_perk_flags.rank
local rank_names = {
    'Guest',
    'Regular',
    'Donator',
    'Admin'
}

local player_poke_cooldown = {}
local player_pokes = {}
local player_settings = {}
local no_notify_players = {}

Global.register(
    {
        player_poke_cooldown = player_poke_cooldown,
        player_pokes = player_pokes,
        player_settings = player_settings,
        no_notify_players = no_notify_players
    },
    function(tbl)
        player_poke_cooldown = tbl.player_poke_cooldown
        player_pokes = tbl.player_pokes
        player_settings = tbl.player_settings
        no_notify_players = tbl.no_notify_players
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local notify_checkbox_name = Gui.uid_name()

local sprite_heading_name = Gui.uid_name()
local player_name_heading_name = Gui.uid_name()
local time_heading_name = Gui.uid_name()
local rank_heading_name = Gui.uid_name()
local distance_heading_name = Gui.uid_name()
local coin_heading_name = Gui.uid_name()
local deaths_heading_name = Gui.uid_name()
local poke_name_heading_name = Gui.uid_name()
local report_heading_name = Gui.uid_name()

local sprite_cell_name = Gui.uid_name()
local player_name_cell_name = Gui.uid_name()
local time_cell_name = Gui.uid_name()
local rank_cell_name = Gui.uid_name()
local distance_cell_name = Gui.uid_name()
local coin_cell_name = Gui.uid_name()
local deaths_cell_name = Gui.uid_name()
local poke_cell_name = Gui.uid_name()
local report_cell_name = Gui.uid_name()

local function lighten_color(color)
    color.r = color.r * 0.6 + 0.4
    color.g = color.g * 0.6 + 0.4
    color.b = color.b * 0.6 + 0.4
    color.a = 1
end

local function format_distance(tiles)
    return math.round(tiles * 0.001, 1) .. ' km'
end

local function get_rank_level(player)
    if player.admin then
        return 4
    end

    local name = player.name
    if UserGroups.is_donator_perk(name, rank_perk_flag) then
        return 3
    elseif UserGroups.is_regular(name) then
        return 2
    end

    return 1
end

local function do_poke_spam_protection(player)
    if player.admin then
        return true
    end

    local tick = player_poke_cooldown[player.index] or 0

    if tick < game.tick then
        player_poke_cooldown[player.index] = game.tick + poke_cooldown_time
        return true
    else
        return false
    end
end

local function apply_heading_style(style)
    style.font_color = focus_color
    style.font = 'default-bold'
    style.align = 'center'
end

local column_builders = {
    [sprite_heading_name] = {
        create_data = function(player)
            local ticks = player.online_time
            local level = math.floor(ticks * inv_sprite_time_step) + 1
            level = math.min(level, #player_sprites)

            return level
        end,
        sort = function(a, b)
            return a < b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = sprite_heading_name, caption = ' '}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 32

            return label
        end,
        draw_cell = function(parent, cell_data)
            local label =
                parent.add {
                type = 'sprite',
                name = sprite_cell_name,
                sprite = player_sprites[cell_data]
            }
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 32

            return label
        end
    },
    [player_name_heading_name] = {
        create_data = function(player)
            return player
        end,
        sort = function(a, b)
            return a.name:lower() < b.name:lower()
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = player_name_heading_name, caption = 'Name'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 150

            return label
        end,
        draw_cell = function(parent, cell_data)
            local color = cell_data.color
            lighten_color(color)
            local name = cell_data.name
            local label =
                parent.add {
                type = 'label',
                name = player_name_cell_name,
                caption = name,
                tooltip = name
            }
            local label_style = label.style
            label_style.font_color = color
            label_style.align = 'left'
            label_style.width = 150

            return label
        end
    },
    [time_heading_name] = {
        create_data = function(player)
            return player.online_time
        end,
        sort = function(a, b)
            return a < b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = time_heading_name, caption = 'Time'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 125

            return label
        end,
        draw_cell = function(parent, cell_data)
            local text = Utils.format_time(cell_data)

            local label = parent.add {type = 'label', name = time_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'left'
            label_style.width = 125

            return label
        end
    },
    [rank_heading_name] = {
        create_data = get_rank_level,
        sort = function(a, b)
            return a < b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = rank_heading_name, caption = 'Rank'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 50

            return label
        end,
        draw_cell = function(parent, cell_data)
            local label = parent.add {type = 'label', name = rank_cell_name, caption = rank_names[cell_data]}
            local label_style = label.style
            label_style.align = 'center'
            label_style.font_color = rank_colors[cell_data]
            label_style.width = 50

            return label
        end
    },
    [distance_heading_name] = {
        create_data = function(player)
            return PlayerStats.get_walk_distance(player.index)
        end,
        sort = function(a, b)
            return a < b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = distance_heading_name, caption = 'Distance'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 70

            return label
        end,
        draw_cell = function(parent, cell_data)
            local text = format_distance(cell_data)

            local label = parent.add {type = 'label', name = distance_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 70

            return label
        end
    },
    [coin_heading_name] = {
        create_data = function(player)
            local index = player.index
            return {
                coin_earned = PlayerStats.get_coin_earned(index),
                coin_spent = PlayerStats.get_coin_spent(index)
            }
        end,
        sort = function(a, b)
            local a_coin_earned, b_coin_earned = a.coin_earned, b.coin_earned
            if a_coin_earned == b_coin_earned then
                return a.coin_spent < b.coin_spent
            else
                return a_coin_earned < b_coin_earned
            end
        end,
        draw_heading = function(parent)
            local label =
                parent.add {
                type = 'label',
                name = coin_heading_name,
                caption = 'Coins',
                tooltip = 'Coins earned / spent.'
            }
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 80

            return label
        end,
        draw_cell = function(parent, cell_data)
            local text = table.concat({cell_data.coin_earned, '/', cell_data.coin_spent})

            local label = parent.add {type = 'label', name = coin_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 80

            return label
        end
    },
    [deaths_heading_name] = {
        create_data = function(player)
            local player_index = player.index
            return {
                count = PlayerStats.get_death_count(player_index),
                causes = PlayerStats.get_all_death_counts_by_casue(player_index)
            }
        end,
        sort = function(a, b)
            return a.count < b.count
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = deaths_heading_name, caption = 'Deaths'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 60

            return label
        end,
        draw_cell = function(parent, cell_data)
            local tooltip = {}
            for name, count in pairs(cell_data.causes) do
                table.insert(tooltip, name)
                table.insert(tooltip, ': ')
                table.insert(tooltip, count)
                table.insert(tooltip, '\n')
            end
            table.remove(tooltip)
            tooltip = table.concat(tooltip)

            local label =
                parent.add {type = 'label', name = deaths_cell_name, caption = cell_data.count, tooltip = tooltip}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 60

            return label
        end
    },
    [poke_name_heading_name] = {
        create_data = function(player)
            return {poke_count = player_pokes[player.index] or 0, player = player}
        end,
        sort = function(a, b)
            return a.poke_count < b.poke_count
        end,
        draw_heading = function(parent, data)
            local label = parent.add {type = 'label', name = poke_name_heading_name, caption = 'Poke'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 60

            data.poke_buttons = {}

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local player = cell_data.player

            local parent_style = parent.style
            parent_style.width = 64
            parent_style.align = 'center'

            local label = parent.add {type = 'button', name = poke_cell_name, caption = cell_data.poke_count}
            local label_style = label.style
            label_style.align = 'center'
            label_style.minimal_width = 32
            label_style.height = 24
            label_style.font = 'default-bold'
            label_style.top_padding = 0
            label_style.bottom_padding = 0
            label_style.left_padding = 0
            label_style.right_padding = 0

            data.poke_buttons[player.index] = label

            Gui.set_data(label, {data = data, player = player})

            return label
        end
    },
    [report_heading_name] = {
        create_data = function(player)
            return player
        end,
        sort = function(a, b)
            return a.name:lower() < b.name:lower()
        end,
        draw_heading = function(parent, data)
            local label =
                parent.add {
                type = 'label',
                name = report_heading_name,
                caption = 'Report',
                tooltip = 'Report player to the admin team for griefing or breaking the rules.'
            }
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 58

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local parent_style = parent.style
            parent_style.width = 58
            parent_style.align = 'center'

            local label =
                parent.add {
                type = 'sprite-button',
                name = report_cell_name,
                sprite = 'utility/force_editor_icon',
                tooltip = 'Report ' .. cell_data.name
            }
            local label_style = label.style
            label_style.align = 'center'
            label_style.minimal_width = 32
            label_style.height = 24
            label_style.font = 'default-bold'
            label_style.top_padding = 0
            label_style.bottom_padding = 0
            label_style.left_padding = 0
            label_style.right_padding = 0

            Gui.set_data(label, cell_data)

            return label
        end
    }
}

local function get_default_player_settings()
    return {
        columns = {
            sprite_heading_name,
            player_name_heading_name,
            time_heading_name,
            rank_heading_name,
            distance_heading_name,
            coin_heading_name,
            deaths_heading_name,
            poke_name_heading_name,
            report_heading_name
        },
        sort = -3
    }
end

local function redraw_title(data)
    local frame = data.frame

    local online_count = #game.connected_players
    local total_count = PlayerStats.get_total_player_count()

    local title = table.concat {'Player list - Online: ', online_count, ' Total: ' .. total_count}

    frame.caption = title
end

local function redraw_headings(data)
    local settings = data.settings
    local columns = settings.columns
    local sort = settings.sort
    local sort_column = math.abs(sort)

    local sort_symbol
    if sort > 0 then
        sort_symbol = symbol_asc
    else
        sort_symbol = symbol_desc
    end

    local heading_table_flow = data.heading_table_flow
    Gui.clear(heading_table_flow)

    local heading_table = heading_table_flow.add {type = 'table', column_count = #columns}

    for i, c in ipairs(settings.columns) do
        local heading = column_builders[c].draw_heading(heading_table, data)

        if i == sort_column then
            heading.caption = heading.caption .. sort_symbol
        end

        Gui.set_data(heading, {data = data, index = i})
    end
end

local function redraw_cells(data)
    local settings = data.settings
    local columns = settings.columns
    local sort = settings.sort
    local sort_column = math.abs(sort)
    local column_name = columns[sort_column]
    local column_sort = column_builders[column_name].sort

    local comp
    if sort > 0 then
        comp = function(a, b)
            return column_sort(a[sort_column], b[sort_column])
        end
    else
        comp = function(a, b)
            return column_sort(b[sort_column], a[sort_column])
        end
    end

    local cell_table_scroll_pane = data.cell_table_scroll_pane
    Gui.clear(cell_table_scroll_pane)

    local grid = cell_table_scroll_pane.add {type = 'table', column_count = #columns}

    local list_data = {}
    for _, p in ipairs(game.connected_players) do
        local row = {}

        for _, c in ipairs(columns) do
            local cell_data = column_builders[c].create_data(p)
            table.insert(row, cell_data)
        end

        table.insert(list_data, row)
    end

    table.sort(list_data, comp)

    for _, row in ipairs(list_data) do
        for c_i, c in ipairs(columns) do
            local flow = grid.add {type = 'flow'}
            column_builders[c].draw_cell(flow, row[c_i], data)
        end
    end
end

local function draw_main_frame(left, player)
    local player_index = player.index
    local frame = left.add {type = 'frame', name = main_frame_name, direction = 'vertical'}

    local heading_table_flow = frame.add {type = 'flow'}

    local cell_table_scroll_pane = frame.add {type = 'scroll-pane'}
    cell_table_scroll_pane.style.maximal_height = 400

    frame.add {
        type = 'checkbox',
        name = notify_checkbox_name,
        state = not no_notify_players[player_index],
        caption = 'Notify me when pokes happen.',
        tooltip = 'Receive a message when a player pokes another player.'
    }

    frame.add {type = 'button', name = main_button_name, caption = 'Close'}

    local settings = player_settings[player_index] or get_default_player_settings()
    local data = {
        frame = frame,
        heading_table_flow = heading_table_flow,
        cell_table_scroll_pane = cell_table_scroll_pane,
        settings = settings
    }

    redraw_title(data)
    redraw_headings(data)
    redraw_cells(data)

    Gui.set_data(frame, data)
end

local function remove_main_frame(frame, player)
    local frame_data = Gui.get_data(frame)
    player_settings[player.index] = frame_data.settings

    Gui.destroy(frame)
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        remove_main_frame(main_frame, player)
    else
        draw_main_frame(left, player)
    end
end

local function tick()
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]

        if frame and frame.valid then
            local data = Gui.get_data(frame)
            redraw_cells(data)
        end
    end
end

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local gui = player.gui
    local top = gui.top

    if not top[main_button_name] then
        top.add {type = 'sprite-button', name = main_button_name, sprite = 'entity/player'}
    end

    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]

        if frame and frame.valid then
            local data = Gui.get_data(frame)
            redraw_title(data)
            redraw_cells(data)
        end
    end
end

local function player_left()
    for _, p in ipairs(game.connected_players) do
        local frame = p.gui.left[main_frame_name]

        if frame and frame.valid then
            local data = Gui.get_data(frame)
            redraw_title(data)
            redraw_cells(data)
        end
    end
end

Event.on_nth_tick(1800, tick)
Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_player_left_game, player_left)

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    notify_checkbox_name,
    function(event)
        local player_index = event.player_index
        local checkbox = event.element

        local new_state
        if checkbox.state then
            new_state = nil
        else
            new_state = true
        end

        no_notify_players[player_index] = new_state
    end
)

local function headings_click(event)
    local heading_data = Gui.get_data(event.element)
    local data = heading_data.data
    local settings = data.settings
    local index = heading_data.index

    local sort = settings.sort
    local sort_column = math.abs(sort)

    if sort_column == index then
        sort = -sort
    else
        sort = -index
    end

    settings.sort = sort

    redraw_headings(data)
    redraw_cells(data)
end

for name, _ in pairs(column_builders) do
    Gui.on_click(name, headings_click)
end

Gui.on_click(
    poke_cell_name,
    function(event)
        local element = event.element
        local button_data = Gui.get_data(element)
        local poke_player = button_data.player
        local player = event.player

        if poke_player == player then
            return
        end

        local poke_player_index = poke_player.index
        if not do_poke_spam_protection(player) then
            return
        end

        local count = (player_pokes[poke_player_index] or 0) + 1
        player_pokes[poke_player_index] = count

        local poke_str = poke_messages[math.random(#poke_messages)]
        local message = table.concat({'>> ', player.name, ' has poked ', poke_player.name, ' with ', poke_str, ' <<'})

        for _, p in ipairs(game.connected_players) do
            local frame = p.gui.left[main_frame_name]
            if frame and frame.valid then
                local frame_data = Gui.get_data(frame)
                local poke_bottons = frame_data.poke_buttons

                if poke_bottons then
                    local settings = frame_data.settings

                    local columns = settings.columns
                    local sort = settings.sort

                    local sorted_column = columns[math.abs(sort)]
                    if sorted_column == poke_name_heading_name then
                        redraw_cells(frame_data)
                    else
                        local poke_button = poke_bottons[poke_player_index]
                        poke_button.caption = count
                    end
                end
            end

            if not no_notify_players[p.index] then
                p.print(message)
            end
        end
    end
)

Gui.on_click(
    report_cell_name,
    function(event)
        local reporting_player = event.player
        local reported_player = Gui.get_data(event.element)

        Report.spawn_reporting_popup(reporting_player, reported_player)
    end
)
