--[[
Some inspiration and bits of code taken from Nightfall by Yehn and dangOreus by Mylon.
Both under their respective MIT licenses.

This softmod uses the Starcraft concept of "creep" as a mechanic. In essence, players can only
build on certain creep tiles (in particular, the defined `creep_expansion_tile`s).
Pollution will naturally expand the creep. The creep will also naturally regress if pollution
is not sustained, affecting player structures in the process.

This module does not create an initial world state, so you will not have a guaranteed safe placed
to build, and any creep_expansion_tiles will be overtaken by creep_retraction_tiles as there is
no initial pollution cloud.

Todo: make the expansion less "blocky"/constrained to chunk borders
]]--

local Event = require 'utils.event'
local Game = require 'utils.game'
local random = math.random
local insert = table.insert

--how many chunks to process in a tick
local processchunk = 5

-- how often to recap the deaths from lack of creep (in ticks)
local death_recap_timer = 1200 --  20 secs

-- how often to check for players' positions
local player_pos_check_time = 300 --  5 secs

-- force that is restricted to the creep
local creep_force = "player"

-- the 3 chunk states are: 0% creep tiles and unpolluted, 100% creep and polluted, unknown or transitional creep state
local NOT_CREEP = 1
local FULL_CREEP = 2
local CREEP_RETRACTION = 3
local CREEP_EXPANDING = 4
local CREEP_UNKNOWN = 5 -- a special case for newly-generated chunks

-- the threshold above which creep expands
local pollution_threshold = 200

-- the number of tiles that change to/from creep at once
local random_factor = 0.1

-- which tiles to use for creep expansion
local creep_expansion_tiles = {
    'grass-1',
    'grass-2'
}

-- which tiles to use when creep retracts
local creep_retraction_tiles = {
    'dirt-1',
    'dirt-2',
    'dry-dirt',
    'sand-1',
    'sand-2',
    'sand-3'
}


-- which tiles players can build on/count as creep
local creep_tiles = {
    'grass-1',
    'grass-2',
    'concrete',
    'hazard-concrete-left',
    'hazard-concrete-right',
    'lab-dark-2',
    'lab-white',
    'refined-concrete',
    'refined-hazard-concrete-left',
    'refined-hazard-concrete-right',
    'stone-path',
    'tutorial-grid'
}

-- which tiles creep can expand to
local creep_expandable_tiles = {
    'lab-dark-1',
    'dirt-1',
    'dirt-2',
    'dirt-3',
    'dirt-4',
    'dirt-5',
    'dirt-6',
    'dirt-7',
    'dry-dirt',
    'grass-3',
    'grass-4',
    'red-desert-0',
    'red-desert-1',
    'red-desert-2',
    'red-desert-3',
    'sand-1',
    'sand-2',
    'sand-3'
}

-- list of all tiles currently in the game (0.16.51)
local all_tiles ={
    'concrete',
    'deepwater',
    'deepwater-green',
    'dirt-1',
    'dirt-2',
    'dirt-3',
    'dirt-4',
    'dirt-5',
    'dirt-6',
    'dirt-7',
    'dry-dirt',
    'grass-1',
    'grass-2',
    'grass-3',
    'grass-4',
    'hazard-concrete-left',
    'hazard-concrete-right',
    'lab-dark-1',
    'lab-dark-2',
    'lab-white',
    'out-of-map',
    'red-desert-0',
    'red-desert-1',
    'red-desert-2',
    'red-desert-3',
    'refined-concrete',
    'refined-hazard-concrete-left',
    'refined-hazard-concrete-right',
    'sand-1',
    'sand-2',
    'sand-3',
    'stone-path',
    'tutorial-grid',
    'water',
    'water-green'
}

local function get_tiles(tile_filter)
    tiles = find_tiles_filtered({area={{chunkcoord.x-16, chunkcoord.y-16},{chunkcoord.x+16, chunkcoord.y+16}},
                name = creep_expandable_tiles})
    return tiles
end

local function convert_tiles(tile_table, tiles)
    local set_tiles = game.surfaces[1].set_tiles
    local tile_set = {}
    local target_tile = tile_table[random(1,#tile_table)]
    -- convert the LuaTiles table into a new one we can edit
    for _, tiledata in ipairs(tiles) do
        if random() < random_factor then
            tile_set[#tile_set+1] = {name = target_tile, position = tiledata.position}
        end
    end
    -- change the tiles to the target_tile
    set_tiles(tile_set)
end

local function check_chunk_for_entities(chunk)
    local find_entities_filtered = game.surfaces[1].find_entities_filtered
    local entities_found
    entities_found = {}
    entities_found = find_entities_filtered{area = {{chunk.x-16, chunk.y-16},{chunk.x+16, chunk.y+16}},
        force = creep_force}
    for _, entity in ipairs(entities_found) do
        kill_invalid_builds(entity, false)
    end
end

local function change_creep_state(state, i)
    -- this function changes the state and tiles of chunks when they meet the creep expansion/retraction criteria
    local find_tiles_filtered = game.surfaces[1].find_tiles_filtered
    -- expand = 1, retract = 2
    local tile_table = {}
    local tiles_to_set = {}
    local debug_message
    local chunk_end_state
    local chunk_transition_state
    if state == 1 then
        tiles_to_find = creep_expandable_tiles
        tiles_to_set = creep_expansion_tiles
        debug_message = "Creep expanding"
        chunk_end_state = FULL_CREEP
        chunk_transition_state = CREEP_EXPANDING
    elseif state == 2 then
        tiles_to_find = creep_tiles
        tiles_to_set = creep_retraction_tiles
        debug_message = "Creep retracting"
        chunk_end_state = NOT_CREEP
        chunk_transition_state = CREEP_RETRACTION
    end

    global.chunklist[i].is_creep = chunk_transition_state
    local chunklist = global.chunklist
    local chunkcoord = chunklist[i]
    local tiles = {}
    -- check to see if there are any tiles to act on
    tiles = find_tiles_filtered({area={{chunkcoord.x-16, chunkcoord.y-16},{chunkcoord.x+16, chunkcoord.y+16}},
        name = tiles_to_find})
    if (#tiles > 0) then
        convert_tiles(tiles_to_set, tiles)
        --if _DEBUG then game.print(debug_message) end
    else
        -- if there are 0 tiles to convert, they're either fully creep or fully non-creep
        global.chunklist[i].is_creep = chunk_end_state
        -- if a chunk has lost all creep, do a final check to see if there are any buildings to kill
        if state == 2 then
            check_chunk_for_entities(global.chunklist[i])
        end
    end
end

local function on_tick()
    local get_pollution = game.surfaces[1].get_pollution

    -- localize globals
    local chunklist = global.chunklist
    local maxindex = #chunklist
    for i=global.c_index, global.c_index+processchunk, 1 do
        if i > maxindex then
            -- we've iterated through all chunks
            global.c_index = 1
            break
        end
        if get_pollution(chunklist[i]) > pollution_threshold and chunklist[i].is_creep ~= FULL_CREEP then
            change_creep_state(1, i) -- expand = 1, retract = 2
        elseif get_pollution(chunklist[i]) == 0 and chunklist[i].is_creep ~= NOT_CREEP then
            change_creep_state(2, i) -- expand = 1, retract = 2
        end
        if chunklist[i].is_creep == CREEP_RETRACTION then
            -- if a chunk's creep is retracting, we need to check if there are entities to kill
            check_chunk_for_entities(chunklist[i])
        end
    end
    global.c_index = global.c_index + processchunk
end

local function make_constrast_tiles_table()
    -- this creates a table of "contrast tiles", that is, tiles that are not creep nor creep retraction, nor water, nor void tiles
    -- we might want to use this list to pass to map gen tools to filter out tiles we don't want
    global.contrast_tiles = {}
    -- table of tiles that are already "anti-creep"
    local retraction_tiles = creep_retraction_tiles
    -- table of tiles we want to keep (water and void)
    local unremovable_tiles = {
    'deepwater',
    'deepwater-green',
    'out-of-map',
    'water',
    'water-green'
    }
    local omit = 0

    -- create a list of all non-creep tiles for the purpose of filtering in kill_invalid_builds
    for _, contrast_tile in ipairs(all_tiles) do
        for _, retraction_tile in ipairs(retraction_tiles) do
            if contrast_tile == retraction_tile then
                omit = 1
            end
        end
        for _, unremovable_tile in ipairs(unremovable_tiles) do
            if contrast_tile == unremovable_tile then
                omit = 1
            end
        end

        if omit == 1 then
            omit = 0
        else
            insert(global.contrast_tiles, contrast_tile)
        end
    end
end

local function on_chunk_generated(event)
    -- Track when new chunks are generated and add them to the chunklist
    if event.surface == game.surfaces[1] then
        local chunk = {}
        local coords = event.area.left_top
        chunk.x = coords.x+16
        chunk.y = coords.y+16
        chunk.is_creep = CREEP_UNKNOWN
        insert(global.chunklist, chunk)
    end
end

function kill_invalid_builds(entity, from_build_event)
    --Auto-destroy buildings created outside of creep
    if not (entity and entity.valid) then
        return
    end
    -- don't kill players
    if entity.type == 'player' then
        return
    end
    -- don't kill vehicles
    if entity.type == 'car' or entity.type == 'tank' or not entity.health then
        return
    end
    -- Some entities have no bounding box area.  Not sure which.
    if entity.bounding_box.left_top.x == entity.bounding_box.right_bottom.x or entity.bounding_box.left_top.y == entity.bounding_box.right_bottom.y then
        return
    end
    -- don't kill trains
    if entity.type == "locomotive"
    or entity.type == "fluid-wagon"
    or entity.type == "cargo-wagon"
    or entity.type == "artillery-wagon "
    then
        return
    end
    local last_user = entity.last_user
    local unacceptable_tiles = global.unacceptable_tiles
    local ceil = math.ceil
    local floor = math.floor

    -- expand the bounding box to enclose full tiles rather than the subtile size most bounding boxes are
    local bounding_box = {
        {floor(entity.bounding_box.left_top.x), floor(entity.bounding_box.left_top.y)},
        {ceil(entity.bounding_box.right_bottom.x), ceil(entity.bounding_box.right_bottom.y)}
    }
    local tiles = entity.surface.count_tiles_filtered{name = unacceptable_tiles, area = bounding_box, limit = 1}
    if tiles > 0 then
        --Need to turn off ghosts left by dead buildings so construction bots won't keep placing buildings and having them blow up.
        local force = entity.force
        local ttl = force.ghost_time_to_live
        entity.force.ghost_time_to_live = 0
        entity.die()
        force.ghost_time_to_live = ttl
        global.death_count = global.death_count + 1
        if from_build_event and last_user then
            last_user.print("You may only build on the creep!")
        end
    end
end

local function print_death_toll()
    if global.death_count > 1 then
        game.print(global.death_count .. " buildings have died outside of the creep recently.")
        global.death_count = 0
    end
end

local function kill_on_built (event)
    local entity = event.created_entity
    kill_invalid_builds(entity, true)
end

local function apply_creep_effects_on_players()
    --Penalize players for not being on creep by slowing their movement
    local radius = 10 --not actually a radius
    local unacceptable_tiles = global.unacceptable_tiles

    for _, p in ipairs(game.connected_players) do
        if not p.character then --Spectator or admin
            return
        end
        local count = p.surface.count_tiles_filtered{name=unacceptable_tiles, area={{p.position.x-radius, p.position.y-radius}, {p.position.x+radius, p.position.y+radius}}}
        if count == (radius * 2)^2 * 1 then
            if p.vehicle then
                return
            else
                p.surface.create_entity{name="acid-projectile-purple", target=p.character, position=p.character.position, speed=10}
                p.character.health = p.character.health - 20
                p.print("You are taking damage from being too far from the creep.")
            end
            p.character_running_speed_modifier = 0
            if _DEBUG then game.print("Speed modifier 0 and damage") end
        elseif count > (radius * 2)^2 * 0.8 then

            p.character_running_speed_modifier = 0
            if _DEBUG then game.print("Speed modifier 0") end
        else
            p.character_running_speed_modifier = 0.2
            if _DEBUG then game.print("Speed modifier 0.2") end
        end
    end
end

local function on_init()
    global.chunklist = {}
    global.c_index=1
    global.unacceptable_tiles = {}
    global.death_count = 0
    local omit = 0

    -- create a list of all non-creep tiles for the purpose of filtering in kill_invalid_builds
    for _, all_tile in ipairs(all_tiles) do
        for _, creep_tile in ipairs(creep_tiles) do
            if all_tile == creep_tile then
                omit = 1
            end
        end

        if omit == 1 then
            omit = 0
        else
            insert(global.unacceptable_tiles, all_tile)
        end
    end
end

Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.on_init(on_init)
Event.add(defines.events.on_built_entity, kill_on_built)
Event.add(defines.events.on_robot_built_entity, kill_on_built)
Event.on_nth_tick(death_recap_timer, print_death_toll)
Event.on_nth_tick(player_pos_check_time, apply_creep_effects_on_players)

-- a couple little debug command to generate and clear pollution to test things without having to mess with world gen
if _DEBUG then
commands.add_command(
    'cloud',
    'Use your vape rig to create a pollution cloud around you',
    function()
        if game.player then
            game.player.surface.pollute(game.player.position, 10000)
        end
    end
)
commands.add_command(
    'clean',
    'Use your vacuum to suck up the pollution cloud around you',
    function()
        if game.player then
            game.player.surface.clear_pollution()
        end
    end
)
end
