-- Biters attack in the dark

local Event = require 'utils.event'
local Global = require 'utils.global'
local random = math.random
local floor = math.floor
local ceil = math.ceil

local debounce = {} -- player_index --> boolean
Global.register(debounce, function(tbl) debounce = tbl end)

local DARK_THRESHOLD = 0.71
local DELTA_TIME = 15 * 60 -- 15s
local FIGHT_TIME = 105 * 60 -- 1:45m
local SPAWN_CHANCE = 16
local ORE_TILES = 4
local lamp_search_filter = { position = nil, radius = 8, type = 'lamp', limit = 1 }
local entity_search_filter = { position = nil, force = 'player', radius = 4 }
local resource_search_filter = { position = nil, type = 'resource', name = { 'coal', 'copper-ore', 'iron-ore', 'stone' }, radius = 0.49 }

local ores = {}
local units

do
    for _ = 1, 15 do ores[#ores+1] = 'iron-ore' end
    for _ = 1, 9 do ores[#ores+1] = 'coal' end
    for _ = 1, 7 do ores[#ores+1] = 'copper-ore' end
    for _ = 1, 3 do ores[#ores+1] = 'stone' end

    local u1 = {}
    for _ = 1, 3 do u1[#u1 +1] = 'small-biter' end
    for _ = 1, 1 do u1[#u1 +1] = 'small-spitter' end

    local u2 = {}
    for _ = 1, 7 do u2[#u2 +1] = 'medium-biter' end
    for _ = 1, 3 do u2[#u2 +1] = 'medium-spitter' end

    local u3 = {}
    for _ = 1, 7 do u3[#u3 +1] = 'big-biter' end
    for _ = 1, 3 do u3[#u3 +1] = 'big-spitter' end

    local u4 = {}
    for _ = 1, 2 do u3[#u3 +1] = 'big-biter' end
    for _ = 1, 1 do u3[#u3 +1] = 'big-spitter' end
    for _ = 1, 12 do u4[#u4 +1] = 'medium-biter' end
    for _ = 1, 5 do u4[#u4 +1] = 'medium-spitter' end

    units = { u1, u2, u3, u4 }
end

---@param evo number
---@return string[]
local function get_unit_by_evo(evo)
    if evo < 0.20 then return units[1] end
    if evo < 0.50 then return units[2] end
    if evo < 0.90 then return units[3] end
    return units[4]
end

-- Append Entity+Position data to the list of candidates
---@param entity LuaEntity
---@param candidates { entity?: LuaEntity, position: MapPosition }[]
local function collect_entity_positions(entity, candidates)
    local box = entity.selection_box
    local left   = floor(box.left_top.x)
    local top    = floor(box.left_top.y)
    local right  = ceil(box.right_bottom.x) - 1
    local bottom = ceil(box.right_bottom.y) - 1

    for y = top, bottom do
        for x = left, right do
            candidates[#candidates+1] = {
                entity = entity,
                position = { x = x + 0.5, y = y + 0.5 }
            }
        end
    end
end

---@param center MapPosition
---@return MapPosition
local function random_position_nearby(center)
    return {
        position = {
            x = center.x + random(-3, 3),
            y = center.y + random(-3, 3),
        }
    }
end

---@param surface LuaSurface
---@param position MapPosition
---@return { entity?: LuaEntity, position: MapPosition}[]
local function get_spawn_candidates(surface, position)
    local results = {}

    entity_search_filter.position = position
    local entities = surface.find_entities_filtered(entity_search_filter)

    for i = 1, #entities do
        if #results >= ORE_TILES then break end

        local entity = entities[i]
        if entity.valid and entity.type ~= 'character' then
            local tiles = {}
            collect_entity_positions(entity, tiles)

            -- pick at most one tile from each entity but large entities contribute more weight by allowing more than one tile if needed.
            for t = 1, #tiles do
                results[#results+1] = tiles[t]
                if #results >= ORE_TILES then break end
            end
        end
    end

    -- if not enough entities, then random positions to fill up
    while #results < ORE_TILES do
        results[#results+1] = random_position_nearby(position)
    end

    return results
end

-- Verify that the unit target is within reach as this could be triggered from another surface even
---@param player LuaPlayer
---@return LuaEntity|nil
local function validate_unit_target(player)
    local character = player.character
    if not (character and character.valid) then
        return
    end

    if character.surface ~= player.surface then
        return
    end

    local c_pos = character.position
    local p_pos = player.position -- intentional instead of player.physical_position
    local dx = c_pos.x - p_pos.x
    local dy = c_pos.y - p_pos.y

    if (dx*dx + dy*dy) > 4096 then
        return
    end

    return character
end

---@param entity? LuaEntity
local function do_kill_entity(entity)
    if not (entity and entity.valid) then
        return
    end
    entity.die('enemy')
end

---@param surface LuaSurface
---@param position MapPosition
local function do_spawn_ore(surface, position)
    resource_search_filter.position = position
    local ore = surface.find_entities_filtered(resource_search_filter)[1]
    if not ore then
        ore = surface.create_entity{
            name = ores[random(#ores)],
            amount = 1,
            position = position,
            enable_tree_removal = false,
            enable_cliff_removal  = false,
        }
    end
    if ore and ore.valid then
        ore.amount = ore.amount + random(75, 150)
    end
end

---@param surface LuaSurface
---@param position MapPosition
---@param raffle string[]
---@param target? LuaEntity
local function do_spawn_unit(surface, position, raffle, target)
    local name = raffle[random(#raffle)]
    surface.create_entity{
        name = name,
        force = 'enemy',
        position = position,
        direction = random(8),
        target = target,
        move_stuck_players = true,
    }
    surface.create_entity{
        name = name..'-die',
        force = 'enemy',
        position = position,
    }
    surface.create_trivial_smoke{
        name = 'small-dusty-explosion-smoke',
        position = position
    }
end

---@param surface LuaSurface
---@param position MapPosition
---@return boolean
local function should_trigger(surface, position)
    if surface.darkness < DARK_THRESHOLD then
        return false
    end
    if random(SPAWN_CHANCE) ~= 1 then
        return false
    end
    lamp_search_filter.position = position
    return (surface.count_entities_filtered(lamp_search_filter) == 0)
end

local function on_player_changed_position(event)
    local player_index = event.player_index
    if (debounce[player_index] or 0) > game.tick then
        return
    end

    local player = game.get_player(player_index)
    if not (player and player.valid) then
        return
    end

    local surface = player.surface
    debounce[player_index] = game.tick + DELTA_TIME

    if not should_trigger(surface, player.position) then
        return
    end

    local evo = game.forces.enemy.get_evolution_factor(surface)
    local raffle = get_unit_by_evo(evo)
    local target = validate_unit_target(player)

    local candidates = get_spawn_candidates(surface, player.position)
    for _, candidate in pairs(candidates) do
        do_kill_entity(candidate.entity)
        do_spawn_ore(surface, candidate.position)
        do_spawn_unit(surface, candidate.position, raffle, target)
    end

    debounce[player_index] = debounce[player_index] + FIGHT_TIME
end

local function on_built(event)
    local entity = event.entity or event.destination
    if not (entity and entity.valid and entity.type == 'lamp') then
        return
    end

    entity.always_on = true
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_built_entity, on_built)
Event.add(defines.events.on_entity_cloned, on_built)
Event.add(defines.events.on_robot_built_entity, on_built)
Event.add(defines.events.script_raised_built, on_built)
Event.add(defines.events.script_raised_revive, on_built)
Event.add(defines.events.on_space_platform_built_entity, on_built)
