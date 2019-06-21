local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Schedule = require 'utils.task'
local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'
local Server = require 'features.server'
local ScoreTracker = require 'utils.score_tracker'
local format_number = require 'util'.format_number
local pairs = pairs
local concat = table.concat
local scores_to_show = global.config.score.global_to_show
local set_timeout_in_ticks = Schedule.set_timeout_in_ticks
local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

local memory = {
    redraw_score_scheduled = false,
    player_last_position = {},
    player_death_causes = {}
}

Global.register(memory, function(tbl) memory = tbl end)

---Creates a map of score name => {captain, tooltip}
local function get_global_score_labels()
    local scores = ScoreTracker.get_global_scores_with_metadata(scores_to_show)
    local score_labels = {}

    for index = 1, #scores do
        local score_data = scores[index]
        score_labels[score_data.name] = {
            caption = concat({score_data.icon, format_number(score_data.value, true)}, ' '),
            tooltip = score_data.locale_string
        }
    end

    return score_labels
end

local do_redraw_score = Token.register(function()
    local players = game.connected_players
    local scores = get_global_score_labels()

    for i = 1, #players do
        local player = players[i]
        local frame = player.gui.top[main_frame_name]

        if frame and frame.valid then
            local score_table = frame.score_table
            for score_name, textual_display in pairs(scores) do
                score_table[score_name].caption = textual_display.caption
            end
        end
    end

    memory.redraw_score_scheduled = false
end)

local function schedule_redraw_score()
    if memory.redraw_score_scheduled then
        return
    end

    -- throttle redraws
    set_timeout_in_ticks(30, do_redraw_score)
    memory.redraw_score_scheduled = true
end

local function player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local top = player.gui.top

    if not top[main_button_name] then
        top.add({
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'achievement/there-is-no-spoon',
            tooltip = {'score.tooltip'}
        })
    end
end

local function score_label_style(label, color)
    local style = label.style
    style.font = 'default-bold'
    style.font_color = color
end

local function score_show(top)
    local scores = get_global_score_labels()
    local frame = top.add {type = 'frame', name = main_frame_name}
    local score_table = frame.add {type = 'table', name = 'score_table', column_count = 8}
    local style = score_table.style
    style.vertical_spacing = 4
    style.horizontal_spacing = 16

    for score_name, textual_display in pairs(scores) do
        local label = score_table.add({
            type = 'label',
            name = score_name,
            caption = textual_display.caption,
            tooltip = textual_display.tooltip
        })
        score_label_style(label, Color.white)
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

    if (count < 10) or ((count < 50) and ((count % 5) == 0)) or ((count % 25) == 0) then
        local message = 'A satellite has been launched! Total count: ' .. count

        game.print(message)
        Server.to_discord_bold(message)
    end
end

Gui.on_click(
    main_button_name,
    function(event)
        local player = event.player
        local top = player.gui.top
        local frame = top[main_frame_name]
        local main_button = top[main_button_name]

        if not frame then
            score_show(top)

            main_button.style = 'selected_slot_button'
            local style = main_button.style
            style.width = 38
            style.height = 38
        else
            frame.destroy()
            main_button.style = 'icon_button'
        end
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, player_joined_game)
Event.add(ScoreTracker.events.on_global_score_changed, global_score_changed)
