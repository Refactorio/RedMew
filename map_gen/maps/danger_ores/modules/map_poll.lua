local Poll = require 'features.gui.poll'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local MapPollUtils = require 'map_gen.maps.danger_ores.modules.map_poll_utils'
local Restart = require 'features.restart_command'
local Server = require 'features.server'
local Ranks = require 'resources.ranks'

local data_set_name = 'map_poll_tags'

local data = {
    created = false,
    id = nil,
    map_indices = nil -- array of indices into maps, positionally aligned with the poll answers.
}

Global.register(data, function(tbl)
    data = tbl
end)

local mod_packs = {
    danger_ore_normal     = 'danger_ore_normal',
    danger_ore_angel      = 'danger_ore_angel',
    danger_ore_bob        = 'danger_ore_bob',
    danger_ore_bob_angel  = 'danger_ore_bob_angel',
    danger_ore_bz         = 'danger_ore_bz',
    danger_ore_ei         = 'danger_ore_ei',
    danger_ore_ir3        = 'danger_ore_ir3',
    danger_ore_krastorio2 = 'danger_ore_krastorio2',
    danger_ore_omnimatter = 'danger_ore_omnimatter',
    danger_ore_py_short   = 'danger_ore_py_short',
    danger_ore_scrap      = 'danger_ore_scrap',
    danger_ore_space_age  = 'danger_ore_space_age',
    danger_ore_collapse   = 'danger_ore_collapse',
    danger_ore_gridlocked = 'danger_ore_gridlocked',
}

-- Tags are used by the map_poll_tags scenario data to decide which maps a server is offered.
-- Servers are configured with an array of tags on the web server, a map is offered if any of
-- its tags matches any of the server's tags, and maps without tags are always included.
-- A server with no tags configured (no entry for its id) is offered all maps, while a
-- server whose tags match no maps is offered none (no map poll is created).
local tags = {
    regular = 'regular',
    overhaul = 'overhaul'
}

local maps = {
    { name = 'danger-ore-3way', display_name = '3-Way (T-shape)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-angel', display_name = 'Angel\'s mods (default)', mod_pack = mod_packs.danger_ore_angel, tags = {tags.overhaul} },
    { name = 'danger-ore-bob', display_name = 'Bob\'s mods (default)', mod_pack = mod_packs.danger_ore_bob, tags = {tags.overhaul} },
    { name = 'danger-ore-bob-angel', display_name = 'Bob\'s + Angel\'s mods (default)', mod_pack = mod_packs.danger_ore_bob_angel, tags = {tags.overhaul} },
    --{ name = 'danger-ore-bz', display_name = 'Very BZ (default)', mod_pack = mod_packs.danger_ore_bz, tags = {tags.overhaul} },
    { name = 'danger-ore-chessboard', display_name = 'Chessboard (random squares)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-circles', display_name = 'Circles (ore rings)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-city-blocks', display_name = 'City Blocks (train-only blocks)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-coal-maze', display_name = 'Coal Maze (maze)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-collapse', display_name = 'Collapse (increasing hardness)', mod_pack = mod_packs.danger_ore_collapse, tags = {tags.overhaul} },
    --{ name = 'danger-ore-exotic-industries', display_name = 'Exotic Industries (default)', mod_pack = mod_packs.danger_ore_ei, tags = {tags.overhaul} },
    --{ name = 'danger-ore-exotic-industries-spiral', display_name = 'Exotic Industries Spiral (without void)', mod_pack = mod_packs.danger_ore_ei, tags = {tags.overhaul} },
    { name = 'danger-ore-expanse', display_name = 'Expanse (feed Hungry Chests to expand)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-for-the-swarm', display_name = 'Honeycomb-gradient (smooth ore ratios)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-gradient', display_name = 'Gradient (smooth ore ratios)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-grid-factory', display_name = 'Grid Factory (squares)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-gridlocked', display_name = 'Gridlocked (buy chunks)', mod_pack = mod_packs.danger_ore_gridlocked, tags = {tags.overhaul} },
    { name = 'danger-ore-hub-spiral', display_name = 'Hub-spiral (with void)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    --{ name = 'danger-ore-industrial-revolution-3', display_name = 'Industrial Revolution 3 (default)', mod_pack = mod_packs.danger_ore_ir3, tags = {tags.overhaul} },
    --{ name = 'danger-ore-industrial-revolution-3-grid-factory', display_name = 'Industrial Revolution 3 Grid Factory (squares)', mod_pack = mod_packs.danger_ore_ir3, tags = {tags.overhaul} },
    { name = 'danger-ore-joker', display_name = 'Joker (4 suits start)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-krastorio2', display_name = 'Krastorio2 (landfill)', mod_pack = mod_packs.danger_ore_krastorio2, tags = {tags.overhaul} },
    { name = 'danger-ore-landfill', display_name = 'Landfill (all tiles)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-lazy-one', display_name = 'Lazy One (no handcraft)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-normal-science', display_name = 'Normal science (+ biters)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-omnimatter', display_name = 'Omnimatter (1 ore)', mod_pack = mod_packs.danger_ore_omnimatter, tags = {tags.overhaul} },
    { name = 'danger-ore-omnimatter-cages', display_name = 'Omnimatter Cages (1 ore + frames)', mod_pack = mod_packs.danger_ore_omnimatter, tags = {tags.overhaul} },
    { name = 'danger-ore-omnimatter-maze', display_name = 'Omnimatter Maze (1 ore + maze)', mod_pack = mod_packs.danger_ore_omnimatter, tags = {tags.overhaul} },
    { name = 'danger-ore-one-direction', display_name = 'One Direction (right ribbon world)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-one-direction-wide', display_name = 'One Direction Wide (wide right ribbon world)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-patches', display_name = 'Patches (ore islands in coal)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-permanence', display_name = 'Permanence (rebuilding penalty)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    --{ name = 'danger-ore-poor-mans-coal-fields', display_name = 'Poor Man\'s Coal Fields (Alex Gaming\'s map)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-pyfe', display_name = 'Pyanodon Short (PyFe)', mod_pack = mod_packs.danger_ore_py_short, tags = {tags.overhaul} },
    { name = 'danger-ore-safety', display_name = 'Safety Ores (inverse Danger Ores)', mod_pack = mod_packs.danger_ore_scrap, tags = {tags.overhaul} },
    { name = 'danger-ore-scrap', display_name = 'Scrapworld (no ores, all scraps)', mod_pack = mod_packs.danger_ore_scrap, tags = {tags.overhaul} },
    { name = 'danger-ore-scrap-maze', display_name = 'Scrapworld Maze (all scraps + maze)', mod_pack = mod_packs.danger_ore_scrap, tags = {tags.overhaul} },
    { name = 'danger-ore-space-age', display_name = 'Space Age (everything on Nauvis)', mod_pack = mod_packs.danger_ore_space_age, tags = {tags.overhaul} },
    { name = 'danger-ore-spiral', display_name = 'Spiral (without void)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-split', display_name = 'Split (4x sectors)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-square', display_name = 'Square (corner start)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-terraforming', display_name = 'Terraforming (default)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-tetrominoes', display_name = 'Tetrominoes (interlocking pieces)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-voronoi', display_name = 'Voronoi (organic cells)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    { name = 'danger-ore-x-cross', display_name = 'X Cross (45 degrees)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
    --{ name = 'danger-ore-xmas-tree', display_name = 'Christmas Tree (triangle)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} },
}

local function create_map_poll(server_tags)
    -- The poll counts as handled even if no poll ends up being created, so we
    -- don't make repeated calls (on server restart) when a server wants an empty poll.
    data.created = true

    local map_indices = MapPollUtils.get_map_indices(maps, server_tags)

    if #map_indices == 0 then
        log('map_poll: no maps match the server tags, no map poll created')
        return
    end

    local answers = {}
    for i, map_index in pairs(map_indices) do
        answers[i] = maps[map_index].display_name
    end

    local success, id = Poll.poll({
        question = 'Next map? (Advisory only)',
        duration = 0,
        edit_rank = Ranks.admin,
        answers = answers
    })

    if success then
        data.id = id
        data.map_indices = map_indices
        Restart.set_use_map_poll_result_option(true)
        Restart.set_known_modpacks_option(mod_packs)
    else
        log('map_poll: failed to create the map poll: ' .. tostring(id))
    end
end

local map_poll_tags_callback_token = Token.register(function(response)
    if data.created then
        return
    end

    create_map_poll(response.value)
end)

--- Called when the server goes from the starting state to the running state.
local function on_server_started()
    if data.created then
        return
    end

    local server_id = Server.get_server_id()
    if server_id == '' then
        -- Without a server id there is nothing to fetch, treat the server as having no tags.
        create_map_poll(nil)
        return
    end

    Server.try_get_data(data_set_name, server_id, map_poll_tags_callback_token)
end

Event.add(Server.events.on_server_started, on_server_started)

local Public = {}

--- Returns the maps table, exposed for tests.
function Public.get_maps()
    return maps
end

--- Returns the tags table, exposed for tests.
function Public.get_tags()
    return tags
end

--- Resets the module state so a new map poll can be created, exposed for tests.
-- Any existing map poll is removed.
function Public.reset()
    if data.id ~= nil then
        Poll.remove_poll(data.id)
    end

    data.created = false
    data.id = nil
    data.map_indices = nil
end

--- The on_server_started handler, exposed for tests.
Public.on_server_started = on_server_started

function Public.get_map_poll_id()
    return data.id
end

function Public.get_next_map()
    local poll_data = Poll.get_poll_data(data.id)
    if poll_data == nil then
        return nil
    end

    return MapPollUtils.get_next_map(maps, data.map_indices, poll_data.answers)
end

return Public
