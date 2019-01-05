--Author: MewMew
-- Threaded by Tris
-- !! ATTENTION !!
-- Use water only in starting area as map setting!!!
local perlin = require 'map_gen.shared.perlin_noise'
local Task = require 'utils.task'
local RS = require 'map_gen.shared.redmew_surface'
wreck_item_pool = {}
wreck_item_pool = {
    {name = 'iron-gear-wheel', count = 32},
    {name = 'iron-plate', count = 64},
    {name = 'rocket-control-unit', count = 1},
    {name = 'coal', count = 4},
    {name = 'rocket-launcher', count = 1},
    {name = 'rocket', count = 32},
    {name = 'copper-cable', count = 128},
    {name = 'land-mine', count = 64},
    {name = 'railgun', count = 1},
    {name = 'railgun-dart', count = 128},
    {name = 'fast-inserter', count = 8},
    {name = 'stack-filter-inserter', count = 2},
    {name = 'belt-immunity-equipment', count = 1},
    {name = 'fusion-reactor-equipment', count = 1},
    {name = 'electric-engine-unit', count = 8},
    {name = 'exoskeleton-equipment', count = 1},
    {name = 'rocket-fuel', count = 10},
    {name = 'used-up-uranium-fuel-cell', count = 3},
    {name = 'uranium-fuel-cell', count = 2}
}

local function place_entities(surface, entity_list)
    local directions = {
        defines.direction.north,
        defines.direction.east,
        defines.direction.south,
        defines.direction.west
    }
    for _, entity in pairs(entity_list) do
        local r = math.random(1, entity.chance)
        if r == 1 then
            if not entity.force then
                entity.force = 'player'
            end
            local r = math.random(1, 4)
            if
                surface.can_place_entity {
                    name = entity.name,
                    position = entity.pos,
                    direction = directions[r],
                    force = entity.force
                }
             then
                local e =
                    surface.create_entity {
                    name = entity.name,
                    position = entity.pos,
                    direction = directions[r],
                    force = entity.force
                }
                if entity.health then
                    if entity.health == 'low' then
                        e.health = ((e.health / 1000) * math.random(33, 330))
                    end
                    if entity.health == 'medium' then
                        e.health = ((e.health / 1000) * math.random(333, 666))
                    end
                    if entity.health == 'high' then
                        e.health = ((e.health / 1000) * math.random(666, 999))
                    end
                    if entity.health == 'random' then
                        e.health = ((e.health / 1000) * math.random(1, 1000))
                    end
                end
                return true, e
            end
        end
    end
    return false
end

local function auto_place_entity_around_target(entity, scan_radius, mode, density, surface)
    local x = entity.pos.x
    local y = entity.pos.y
    if not surface then
        surface = RS.get_surface()
    end
    if not scan_radius then
        scan_radius = 6
    end
    if not entity then
        return
    end
    if not mode then
        mode = 'ball'
    end
    if not density then
        density = 1
    end

    if surface.can_place_entity {name = entity.name, position = {x, y}} then
        local e = surface.create_entity {name = entity.name, position = {x, y}}
        return true, e
    end

    local i = 2
    local r = 1

    if mode == 'ball' then
        if math.random(1, 2) == 1 then
            density = density * -1
        end
        r = math.random(1, 4)
    end
    if mode == 'line' then
        density = 1
        r = math.random(1, 4)
    end
    if mode == 'line_down' then
        density = density * -1
        r = math.random(1, 4)
    end
    if mode == 'line_up' then
        density = 1
        r = math.random(1, 4)
    end
    if mode == 'block' then
        r = 1
        density = 1
    end

    if r == 1 then
        --start placing at -1,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                x = x + density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                y = y + density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                x = x - density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                y = y - density
            end
            i = i + 2
        end
    end

    if r == 2 then
        --start placing at 0,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                x = x + density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                y = y + density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                x = x - density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                y = y - density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            i = i + 2
        end
    end

    if r == 3 then
        --start placing at 1,-1
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                y = y + density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                x = x - density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                y = y - density
            end
            for a = 1, i, 1 do
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
                x = x + density
            end
            i = i + 2
        end
    end

    if r == 4 then
        --start placing at 1,0
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                y = y + density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                x = x - density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                y = y - density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            for a = 1, i, 1 do
                x = x + density
                if surface.can_place_entity {name = entity.name, position = {x, y}} then
                    local e = surface.create_entity {name = entity.name, position = {x, y}}
                    return true, e
                end
            end
            i = i + 2
        end
    end

    return false
end

local function create_tree_cluster(pos, amount)
    if not pos then
        return false
    end
    if amount == nil then
        amount = 7
    end
    local scan_radius = amount * 2
    --local mode = "line_down"
    --if math.random(1,2) == 1 then mode = "line_up" end
    local mode = 'ball'
    local entity = {}
    entity.pos = pos
    for i = 1, amount, 1 do
        entity.name = 'tree-06'
        local density = 2
        if 1 == math.random(1, 20) then
            entity.name = 'tree-07'
        end
        if 1 == math.random(1, 70) then
            entity.name = 'tree-09'
        end
        if 1 == math.random(1, 10) then
            entity.name = 'tree-04'
        end
        if 1 == math.random(1, 9) then
            density = 1
        end
        if 1 == math.random(1, 3) then
            density = 3
        end
        if 1 == math.random(1, 3) then
            density = 4
        end

        local b, e = auto_place_entity_around_target(entity, scan_radius, mode, density)
        if b == true then
            if 1 == math.random(1, 3) then
                entity.pos = e.position
            end
        end
    end
    return b, e
end

global.swamp_tiles_hold = {}
global.swamp_decoratives_hold = {}

function run_swamp_init(params)
    global.swamp_tiles_hold = {}
    global.swamp_decoratives_hold = {}
end

function run_swamp_place_tiles(params)
    local surface = params.surface
    surface.set_tiles(global.swamp_tiles_hold)
    for _, deco in pairs(global.swamp_decoratives_hold) do
        surface.create_decoratives {check_collision = false, decoratives = {deco}}
    end
end

function run_swamp_river(params)
    local area = params.area
    local surface = params.surface

    local x = params.x
    local pos_x = area.left_top.x + x
    local seed = params.seed

    for y = 0, 31, 1 do
        local pos_y = area.left_top.y + y
        local noise_terrain_1 = perlin.noise(((pos_x + seed) / 150), ((pos_y + seed) / 150), 0)
        local noise_terrain_2 = perlin.noise(((pos_x + seed) / 75), ((pos_y + seed) / 75), 0)
        local noise_terrain_3 = perlin.noise(((pos_x + seed) / 50), ((pos_y + seed) / 50), 0)
        local noise_terrain_4 = perlin.noise(((pos_x + seed) / 7), ((pos_y + seed) / 7), 0)
        local noise_terrain =
            noise_terrain_1 + (noise_terrain_2 * 0.2) + (noise_terrain_3 * 0.1) + (noise_terrain_4 * 0.02)
        local tile_to_insert
        if noise_terrain > -0.03 and noise_terrain < 0.03 then
            tile_to_insert = 'water-green'
            local a = pos_x + 1
            table.insert(global.swamp_tiles_hold, {name = tile_to_insert, position = {a, pos_y}})
            local a = pos_y + 1
            table.insert(global.swamp_tiles_hold, {name = tile_to_insert, position = {pos_x, a}})
            local a = pos_x - 1
            table.insert(global.swamp_tiles_hold, {name = tile_to_insert, position = {a, pos_y}})
            local a = pos_y - 1
            table.insert(global.swamp_tiles_hold, {name = tile_to_insert, position = {pos_x, a}})
            table.insert(global.swamp_tiles_hold, {name = tile_to_insert, position = {pos_x, pos_y}})
        end
    end
end

function run_swamp_destroy_trees(params)
    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        if entity.type == 'simple-entity' or entity.type == 'tree' then
            if entity.name ~= 'tree-09' and entity.name ~= 'tree-07' and entity.name ~= 'tree-06' then --and entity.name ~= "tree-04"
                entity.destroy()
            end
        end
    end
end

function run_swamp_entities(params)
    local area = params.area
    local surface = params.surface

    local x = params.x
    local pos_x = area.left_top.x + x
    local forest_cluster = params.forest_cluster

    for y = 0, 31, 1 do
        local pos_y = area.left_top.y + y
        local pos = {x = pos_x, y = pos_y}
        local tile = surface.get_tile(pos_x, pos_y)
        local tile_to_insert = tile
        local entity_placed = false
        -- or tile.name == "grass-2"
        --if tile.name ~= "water" and tile.name ~= "deepwater" and tile.name ~= "water-green" then
        if tile.name ~= 'water-green' then
            table.insert(global.swamp_tiles_hold, {name = 'grass-1', position = {pos_x, pos_y}})

            local entity_list = {}
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-1', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-2', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            table.insert(
                entity_list,
                {name = 'big-ship-wreck-3', pos = {pos_x, pos_y}, chance = 65000, health = 'random'}
            )
            local b, placed_entity = place_entities(surface, entity_list)
            if b == true then
                placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
                placed_entity.insert(wreck_item_pool[math.random(1, #wreck_item_pool)])
            end

            local entity_list = {}
            table.insert(entity_list, {name = 'tree-04', pos = {pos_x, pos_y}, chance = 400})
            table.insert(entity_list, {name = 'tree-09', pos = {pos_x, pos_y}, chance = 1000})
            table.insert(entity_list, {name = 'tree-07', pos = {pos_x, pos_y}, chance = 400})
            table.insert(entity_list, {name = 'tree-06', pos = {pos_x, pos_y}, chance = 150})
            table.insert(entity_list, {name = 'rock-big', pos = {pos_x, pos_y}, chance = 400})
            table.insert(entity_list, {name = 'green-coral', pos = {pos_x, pos_y}, chance = 10000})
            table.insert(
                entity_list,
                {name = 'medium-ship-wreck', pos = {pos_x, pos_y}, chance = 25000, health = 'random'}
            )
            table.insert(
                entity_list,
                {name = 'small-ship-wreck', pos = {pos_x, pos_y}, chance = 25000, health = 'random'}
            )
            table.insert(entity_list, {name = 'car', pos = {pos_x, pos_y}, chance = 125000, health = 'low'})
            table.insert(
                entity_list,
                {name = 'stone-furnace', pos = {pos_x, pos_y}, chance = 100000, health = 'random', force = 'enemy'}
            )
            local b, placed_entity = place_entities(surface, entity_list)

            if forest_cluster == true then
                if math.random(1, 800) == 1 then
                    create_tree_cluster(pos, 120)
                end
            end
        else
            --if tile.name == "water" then tile_to_insert = "water" end
            --if tile.name == "deepwater" then tile_to_insert = "deepwater" end
        end
    end
end

function run_combined_module(event)
    -- Generate Rivers
    if not global.perlin_noise_seed then
        global.perlin_noise_seed = math.random(1000, 1000000)
    end

    local seed = global.perlin_noise_seed
    local tiles = {}

    Task.queue_task('run_swamp_init', {})
    for x = 0, 31, 1 do
        Task.queue_task('run_swamp_river', {area = event.area, surface = event.surface, x = x, seed = seed})
    end
    Task.queue_task('run_swamp_place_tiles', {surface = event.surface})

    -- Generate other thingies
    Task.queue_task('run_swamp_destroy_trees', {area = event.area, surface = event.surface, x = x})

    local forest_cluster = true
    if math.random(1, 4) == 1 then
        forest_cluster = false
    end

    Task.queue_task('run_swamp_init', {})

    for x = 0, 31, 1 do
        Task.queue_task(
            'run_swamp_entities',
            {area = event.area, surface = event.surface, x = x, forest_cluster = forest_cluster}
        )
    end
    Task.queue_task('run_swamp_place_tiles', {surface = event.surface})

    Task.queue_task('run_swamp_cleanup', {area = event.area, surface = event.surface})

    Task.queue_task('run_chart_update', {area = event.area, surface = event.surface})
end

function run_chart_update(params)
    local x = params.area.left_top.x / 32
    local y = params.area.left_top.y / 32
    if game.forces.player.is_chunk_charted(params.surface, {x, y}) then
        -- Don't use full area, otherwise adjacent chunks get charted
        game.forces.player.chart(
            params.surface,
            {
                {params.area.left_top.x, params.area.left_top.y},
                {params.area.left_top.x + 30, params.area.left_top.y + 30}
            }
        )
    end
end

function run_swamp_cleanup(params)
    local area = params.area
    local surface = params.surface
    local decoratives = {}

    --check for existing chunk if you would overwrite decoratives
    local for_start_x = 0
    local for_end_x = 31
    local for_start_y = 0
    local for_end_y = 31
    local testing_pos = area.left_top.x - 1
    local tile = surface.get_tile(testing_pos, area.left_top.y)
    if tile.name then
        for_start_x = -1
    end
    local testing_pos = area.left_top.y - 1
    local tile = surface.get_tile(area.left_top.x, testing_pos)
    if tile.name then
        for_start_y = -1
    end
    local testing_pos = area.right_bottom.x
    local tile = surface.get_tile(testing_pos, area.right_bottom.y)
    if tile.name then
        for_end_x = 32
    end
    local testing_pos = area.right_bottom.y
    local tile = surface.get_tile(area.right_bottom.x, testing_pos)
    if tile.name then
        for_end_y = 32
    end

    for x = for_start_x, for_end_x, 1 do
        for y = for_start_y, for_end_y, 1 do
            local pos_x = area.left_top.x + x
            local pos_y = area.left_top.y + y
            local tile = surface.get_tile(pos_x, pos_y)
            local decal_has_been_placed = false

            if tile.name == 'grass-1' then
                if decal_has_been_placed == false then
                    local r = math.random(1, 3)
                    if r == 1 then
                        table.insert(
                            decoratives,
                            {name = 'green-carpet-grass-1', position = {pos_x, pos_y}, amount = 1}
                        )
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 7)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-hairy-grass-1', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 10)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-bush-mini', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 6)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-pita', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 12)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-small-grass-1', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 25)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-asterisk', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
            end
            if tile.name == 'water' or tile.name == 'water-green' then
                if decal_has_been_placed == false then
                    local r = math.random(1, 18)
                    if r == 1 then
                        table.insert(
                            decoratives,
                            {name = 'green-carpet-grass-1', position = {pos_x, pos_y}, amount = 1}
                        )
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 950)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-small-grass-1', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
                if decal_has_been_placed == false then
                    local r = math.random(1, 150)
                    if r == 1 then
                        table.insert(decoratives, {name = 'green-bush-mini', position = {pos_x, pos_y}, amount = 1})
                        decal_has_been_placed = false
                    end
                end
            end
        end
    end
    for _, deco in pairs(decoratives) do
        surface.create_decoratives {check_collision = false, decoratives = {deco}}
    end
end
