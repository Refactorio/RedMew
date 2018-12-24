--[[
    TO DO:
    - make the lanes fork shaped
]]

--- Creates everything needed on the surface for the play field
-- will call redmew_surface to gen the surface itself

-- Dependencies
local RS = require 'map_gen.shared.redmew_surface'
local b = require 'map_gen.shared.builders'

-- Localise globals
local BLW = global.map.blw
local teams = BLW.teams

RS.map_gen_settings = require 'resources.map_gen_settings'.no_cliffs_trees_ores_water

-- for each team, create buildings
for _, team in pairs(teams) do
    local item_market = surface.create_entity({name = 'market',  position={0,60}})
    local creep_market = surface.create_entity({name = 'market',  position={10,55}})
    local tomes_market = surface.create_entity({name = 'market',  position={-10,55}})
    local furnace = surface.create_entity({name = 'electric-furnace',  position={0,50}})

    item_market.destructible = false
    creep_market.destructible = false
    tomes_market.destructible = false
    Retailer.add_market('items', item_market)
    Retailer.add_market('creeps', creep_market)
    Retailer.add_market('tomes', tomes_market)
end

-- no_resources seems like it should be inside builders or some other shared library
local function no_resources(_, _, world, tile)
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'resource', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'tree', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'simple-entity', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end
    for _, e in ipairs(
        world.surface.find_entities_filtered(
            {type = 'cliff', area = {{world.x, world.y}, {world.x + 1, world.y + 1}}}
        )
    ) do
        e.destroy()
    end

    return tile
end

-- MAP GENERATION
local grass_circle = b.circle(20)
grass_circle = b.change_tile(grass_circle, true, 'grass-1')
local sand_circle = b.circle(22)
sand_circle = b.change_tile(sand_circle, true, 'sand-1')

local starting_area = b.any{
    grass_circle,
    sand_circle
}

local lane_background = b.rectangle(50,200)
lane_background = b.change_tile(lane_background, true, 'grass-1')
local small_rectangle = b.rectangle(44,26)
local spawn_area = b.change_tile(small_rectangle, true, 'hazard-concrete-left')
local market_area = b.change_tile(small_rectangle, true, 'concrete')
local lane_container = b.any{
    b.translate(spawn_area, 0, 83),
    b.translate(market_area, 0, -83),
    lane_background
}
lane_container = b.translate(lane_container,0,-80)
local containers = b.circular_pattern(lane_container, 2, 220)   -- Change this to add more containers (and later teams)

local sea = b.change_tile(b.full_shape, true, 'water')          -- turn the void to water
sea = b.fish(sea, 0.00125)

local map = b.any{
    starting_area,
    containers,
    sea
}
map = b.apply_effect(map, no_resources)

local function on_tick(Event)
    local game_tick = game.tick
    local wave_duration_secs = 60 --in seconds
    local wave_duration_ticks = wave_duration_secs * 60
    local surface = game.surfaces.nauvis

    --if game_tick % 60 == 49 then -- I don't know why I chose these tick multiples. Do I have to do different stuff on different ticks to avoid messing stuff up?
        -- Update the clock gui once per second
    --end

    -- WAVE EVENTS
    if game_tick % wave_duration_ticks == 50 then
        wave_number = wave_number + 1
        game.print('Wave ' .. wave_number .. ' is starting. Prepare yourselves!')
        -- For each team
            -- Spawn in the right amount of biters in the correct position
            for _ = 1, 20 do
                local p = surface.find_non_colliding_position('small-biter', {-60,0}, 30, 1)
                if p then
                    surface.create_entity {name = 'small-biter', position={-220,0}}
                end
              end
            -- Force the biters to attack the respective player team
            -- Give each team member their team gold
            -- Update the GUI with the wave number
        -- end
    end
end

return map
