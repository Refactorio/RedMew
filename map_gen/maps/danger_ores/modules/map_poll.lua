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

local mod_packs = {
    normal    = 'danger_ore_normal',
    bob_angel = 'danger_ore_bob_angel',
    bob       = 'danger_ore_bob',
    bz        = 'danger_ore_bz',
    ei        = 'danger_ore_ei',
    ir3       = 'danger_ore_ir3',
    k2        = 'danger_ore_krastorio2',
    omni      = 'danger_ore_omnimatter',
    py_short  = 'danger_ore_py_short',
    scrap     = 'danger_ore_scrap',
}

local maps = {
    { name = 'danger-ore-3way', display_name = '3-Way (T-shape)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-bob', display_name = 'Bob\'s mods (default)', mod_pack = mod_packs.bob },
    --{ name = 'danger-ore-bob-angel', display_name = 'Bob\'s Angel\'s mods (default)', mod_pack = mod_packs.bob_angel },
    --{ name = 'danger-ore-bz', display_name = 'Very BZ (default)', mod_pack = mod_packs.bz },
    { name = 'danger-ore-chessboard', display_name = 'Chessboard (random squares)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-circles', display_name = 'Circles (ore rings)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-exotic-industries', display_name = 'Exotic Industries (default)', mod_pack = mod_packs.ei },
    { name = 'danger-ore-exotic-industries-spiral', display_name = 'Exotic Industries Spiral (without void)', mod_pack = mod_packs.ei },
    --{ name = 'danger-ore-expanse', display_name = 'Expanse (feed Hungry Chests to expand)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-for-the-swarm', display_name = 'Honeycomb-gradient (smooth ore ratios)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-gradient', display_name = 'Gradient (smooth ore ratios)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-grid-factory', display_name = 'Grid Factory (squares)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-hub-spiral', display_name = 'Hub-spiral (with void)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-industrial-revolution-3', display_name = 'Industrial Revolution 3 (default)', mod_pack = mod_packs.ir3 },
    --{ name = 'danger-ore-industrial-revolution-3-grid-factory', display_name = 'Industrial Revolution 3 Grid Factory (squares)', mod_pack = mod_packs.ir3 },
    --{ name = 'danger-ore-krastorio2', display_name = 'Krastorio2 (landfill)', mod_pack = mod_packs.k2 },
    { name = 'danger-ore-landfill', display_name = 'Landfill (all tiles)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-lazy-one', display_name = 'Lazy One (no handcraft)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-normal-science', display_name = 'Normal science (+ biters)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-omnimatter', display_name = 'Omnimatter (1 ore)', mod_pack = mod_packs.omni },
    --{ name = 'danger-ore-omnimatter-cages', display_name = 'Omnimatter Cages (1 ore + frames)', mod_pack = mod_packs.omni },
    { name = 'danger-ore-one-direction', display_name = 'One Direction (right ribbon world)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-one-direction-wide', display_name = 'One Direction Wide (wide right ribbon world)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-patches', display_name = 'Patches (ore islands in coal)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-poor-mans-coal-fields', display_name = 'Poor Man\'s Coal Fields (Alex Gaming\'s map)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-pyfe', display_name = 'Pyanodon Short (PyFe)', mod_pack = mod_packs.py_short },
    --{ name = 'danger-ore-scrap', display_name = 'Scrapworld (no ores, all scraps)', mod_pack = mod_packs.scrap },
    { name = 'danger-ore-spiral', display_name = 'Spiral (without void)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-split', display_name = 'Split (4x sectors)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-square', display_name = 'Square (corner start)', mod_pack = mod_packs.normal },
    { name = 'danger-ore-terraforming', display_name = 'Terraforming (default)', mod_pack = mod_packs.normal },
    --{ name = 'danger-ore-xmas-tree', display_name = 'Christmas Tree (triangle)', mod_pack = mod_packs.normal },
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
