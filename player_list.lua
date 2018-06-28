local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local UserGroups = require 'user_groups'
local PlayerStats = require 'player_stats'

local symbol_asc = ' ▲'
local symbol_desc = ' ▼'
local normal_color = {r = 1, g = 1, b = 1}
local focus_color = {r = 1, g = 0.55, b = 0.1}

local player_poke_cooldown = {}
local player_pokes = {}
local player_settings = {}

Global.register(
    {player_poke_cooldown = player_poke_cooldown, player_pokes = player_pokes, player_settings = player_settings},
    function(tbl)
        player_poke_cooldown = tbl.player_poke_cooldown
        player_pokes = player_pokes
        player_settings = tbl.player_settings
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

--local heading_table_name = Gui.uid_name()
local player_name_heading_name = Gui.uid_name()
local time_heading_name = Gui.uid_name()
local rank_heading_name = Gui.uid_name()
local distance_heading_name = Gui.uid_name()
local fish_heading_name = Gui.uid_name()
local deaths_heading_name = Gui.uid_name()
local poke_name_heading_name = Gui.uid_name()

--local cell_table_name = Gui.uid_name()
local player_name_cell_name = Gui.uid_name()
local time_cell_name = Gui.uid_name()
local rank_cell_name = Gui.uid_name()
local distance_cell_name = Gui.uid_name()
local fish_cell_name = Gui.uid_name()
local deaths_cell_name = Gui.uid_name()
local poke_cell_name = Gui.uid_name()

local function lighten_color(color)
    color.r = color.r * 0.6 + 0.4
    color.g = color.g * 0.6 + 0.4
    color.b = color.b * 0.6 + 0.4
    color.a = 1
end

local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks

local function format_time(ticks)
    local result = {}

    local hours = math.floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        table.insert(result, hours)
        if hours == 1 then
            table.insert(result, 'hour')
        else
            table.insert(result, 'hours')
        end
    end

    local minutes = math.floor(ticks * ticks_to_minutes)
    table.insert(result, minutes)
    if minutes == 1 then
        table.insert(result, 'minute')
    else
        table.insert(result, 'minutes')
    end

    return table.concat(result, ' ')
end

local function format_distance(tiles)
    return math.round(tiles * 0.001, 1) .. ' km'
end

local function apply_heading_style(style)
    style.font_color = focus_color
    style.font = 'default-bold'
    style.align = 'center'
end

local column_builders = {
    [player_name_heading_name] = {
        create_data = function(player)
            return player
        end,
        sort = function(a, b)
            return a.name > b.name
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = player_name_heading_name, caption = 'Name'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local color = cell_data.color
            lighten_color(color)
            local label =
                parent.add {
                type = 'label',
                name = player_name_cell_name,
                caption = cell_data.name
            }
            local label_style = label.style
            label_style.font_color = color
            label_style.align = 'center'
            label_style.width = 100

            return label
        end
    },
    [time_heading_name] = {
        create_data = function(player)
            return player.online_time
        end,
        sort = function(a, b)
            return a > b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = time_heading_name, caption = 'Time'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local text = format_time(cell_data)

            local label = parent.add {type = 'label', name = time_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 100

            return label
        end
    },
    [rank_heading_name] = {
        create_data = function(player)
            return UserGroups.get_rank(player)
        end,
        sort = function(a, b)
            return a > b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = rank_heading_name, caption = 'Rank'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local label = parent.add {type = 'label', name = rank_cell_name, caption = cell_data}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 100

            return label
        end
    },
    [distance_heading_name] = {
        create_data = function(player)
            return PlayerStats.get_walk_distance(player.index)
        end,
        sort = function(a, b)
            return a > b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = distance_heading_name, caption = 'Distance'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local text = format_distance(cell_data)

            local label = parent.add {type = 'label', name = distance_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 100

            return label
        end
    },
    [fish_heading_name] = {
        create_data = function(player)
            local index = player.index
            return {
                fish_earnt = PlayerStats.get_fish_earned(index),
                fish_spent = PlayerStats.get_fish_spent(index)
            }
        end,
        sort = function(a, b)
            local a_fish_earned, b_fish_earned = a.fish_earned, b.fish_earned
            if a_fish_earned == b_fish_earned then
                return a.fish_spent > b.fish_spent
            else
                return a_fish_earned > b_fish_earned
            end
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = fish_heading_name, caption = 'Fish'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local text = table.concat({cell_data.fish_earnt, ' / ', cell_data.fish_spent})

            local label = parent.add {type = 'label', name = fish_cell_name, caption = text}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 100

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
            return a.count > b.count
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = deaths_cell_name, caption = 'Deaths'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
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
            label_style.width = 100

            return label
        end
    },
    [poke_name_heading_name] = {
        create_data = function(player)
            return player_pokes[player.index] or 0
        end,
        sort = function(a, b)
            return a > b
        end,
        draw_heading = function(parent)
            local label = parent.add {type = 'label', name = poke_name_heading_name, caption = 'Poke'}
            local label_style = label.style
            apply_heading_style(label_style)
            label_style.width = 100

            return label
        end,
        draw_cell = function(parent, cell_data, data)
            local label = parent.add {type = 'button', name = poke_cell_name, caption = cell_data}
            local label_style = label.style
            label_style.align = 'center'
            label_style.width = 100

            return label
        end
    }
}

local default_player_settings = {
    columns = {
        player_name_heading_name,
        time_heading_name,
        rank_heading_name,
        distance_heading_name,
        fish_heading_name,
        deaths_heading_name,
        poke_name_heading_name
    },
    sort = -2
}

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
        local heading = column_builders[c].draw_heading(heading_table)

        if i == sort_column then
            heading.caption = heading.caption .. sort_symbol
        end

        Gui.set_data(heading, data)
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
    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Player list', direction = 'vertical'}

    local heading_table_flow = frame.add {type = 'flow'}

    local cell_table_scroll_pane = frame.add {type = 'scroll-pane'}
    cell_table_scroll_pane.style.maximal_height = 600

    frame.add {type = 'button', name = main_button_name, caption = 'Close'}

    local data = {
        heading_table_flow = heading_table_flow,
        cell_table_scroll_pane = cell_table_scroll_pane,
        settings = default_player_settings
    }

    redraw_headings(data)
    redraw_cells(data)
end

local function remove_main_frame(frame)
    Gui.remove_data_recursivly(frame)
    frame.destroy()
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame then
        remove_main_frame(main_frame)
    else
        draw_main_frame(left, player)
    end
end

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local top = player.gui.top

    if not top[main_button_name] then
        top.add {type = 'sprite-button', name = main_button_name, sprite = 'item/heavy-armor'}
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)

Gui.on_click(main_button_name, toggle)
