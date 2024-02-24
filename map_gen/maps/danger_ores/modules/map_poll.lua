local Poll = require 'features.gui.poll'
local Global = require 'utils.global'
local Event = require 'utils.event'
local PollUtils = require 'utils.poll_utils'
local Restart = require 'features.restart_command'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local data = {
    created = false,
    id = nil
}

Global.register(data, function(tbl)
    data = tbl
end)

local normal_mod_pack = 'normal_mod_pack'
local bobs_mod_pack = 'bobs_mod_pack'
local krastorio_mod_pack = 'krastorio_mod_pack'
local omnimatter_mod_pack = 'omnimatter_mod_pack'
local bz_mod_pack = 'bz_mod_pack'
local ei_mod_pack = 'ei_mod_pack'
-- local py_short_mod_pack = 'py_short_mod_pack'
local ir3_mod_pack = 'ir3_mod_pack'
local scrap_mod_pack = 'scrap_mod_pack'

local mod_packs = {
    normal_mod_pack = 'danger_ore29',
    bobs_mod_pack = 'danger_ore_bobs3',
    krastorio_mod_pack = 'danger_ore_krastorio3',
    omnimatter_mod_pack = 'danger_ore_omnimatter',
    bz_mod_pack = 'danger_ore_bz',
    ei_mod_pack = 'danger_ore_ei',
    py_short_mod_pack = 'danger_ore_py_short',
    ir3_mod_pack = 'danger_ore_ir3',
    scrap_mod_pack = 'danger_ore_scrap',
}

local maps = {
    {
        name = 'danger-ore-deadlock-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'terraforming (default)'
    },
    {
        name = 'danger-ore-one-direction-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'one direction (line)'
    },
    {
        name = 'danger-ore-one-direction-wide-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'one direction wide (wider line)'
    },
    {
        name = 'danger-ore-3way-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = '3-way (T shape)'
    },
    {
        name = 'danger-ore-square-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'square (corner start)'
    },
    {
        name = 'danger-ore-chessboard-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'chessboard (random squares)'
    },
    {
        name = 'danger-ore-chessboard-uniform-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'chessboard uniform (fixed squares)'
    },
    {
        name = 'danger-ore-expensive-grid-factory-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'Concrete-chessboard uniform (fixed squares)'
    },
    {
        name = 'danger-ore-circles-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'circles (ore rings)'
    },
    {
        name = 'danger-ore-gradient-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'gradient (smooth ore ratios)'
    },
    {
        name = 'danger-ore-for-the-swarm-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'Honeycomb-gradient (smooth ore ratios)'
    },
    {
        name = 'danger-ore-split-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'split (4x sectors)'
    },
    {
        name = 'danger-ore-hub-spiral-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'hub-spiral (with void)'
    },
    {
        name = 'danger-ore-spiral-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'spiral (without void)'
    },
    {
        name = 'danger-ore-landfill-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'landfill (all tiles)'
    },
    {
        name = 'danger-ore-lazy-one-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'NoHandcraft-landfill (all tiles)'
    },
    {
        name = 'danger-ore-patches-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'patches (ore islands in coal)'
    },
    --[[ {
        name = 'danger_ore_poor_mans_coal_fields',
        mod_pack = normal_mod_pack,
        display_name = 'poor man\'s coal fields (Alex Gaming\'s map)'
    }, ]]
    {
        name = 'danger-ore-xmas-tree-beltboxes-ore-only',
        mod_pack = normal_mod_pack,
        display_name = 'xmas tree (triangle)'
    },
    {
        name = 'danger-bobs-ores',
        mod_pack = bobs_mod_pack,
        display_name = 'bob\'s mod (default map)'
    },
    {
        name = 'danger-ore-krastorio2',
        mod_pack = krastorio_mod_pack,
        display_name = 'Krastorio2 (landfill)'
    },
    {
        name = 'danger-ore-omnimatter',
        mod_pack = omnimatter_mod_pack,
        display_name = 'Omnimatter (default map)'
    },
    {
        name = 'danger-ore-omnimatter-cages',
        mod_pack = omnimatter_mod_pack,
        display_name = 'Omnimatter cages (landfill + frames)'
    },
    {
        name = 'danger-ore-bz',
        mod_pack = bz_mod_pack,
        display_name = 'Very BZ (default map)'
    },
    {
        name = 'danger-ore-exotic-industries',
        mod_pack = ei_mod_pack,
        display_name = 'Exotic Industries (default map)'
    },
    {
        name = 'danger-ore-exotic-industries-spiral',
        mod_pack = ei_mod_pack,
        display_name = 'Exotic Industries spiral (without void)'
    },
    --[[ N/A until rework on data stages is finished
    {
        name = 'danger-ore-pyfe',
        mod_pack = py_short_mod_pack,
        display_name = 'Pyanodon Short (landfill)'
    },
    ]]
    {
        name = 'danger-ore-industrial-revolution-3',
        mod_pack = ir3_mod_pack,
        display_name = 'Industrial Revolution 3 (default map)'
    },
    {
        name = 'danger-ore-industrial-revolution-3-grid-factory',
        mod_pack = ir3_mod_pack,
        display_name = 'Industrial Revolution 3 chessboard (fixed squares)'
    },
    {
        name = 'danger-ore-scrap',
        mod_pack = scrap_mod_pack,
        display_name = 'Scrapworld (no ores, all scraps)'
    }
}

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

    Restart.set_use_map_poll_result_option(true)
    Restart.set_known_modpacks_option(mod_packs)
end)

local Public = {}

function Public.get_map_poll_id()
    return data.id
end

function Public.get_next_map()
    local poll_data = Poll.get_poll_data(data.id)
    if poll_data == nil then
        return nil
    end

    local answers = poll_data.answers
    local chosen_index = PollUtils.get_poll_winner(answers)
    if chosen_index == nil then
        return nil
    end

    return maps[chosen_index]
end

return Public
