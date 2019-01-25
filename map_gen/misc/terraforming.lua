local Game = require 'utils.game'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Popup = require 'features.gui.popup'
local Global = require 'utils.global'
local Command = require 'utils.command'
local RS = require 'map_gen.shared.redmew_surface'

local random = math.random
local insert = table.insert

if not global.map.terraforming then
    global.map.terraforming = {}
end

--[[
Some inspiration and bits of code taken from Nightfall by Yehn and dangOreus by Mylon.
Both under their respective MIT licenses.

This softmod originally used the Starcraft concept of "creep" as a mechanic. This was later changed
to a terraforming context, but most of the code and documentation will keep the creep terminology.
Players can only build on certain creep tiles (in particular, the defined `creep_expansion_tile`s).
Pollution will naturally expand the creep. The creep will also naturally regress if pollution
is not sustained, affecting player structures in the process.

This module does not create a map/safe start area, so you will not have a guaranteed safe placed
to build, and any creep_expansion_tiles will be overtaken by creep_retraction_tiles as there is
no initial pollution cloud. You can use creep-exempt tiles for a safe starting area.

Would love to make the expansion less "blocky"/constrained to chunk borders.
]]

-- lets you know when creep is spreading/contracting (it is very verbose/annoying)
global.DEBUG_SPREAD = false
-- lets you know when your bonuses/penalties change based on being on creep
global.DEBUG_ON_CREEP = false

--how many chunks to process in a tick
local processchunk = 5
-- the amount of damage taken when too far from creep
local off_creep_damage = 15
-- how often to check for players' positions
local player_pos_check_time = 180 --  3 secs
-- the amount of extra damage to deal if a player has shields (because they will regen health)
local regen_factor = 0.194 * player_pos_check_time
-- how often to recap the deaths from lack of creep (in ticks)
local death_recap_timer = 1200 --  20 secs
-- force that is restricted to the creep
local creep_force = 'player'
-- the threshold above which creep expands
local pollution_upper_threshold = 200
-- the threshold below which creep retracts
local pollution_lower_threshold = 100
-- the number of tiles that change to/from creep at once
local random_factor = 0.1

-- the message to pop up when players build on the wrong tiles
local popup_message = 'You may only build on terraformed land! Terraform by spreading pollution.'
-- the message attached to the number of entities destroyed from not being on creep tiles
local death_recap_message = ' buildings have died to the toxic atmosphere recently.'
-- message printed to player when taking damage from being away from the creep
local player_damage_message = 'You are taking damage from the toxic atmosphere.'
-- message printed to player when they are ejected from a vehicle from being away from the creep
local vehicle_ejecte_message = 'The toxic atmosphere wreaks havoc on your controls and you find yourself ejected from the vehicle.'
-- message printed to game when a player dies to the atmosphere
local player_death_message = 'The toxic atmosphere has claimed a victim.'
-- message printed to the game when a bot is destroyed placing a tile
local dead_robot_recap_message = ' robots died trying to place tiles, it seemed as though the ground swelled up swallowed them whole.'
-- message printed to the game when a player tries placing a tile
local player_built_tile_message = 'The ground rejects the artificial tiles you have tried to place'

-- boosts while on creep
local boosts = {
    ['character_running_speed_modifier'] = 1.1,
    ['character_mining_speed_modifier'] = 1.3,
    ['character_crafting_speed_modifier'] = 1,
    ['character_health_bonus'] = 200,
}

-- which tiles to use for creep expansion
local creep_expansion_tiles = global.map.terraforming.creep_expansion_tiles or {
    'grass-1',
    'grass-2',
}
-- which tiles to use when creep retracts
local creep_retraction_tiles = global.map.terraforming.creep_retraction_tiles or {
    'dirt-1',
    'dirt-2',
    'dry-dirt',
    'sand-1',
    'sand-2',
    'sand-3',
}
-- which tiles players can build on/count as creep
local creep_tiles = global.map.terraforming.creep_tiles or {
    'grass-1',
    'grass-2',
    'concrete',
    'hazard-concrete-left',
    'hazard-concrete-right',
    'refined-concrete',
    'refined-hazard-concrete-left',
    'refined-hazard-concrete-right',
    'stone-path',
}
-- tiles which creep can expand into
local non_creep_tiles = global.map.terraforming.non_creep_tiles or {
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
    'sand-3',
}
-- Tiles which are completely exempt from the creep mechanic, currently kept in comment as a reference:
-- 'deepwater', 'deepwater-green', 'out-of-map', 'water', 'water-green', 'lab-dark-1', 'lab-dark-2', 'lab-white', 'tutorial-grid'
local decoratives = {
    'brown-asterisk',
    'brown-carpet-grass',
    'brown-fluff',
    'brown-fluff-dry',
    'brown-hairy-grass',
    'garballo',
    'garballo-mini-dry',
    'green-asterisk',
    'green-bush-mini',
    'green-carpet-grass',
    'green-hairy-grass',
    'green-pita',
    'green-pita-mini',
    'green-small-grass',
    'red-asterisk'
}

-- the 5 states a chunk can be in
local NOT_CREEP = 1 -- Chunk is 0% creep tiles and unpolluted
local FULL_CREEP = 2 -- Chunk is 100% creep tile and polluted
local CREEP_RETRACTION = 3 -- Chunk has >0% creep tiles but is unpolluted
local CREEP_EXPANDING = 4 -- Chunk has <100% creep tiles but is polluted
local CREEP_UNKNOWN = 5 -- a special case for newly-generated chunks where we need to check their state

-- Register our globals
local chunklist = {}
local popup_timeout = {}
local death_count = {0}
local dead_robot_count = {0}
local c_index = {1}

Global.register(
    {
        chunklist = chunklist,
        death_count = death_count,
        c_index = c_index,
        dead_robot_count = dead_robot_count,
        popup_timeout = popup_timeout,
    },
    function(tbl)
        chunklist = tbl.chunklist
        death_count = tbl.death_count
        c_index = tbl.c_index
        dead_robot_count = tbl.dead_robot_count
        popup_timeout = tbl.popup_timeout
    end
)

--- Converts tiles
-- @param tile_table table of tiles to convert
-- @param tiles table of potential tiles to convert to
local function convert_tiles(tile_table, tiles)
    local set_tiles = RS.get_surface().set_tiles
    local tile_set = {}
    local target_tile = tile_table[random(1, #tile_table)]
    -- convert the LuaTiles table into a new one we can edit
    for _, tiledata in pairs(tiles) do
        if random() < random_factor then
            tile_set[#tile_set + 1] = {name = target_tile, position = tiledata.position}
        end
    end
    -- change the tiles to the target_tile
    set_tiles(tile_set)
end

local on_popup_timeout_complete =
    Token.register(
    function(name)
        popup_timeout[name] = nil
    end
)

--- Kills buildings that are not on creep tiles
-- @param entity LuaEntity to kill
-- @param event or false - whether the entity is coming from a build event
local function kill_invalid_builds(event)
    local entity = event.created_entity
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
    if entity.type == 'locomotive' or entity.type == 'fluid-wagon' or entity.type == 'cargo-wagon' or entity.type == 'artillery-wagon ' then
        return
    end

    local last_user = entity.last_user
    local ceil = math.ceil
    local floor = math.floor

    -- expand the bounding box to enclose full tiles to be scanned (if your area is less than the full size of the tile, the tile is not included)
    local bounding_box = {
        {floor(entity.bounding_box.left_top.x), floor(entity.bounding_box.left_top.y)},
        {ceil(entity.bounding_box.right_bottom.x), ceil(entity.bounding_box.right_bottom.y)}
    }
    local tiles = entity.surface.count_tiles_filtered {name = non_creep_tiles, area = bounding_box, limit = 1}
    if tiles > 0 then
        --Need to turn off ghosts left by dead buildings so construction bots won't keep placing buildings and having them blow up.
        local force = entity.force
        local ttl = force.ghost_time_to_live
        entity.force.ghost_time_to_live = 0
        entity.die()
        force.ghost_time_to_live = ttl
        death_count[1] = death_count[1] + 1
        -- checking for event.tick is a cheap way to see if it's an actual event or if the event data came from check_chunk_for_entities
        if event.tick and last_user and last_user.connected and not popup_timeout[last_user.name] then
            Popup.player(last_user, popup_message)
            popup_timeout[last_user.name] = true
            Task.set_timeout(60, on_popup_timeout_complete, last_user.name)
        end
    end
end

--- Scans the provided chunk for entities on force _creep_force_.
--@param chunk table with position and status of a map chunk
local function check_chunk_for_entities(chunk)
    local find_entities_filtered = RS.get_surface().find_entities_filtered
    local entities_found
    entities_found =
        find_entities_filtered {
        area = {{chunk.x - 16, chunk.y - 16}, {chunk.x + 16, chunk.y + 16}},
        force = creep_force
    }
    for _, entity in pairs(entities_found) do
        kill_invalid_builds({['created_entity'] = entity})
    end
end

--- Changes the state and tiles of chunks when they meet the creep expansion/retraction criteria
--@param state number representing whether we want to expand or contract the chunk (expand = 1, retract = 2)
--@param i number of the chunk's key in the chunklist table
local function change_creep_state(state, i)
    local find_tiles_filtered = RS.get_surface().find_tiles_filtered
    local tiles_to_set = {}
    local debug_message
    local chunk_end_state
    local chunk_transition_state
    local tiles_to_find

    -- states: expand = 1, retract = 2
    if state == 1 then
        tiles_to_find = non_creep_tiles
        tiles_to_set = creep_expansion_tiles
        debug_message = 'Creep expanding'
        chunk_end_state = FULL_CREEP
        chunk_transition_state = CREEP_EXPANDING
    elseif state == 2 then
        tiles_to_find = creep_tiles
        tiles_to_set = creep_retraction_tiles
        debug_message = 'Creep retracting'
        chunk_end_state = NOT_CREEP
        chunk_transition_state = CREEP_RETRACTION
    end

    chunklist[i].is_creep = chunk_transition_state
    local chunkcoord = chunklist[i]
    local tiles =
        find_tiles_filtered(
        {
            area = {{chunkcoord.x - 16, chunkcoord.y - 16}, {chunkcoord.x + 16, chunkcoord.y + 16}},
            name = tiles_to_find
        }
    )
    if (#tiles > 0) then
        convert_tiles(tiles_to_set, tiles)
        if global.DEBUG_SPREAD then
            game.print(debug_message)
        end
    else
        -- if there are 0 tiles to convert, they're either fully creep or fully non-creep
        chunklist[i].is_creep = chunk_end_state
        -- if a chunk has lost all creep, do a final check to see if there are any buildings to kill and regen the decoratives
        if state == 2 then
            check_chunk_for_entities(chunklist[i])
            RS.get_surface().regenerate_decorative(decoratives, {{chunklist[i].x, chunklist[i].y}})
        end
    end
end

--- Every tick scan _processchunk_ number of chunks for their pollution state and if needed, change their state
local function on_tick()
    local get_pollution = RS.get_surface().get_pollution
    local maxindex = #chunklist
    for i = c_index[1], c_index[1] + processchunk, 1 do
        if i > maxindex then
            -- we've iterated through all chunks
            c_index[1] = 1
            break
        end
        if get_pollution(chunklist[i]) > pollution_upper_threshold and chunklist[i].is_creep ~= FULL_CREEP then
            change_creep_state(1, i) -- expand = 1, retract = 2
        elseif get_pollution(chunklist[i]) < pollution_lower_threshold and chunklist[i].is_creep ~= NOT_CREEP then
            change_creep_state(2, i) -- expand = 1, retract = 2
        end
        if chunklist[i].is_creep == CREEP_RETRACTION then
            -- if a chunk's creep is retracting, we need to check if there are entities to kill
            check_chunk_for_entities(chunklist[i])
        end
    end
    c_index[1] = c_index[1] + processchunk
end

--- Takes newly generated chunks and places them inside the chunklist table
local function on_chunk_generated(event)
    if event.surface == RS.get_surface() then
        local chunk = {}
        local coords = event.area.left_top
        chunk.x = coords.x + 16
        chunk.y = coords.y + 16
        chunk.is_creep = CREEP_UNKNOWN
        insert(chunklist, chunk)
    end
end

--- Prints the number of deaths from buildings outside of creep. Resets every _death_recap_timer_ ticks.
local function print_death_recap()
    if death_count[1] > 1 then
        game.print(death_count[1] .. death_recap_message)
        death_count[1] = 0
    end
    if dead_robot_count[1] > 1 then
        game.print(dead_robot_count[1] .. dead_robot_recap_message)
        dead_robot_count[1] = 0
    end
end

--- Apply penalties for being away from creep
local function apply_penalties(p, c)
    for boost in pairs(boosts) do
        p[boost] = 0
    end
    c.disable_flashlight()
end

--- Gives movement speed buffs when on creep, slows when only near creep, damages when far from creep.
local function apply_creep_effects_on_players()
    local radius = 10 --distance to check around player for creep (nb. not actually a radius)
    for _, p in pairs(game.connected_players) do
        local c = p.character
        if c then
            -- count all non_creep_tiles around the player
            local count = p.surface.count_tiles_filtered {name = non_creep_tiles, area = {{p.position.x - radius, p.position.y - radius}, {p.position.x + radius, p.position.y + radius}}}
            if count == (radius * 2) ^ 2 then
                -- kick player from vehicle
                if p.vehicle then
                    p.driving = false
                    p.print(vehicle_ejecte_message)
                end
                -- calculate damage based on whether player has shields and is not in combat and check to see if we would deal lethal damage
                -- (shields prevent us putting the character into combat, so we need to compensate for health regen)
                local message = player_damage_message
                local damage
                if c.grid and c.grid.shield and not c.in_combat then
                    damage = off_creep_damage + regen_factor
                    message = message .. ' Your shields do nothing to help.'
                else
                    damage = off_creep_damage
                end
                if (damage + 10) >= c.health then -- add 10 for the acid projectile damage
                    c.die('enemy')
                    game.print(player_death_message)
                    return
                end
                -- create acid splash and deal damage
                p.surface.create_entity {name = 'acid-projectile-purple', target = p.character, position = p.character.position, speed = 10}
                c.health = c.health - damage
                p.print(message)
                -- apply penalties for being away from creep
                apply_penalties(p, c)
                if global.DEBUG_ON_CREEP then
                    game.print('Far from creep and taking damage')
                end
            elseif count > (radius * 2) ^ 2 * 0.8 then
                -- apply penalties for being away from creep
                apply_penalties(p, c)
                if global.DEBUG_ON_CREEP then
                    game.print('Near but not on creep')
                end
            else
                -- apply boosts for being on or near creep
                for boost, boost_value in pairs(boosts) do
                    p[boost] = boost_value
                end
                c.enable_flashlight()
                if global.DEBUG_ON_CREEP then
                    game.print('On creep and getting full benefits')
                end
            end
        end
    end
end

--- Revert built tiles
local function check_on_tile_built(event)
    local surface
    if event.robot then
        surface = event.robot.surface
        event.robot.die('enemy')
        dead_robot_count[1] = dead_robot_count[1] + 1
    else
        local player = Game.get_player_by_index(event.player_index)
        surface = player.surface
        player.print(player_built_tile_message)
    end
    global.temp = event.tiles
    local tile_set = {}
    insert = table.insert
    for k, v in pairs(event.tiles) do
        tile_set[#tile_set + 1] = {name = v.old_tile.name, position = v.position}
    end
    surface.set_tiles(tile_set)
end

Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_built_entity, kill_invalid_builds)
Event.add(defines.events.on_robot_built_entity, kill_invalid_builds)
Event.add(defines.events.on_player_built_tile, check_on_tile_built)
Event.add(defines.events.on_robot_built_tile, check_on_tile_built)
Event.on_nth_tick(death_recap_timer, print_death_recap)
Event.on_nth_tick(player_pos_check_time, apply_creep_effects_on_players)

--- Debug commands which will generate or clear pollution
Command.add(
    'cloud',
    {
        description = 'Create a lot of pollution',
        debug_only = true,
        cheat_only = true
    },
    function()
        if game.player then
            game.player.surface.pollute(game.player.position, 10000)
        end
    end
)
Command.add(
    'clean',
    {
        description = 'Eliminate all pollution on the surface',
        debug_only = true,
        cheat_only = true
    },
    function()
        if game.player then
            game.player.surface.clear_pollution()
        end
    end
)
