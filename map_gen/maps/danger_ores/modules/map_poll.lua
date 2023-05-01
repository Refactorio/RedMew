local Poll = require 'features.gui.poll'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local data = {
    created = false,
    id = nil
}

Global.register(data, function(tbl)
    data = tbl
end)

local normal_mod_pack = 'danger_ore23'
local bobs_mod_pack = 'danger_ore_bobs2'

local maps = {{
    name = 'danger-ore-deadlock-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'terraforming (default)'
}, {
    name = 'danger-ore-one-direction-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'one direction (line)'
}, {
    name = 'danger-ore-3way-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = '3-way (T shape)'
}, {
    name = 'danger-ore-chessboard-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'chessboard (random squares)'
}, {
    name = 'danger-ore-chessboard-uniform-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'chessboard uniform (fixed squares)'
}, {
    name = 'danger-ore-circles-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'circles (ore rings)'
}, {
    name = 'danger-ore-gradient-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'gradient (smooth ore ratios)'
}, {
    name = 'danger-ore-split-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'split (4x sectors)'
}, {
    name = 'danger-ore-hub-spiral-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'hub-spiral (with void)'
}, {
    name = 'danger-ore-spiral-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'spiral (without void)'
}, {
    name = 'danger-ore-landfill-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'landfill (all tiles)'
}, {
    name = 'danger-ore-patches-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'patches (ore islands in coal)'
}, {
    name = 'danger-ore-xmas-tree-beltboxes-ore-only',
    mod_pack = normal_mod_pack,
    display_name = 'xmas tree (triangle)'
}, {
    name = 'danger-bobs-ores',
    mod_pack = bobs_mod_pack,
    display_name = 'bob\'s mod (default map)'
}}

Event.add(Server.events.on_server_started, function()
    if data.created then
        return
    end

    data.created = true

    local answers = {}
    for i, map_data in pairs(maps) do
        answers[i] = map_data.display_name
    end

    local success, id = Poll.poll({
        question = 'Next map? (Advisory only)',
        duration = 0,
        edit_rank = Ranks.admin,
        answers = answers
    })

    if success then
        data.id = id
    end
end)

local Public = {}

function Public.get_next_map()
    local poll_data = Poll.get_poll_data(data.id)
    if poll_data == nil then
        return nil
    end

    local answers = poll_data.answers
    local vote_counts = {}
    for i, answer_data in pairs(answers) do
        vote_counts[i] = answer_data.voted_count
    end

    local max_count = 0
    for i = 1, #vote_counts do
        local count = vote_counts[i] or 0
        if count > max_count then
            max_count = count
        end
    end

    if max_count == 0 then
        return nil
    end

    local max_indexes = {}
    for i = 1, #vote_counts do
        local count = vote_counts[i] or 0
        if count == max_count then
            max_indexes[#max_indexes + 1] = i
        end
    end

    local chosen_index = max_indexes[math.random(#max_indexes)]
    return maps[chosen_index]
end

return Public
