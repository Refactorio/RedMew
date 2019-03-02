local Event = require 'utils.event'
local Game = require 'utils.game'
local PlayerStats = require 'features.player_stats'
local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'
local Server = require('features.server')

local concat = table.concat

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

local descriptions = {
    {disc = 'Satellites launched', icon = '[img=item.satellite]'},
    {disc = 'Biters liberated', icon = '[img=entity.medium-biter]'},
    {disc = 'Buildings by hand', icon = '[img=utility.hand]'},
    {disc = 'Buildings by robots', icon = '[img=item.construction-robot]'},
    {disc = 'Trees chopped', icon = '[img=entity.tree-02]'},
    {disc = 'Rocks smashed', icon = '[img=entity.rock-huge]'},
    {disc = 'Kills by train', icon = '[img=item.locomotive]'},
    {disc = 'Coins spent', icon = '[img=item.coin]'},
}

local function create_score_gui(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player then
        return
    end

    local top = player.gui.top

    if not top[main_button_name] then
        top.add({type = 'sprite-button', name = main_button_name, sprite = 'achievement/there-is-no-spoon'})
    end
end

local function refresh_score()
    local players = game.connected_players
    local count = game.forces.player.get_item_launched('satellite')

    local satellites_launched = concat {descriptions[1].icon .. ' ', count, ' '}
    local biters_liberated = concat {descriptions[2].icon .. ' ', PlayerStats.get_total_biter_kills(), ' '}
    local buildings_by_hand = concat {descriptions[3].icon .. ' ', PlayerStats.get_total_player_built_entities(), ' '}
    local buildings_by_robot = concat {descriptions[4].icon .. ' ', PlayerStats.get_total_robot_built_entities(), ' '}
    local trees_chopped = concat {descriptions[5].icon .. ' ', PlayerStats.get_total_player_trees_mined(), ' '}
    local rocks_smashed = concat {descriptions[6].icon .. ' ', PlayerStats.get_total_player_rocks_mined(), ' '}
    local kills_by_train = concat {descriptions[7].icon .. ' ', PlayerStats.get_total_train_kills(), ' '}
    local coins_spent = concat {descriptions[8].icon .. ' ', PlayerStats.get_total_coins_spent(), ' '}

    for i = 1, #players do
        local player = players[i]
        local frame = player.gui.top[main_frame_name]

        if frame and frame.valid then
            local score_table = frame.score_table
            score_table.label_satellites_launched.caption = satellites_launched
            score_table.label_biters_killed.caption = biters_liberated
            score_table.label_player_built_entities.caption = buildings_by_hand
            score_table.label_robot_built_entities.caption = buildings_by_robot
            score_table.label_player_mined_trees.caption = trees_chopped
            score_table.label_player_mined_stones.caption = rocks_smashed
            score_table.label_kills_by_train.caption = kills_by_train
            score_table.label_coins_spent.caption = coins_spent
        end
    end
end

local function score_label_style(label, color)
    local style = label.style
    style.font = 'default-bold'
    style.font_color = color
end

local function score_show(top)
    local count = game.forces.player.get_item_launched('satellite')

    local frame = top.add {type = 'frame', name = main_frame_name}
    local score_table = frame.add {type = 'table', name = 'score_table', column_count = 8}
    local style = score_table.style
    style.vertical_spacing = 4
    style.horizontal_spacing = 16

    local label =
        score_table.add {
        type = 'label',
        name = 'label_satellites_launched',
        caption = concat {descriptions[1].icon .. ' ', count, ' '},
        tooltip = descriptions[1].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_biters_killed',
        caption = concat {descriptions[2].icon .. ' ', PlayerStats.get_total_biter_kills(), ' '},
        tooltip = descriptions[2].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_built_entities',
        caption = concat {descriptions[3].icon .. ' ', PlayerStats.get_total_player_built_entities(), ' '},
        tooltip = descriptions[3].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_robot_built_entities',
        caption = concat {descriptions[4].icon .. ' ', PlayerStats.get_total_robot_built_entities(), ' '},
        tooltip = descriptions[4].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_mined_trees',
        caption = concat {descriptions[5].icon .. ' ', PlayerStats.get_total_player_trees_mined(), ' '},
        tooltip = descriptions[5].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_player_mined_stones',
        caption = concat {descriptions[6].icon .. ' ', PlayerStats.get_total_player_rocks_mined(), ' '},
        tooltip = descriptions[6].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_kills_by_train',
        caption = concat {descriptions[7].icon .. ' ', PlayerStats.get_total_train_kills(), ' '},
        tooltip = descriptions[7].disc
    }
    score_label_style(label, Color.white)

    label =
        score_table.add {
        type = 'label',
        name = 'label_coins_spent',
        caption = concat {descriptions[8].icon .. ' ', PlayerStats.get_total_coins_spent(), ' '},
        tooltip = descriptions[8].disc
    }
    score_label_style(label, Color.white)
end

local function rocket_launched(event)
    local entity = event.rocket

    if not entity or not entity.valid or not entity.force == 'player' then
        return
    end

    local inventory = entity.get_inventory(defines.inventory.rocket)
    if not inventory or not inventory.valid then
        return
    end

    local count = inventory.get_item_count('satellite')
    if count == 0 then
        return
    end

    count = game.forces.player.get_item_launched('satellite')

    if (count < 10) or ((count < 50) and ((count % 5) == 0)) or ((count % 25) == 0) then
        local message = 'A satellite has been launched! Total count: ' .. count

        game.print(message)
        Server.to_discord_bold(message)
    end

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

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, create_score_gui)
Event.add(defines.events.on_rocket_launched, rocket_launched)
Event.on_nth_tick(300, refresh_score)
