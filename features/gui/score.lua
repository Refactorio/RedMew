local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.task'
local Gui = require 'utils.gui'
local Styles = require 'resources.styles'
local Color = require 'resources.color_presets'
local Server = require 'features.server'
local ScoreTracker = require 'utils.score_tracker'
local format_number = require 'util'.format_number
local pairs = pairs
local concat = table.concat
local min = math.min
local format = string.format
local scores_to_show = storage.config.score.global_to_show
local score_goals = storage.config.score.goals or {}
local set_timeout_in_ticks = Schedule.set_timeout_in_ticks
local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

local memory = {
    redraw_score_scheduled = false,
    player_last_position = {},
    player_death_causes = {}
}

Global.register(
    memory,
    function(tbl)
        memory = tbl
    end
)

---Creates a map of score name => {caption, tooltip, progress}, where progress (0 to 1) is only
---set for scores with a goal in storage.config.score.goals
local function get_global_score_labels()
    local scores = ScoreTracker.get_global_scores_with_metadata(scores_to_show)
    local score_labels = {}

    for index = 1, #scores do
        local score_data = scores[index]
        local value = score_data.value
        local goal = score_goals[score_data.name]

        if goal and goal > 0 then
            local progress = min(value / goal, 1)
            score_labels[score_data.name] = {
                caption = concat({score_data.icon, format_number(value, true), '/', format_number(goal, true)}, ' '),
                tooltip = {'score.goal_tooltip', score_data.locale_string, format_number(value), format_number(goal), format('%.1f', progress * 100)},
                progress = progress
            }
        else
            score_labels[score_data.name] = {
                caption = concat({score_data.icon, format_number(value, true)}, ' '),
                tooltip = score_data.locale_string
            }
        end
    end

    return score_labels
end

local do_redraw_score =
    Token.register(
    function()
        local players = game.connected_players
        local scores = get_global_score_labels()

        for i = 1, #players do
            local player = players[i]
            local frame = Gui.get_top_element(player, main_frame_name)

            if frame and frame.valid then
                local score_table = frame.score_table
                for score_name, textual_display in pairs(scores) do
                    local element = score_table[score_name]
                    if textual_display.progress then
                        element.label.caption = textual_display.caption
                        element.label.tooltip = textual_display.tooltip
                        element.bar.value = textual_display.progress
                        element.bar.tooltip = textual_display.tooltip
                    else
                        element.caption = textual_display.caption
                    end
                end
            end
        end

        memory.redraw_score_scheduled = false
    end
)

local function schedule_redraw_score()
    if memory.redraw_score_scheduled then
        return
    end

    -- throttle redraws
    set_timeout_in_ticks(30, do_redraw_score)
    memory.redraw_score_scheduled = true
end

local function get_score_sprite()
    if script.active_mods['Krastorio2'] then
        return 'achievement/kr-matter-production-3'
    end
    if script.active_mods['space-exploration'] then
        return 'achievement/se-there-is-no-spoon'
    end
    return 'achievement/there-is-no-spoon'
end

local function player_created(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    Gui.add_top_element(player,
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = get_score_sprite(),
            tooltip = {'score.tooltip'},
            auto_toggle = true,
        }
    )
end

local function score_label_style(label, color)
    local style = label.style
    style.font = 'default-bold'
    style.font_color = color
end

local function score_show(top)
    local scores = get_global_score_labels()
    local frame = top.add {
        type = 'frame',
        name = main_frame_name,
        style = 'subheader_frame',
        index = top[main_button_name].get_index_in_parent() + 1
    }
    frame.location = { x = 1, y = 38 }
	Gui.set_style(frame, { natural_height = Styles.default_top_element.style.minimal_height, height = Styles.default_top_element.style.minimal_height, padding = 6 })

    local score_table = frame.add {type = 'table', name = 'score_table', column_count = table_size(scores)}
    local style = score_table.style
    style.vertical_spacing = 4
    style.horizontal_spacing = 16

    for score_name, textual_display in pairs(scores) do
        local parent = score_table
        local label_name = score_name
        if textual_display.progress then
            -- a score with a goal shows its count next to a progress bar toward it
            parent = score_table.add({type = 'flow', name = score_name, direction = 'horizontal'})
            Gui.set_style(parent, {vertical_align = 'center', horizontal_spacing = 8})
            label_name = 'label'
        end

        local label =
            parent.add(
            {
                type = 'label',
                name = label_name,
                caption = textual_display.caption,
                tooltip = textual_display.tooltip
            }
        )
        score_label_style(label, Color.white)

        if textual_display.progress then
            local bar = parent.add({type = 'progressbar', name = 'bar', value = textual_display.progress, tooltip = textual_display.tooltip})
            Gui.set_style(bar, {width = 120})
        end
    end
end

local function global_score_changed(event)
    local found = false
    for index = 1, #scores_to_show do
        if scores_to_show[index] then
            found = true
        end
    end

    if not found then
        return
    end

    schedule_redraw_score()

    if event.score_name ~= 'satellites-launched' then
        return
    end

    local count = ScoreTracker.get_for_global('satellites-launched')

    if (count < 10) or ((count < 50) and ((count % 5) == 0)) or ((count < 1000) and ((count % 25) == 0)) or ((count < 10000) and ((count % 100) == 0)) or ((count < 100000) and ((count % 1000) == 0))or ((count < 1000000) and ((count % 10000) == 0)) or ((count % 100000) == 0) then
        local message = 'A satellite has been launched! Total count: ' .. count

        game.print(message)
        Server.to_discord_bold(message)
    end
end

Gui.on_click(
    main_button_name,
    function(event)
        local player = event.player
        local top = Gui.get_top_flow(player)
        local frame = top[main_frame_name]

        if not frame then
            score_show(top)
        else
            frame.destroy()
        end
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_created, player_created)
Event.add(ScoreTracker.events.on_global_score_changed, global_score_changed)
