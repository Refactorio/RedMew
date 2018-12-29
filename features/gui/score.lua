local Event = require 'utils.event'
local Game = require 'utils.game'
local PlayerStats = require 'features.player_stats'
local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'

if not global.score_rockets_launched then
    global.score_rockets_launched = 0
end

local function create_score_gui(event)
    local player = Game.get_player_by_index(event.player_index)

    if player.gui.top.score == nil then
        local button = player.gui.top.add({type = 'sprite-button', name = 'score', sprite = 'item/rocket-silo'})
        button.style.minimal_height = 38
        button.style.minimal_width = 38
        button.style.top_padding = 2
        button.style.left_padding = 4
        button.style.right_padding = 4
        button.style.bottom_padding = 2
    end
end

local function refresh_score()
    local x = 1
    while (Game.get_player_by_index(x) ~= nil) do
        local player = Game.get_player_by_index(x)
        local frame = player.gui.top['score_panel']

        if (frame) then
            frame.score_table.label_rockets_launched.caption = 'Rockets launched: ' .. global.score_rockets_launched
            frame.score_table.label_biters_killed.caption = 'Biters liberated: ' .. PlayerStats.get_total_biter_kills()
            frame.score_table.label_player_built_entities.caption = 'Buildings by hand: ' .. PlayerStats.get_total_player_built_entities()
            frame.score_table.label_robot_built_entities.caption = 'Buildings by robots: ' .. PlayerStats.get_total_robot_built_entities()
            frame.score_table.label_player_mined_trees.caption = 'Trees chopped: ' .. PlayerStats.get_total_player_trees_mined()
            frame.score_table.label_player_mined_stones.caption = 'Rocks smashes: ' .. PlayerStats.get_total_player_rocks_mined()
            frame.score_table.label_kills_by_train.caption = 'Kills by train: ' .. PlayerStats.get_total_train_kills()
        end
        x = x + 1
    end
end

local function score_show(player)
    local frame = player.gui.top.add {type = 'frame', name = 'score_panel'}
    local score_table = frame.add {type = 'table', column_count = 8, name = 'score_table'}

    local label = score_table.add {type = 'label', caption = ' ', name = 'label_rockets_launched'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.orange
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '  '}

    label = score_table.add {type = 'label', caption = '', name = 'label_biters_killed'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.red
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '   '}

    label = score_table.add {type = 'label', caption = '', name = 'label_player_built_entities'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.white
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '   '}

    label = score_table.add {type = 'label', caption = '', name = 'label_robot_built_entities'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.white
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '   '}

    label = score_table.add {type = 'label', caption = '', name = 'label_player_mined_trees'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.lime
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '   '}

    label = score_table.add {type = 'label', caption = '', name = 'label_player_mined_stones'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.lime
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    score_table.add {type = 'label', caption = '   '}

    label = score_table.add {type = 'label', caption = '', name = 'label_kills_by_train'}
    label.style.font = 'default-bold'
    label.style.font_color = Color.yellow
    label.style.top_padding = 2
    label.style.left_padding = 4
    label.style.right_padding = 4

    refresh_score()
end

local function on_gui_click(event)
    if not (event and event.element and event.element.valid) then
        return
    end

    local player = Game.get_player_by_index(event.element.player_index)
    local name = event.element.name
    local frame = player.gui.top['score_panel']

    if (name == 'score') and (frame == nil) then
        score_show(player)
    else
        if (name == 'score') then
            frame.destroy()
        end
    end
end

local function rocket_launched()
    global.score_rockets_launched = global.score_rockets_launched + 1
    game.print('A rocket has been launched!')
    refresh_score()
end

Gui.allow_player_to_toggle_top_element_visibility('score')

Event.add(defines.events.on_entity_died, refresh_score)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, create_score_gui)
Event.add(defines.events.on_rocket_launched, rocket_launched)
Event.on_nth_tick(300, refresh_score)
