local Event = require 'utils.event'
local Game = require 'utils.game'
local PlayerStats = require 'features.player_stats'
local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'
local Global = require 'utils.global'
local Server = require('features.server')

local data = {rockets_launched = 0}

Global.register(
    data,
    function(tbl)
        data = tbl
    end
)

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

local function create_score_gui(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player then
        return
    end

    local top = player.gui.top

    if not top[main_frame_name] then
        local button = top.add({type = 'sprite-button', name = main_button_name, sprite = 'item/rocket-silo'})
        local style = button.style
        style.minimal_height = 38
        style.minimal_width = 38
        style.top_padding = 2
        style.left_padding = 4
        style.right_padding = 4
        style.bottom_padding = 2
    end
end

local function refresh_score()
    local players = game.connected_players

    local rockets_launched = 'Rockets launched: ' .. data.rockets_launched
    local biters_liberated = 'Biters liberated: ' .. PlayerStats.get_total_biter_kills()
    local buildings_by_hand = 'Buildings by hand: ' .. PlayerStats.get_total_player_built_entities()
    local buildings_by_robot = 'Buildings by robots: ' .. PlayerStats.get_total_robot_built_entities()
    local trees_chopped = 'Trees chopped: ' .. PlayerStats.get_total_player_trees_mined()
    local rocks_smashed = 'Rocks smashed: ' .. PlayerStats.get_total_player_rocks_mined()
    local kills_by_train = 'Kills by train: ' .. PlayerStats.get_total_train_kills()

    for i = 1, #players do
        local player = players[i]
        local frame = player.gui.top[main_frame_name]

        if frame and frame.valid then
            local score_table = frame.score_table
            score_table.label_rockets_launched.caption = rockets_launched
            score_table.label_biters_killed.caption = biters_liberated
            score_table.label_player_built_entities.caption = buildings_by_hand
            score_table.label_robot_built_entities.caption = buildings_by_robot
            score_table.label_player_mined_trees.caption = trees_chopped
            score_table.label_player_mined_stones.caption = rocks_smashed
            score_table.label_kills_by_train.caption = kills_by_train
        end
    end
end

local function score_label_style(label, color)
    local style = label.style
    style.font = 'default-bold'
    style.font_color = color
    style.top_padding = 2
    style.left_padding = 4
    style.right_padding = 4
end

local function score_show(top)
    local frame = top.add {type = 'frame', name = main_frame_name}
    local score_table = frame.add {type = 'table', name = 'score_table', column_count = 8}

    local label =
        score_table.add {
        type = 'label',
        name = 'label_rockets_launched',
        caption = 'Rockets launched: ' .. data.rockets_launched
    }
    score_label_style(label, Color.orange)
    score_table.add {type = 'label', caption = '  '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_biters_killed',
        caption = 'Biters liberated: ' .. PlayerStats.get_total_biter_kills()
    }
    score_label_style(label, Color.red)
    score_table.add {type = 'label', caption = '   '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_built_entities',
        caption = 'Buildings by hand: ' .. PlayerStats.get_total_player_built_entities()
    }
    score_label_style(label, Color.white)
    score_table.add {type = 'label', caption = '   '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_robot_built_entities',
        caption = 'Buildings by robots: ' .. PlayerStats.get_total_robot_built_entities()
    }
    score_label_style(label, Color.white)
    score_table.add {type = 'label', caption = '   '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_mined_trees',
        caption = 'Trees chopped: ' .. PlayerStats.get_total_player_trees_mined()
    }
    score_label_style(label, Color.lime)
    score_table.add {type = 'label', caption = '   '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_mined_stones',
        caption = 'Rocks smashed: ' .. PlayerStats.get_total_player_rocks_mined()
    }
    score_label_style(label, Color.lime)
    score_table.add {type = 'label', caption = '   '}

    label =
        score_table.add {
        type = 'label',
        name = 'label_kills_by_train',
        caption = 'Kills by train: ' .. PlayerStats.get_total_train_kills()
    }
    score_label_style(label, Color.yellow)

    refresh_score()
end

local function rocket_launched()
    local count = data.rockets_launched + 1
    data.rockets_launched = count

    local message = 'A rocket has been launched! Total count: ' .. count

    game.print(message)
    Server.to_discord_bold(message)

    refresh_score()
end

Gui.on_click(
    main_button_name,
    function(event)
        local player = event.player

        local top = player.gui.top
        local frame = top[main_frame_name]

        if not frame then
            score_show(top)
        else
            frame.destroy()
        end
    end
)

Gui.allow_player_to_toggle_top_element_visibility('score')

Event.add(defines.events.on_player_joined_game, create_score_gui)
Event.add(defines.events.on_rocket_launched, rocket_launched)
Event.on_nth_tick(300, refresh_score)
