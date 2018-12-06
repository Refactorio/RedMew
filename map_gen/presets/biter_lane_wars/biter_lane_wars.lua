-- WORK IN PROGRESS

-- Read /presets/biter_lane_wars/info.lua for map premise.

--[[
TO DO:
- Game start GUI
- Setup teams
- Write market management code
- Set each force spawn point and enemy force spawn point
- Write a score board
- Write a starting GUI
- Set teams to spectators if more than 2 teams and 1 lose
- Add auto reset on game win condition
]]--

local b = require 'map_gen.shared.builders'
local event = require 'utils.event'
local ScenarioInfo = require 'features.gui.info'
local wave_number = 0

ScenarioInfo.set_map_name('Biter Lane Wars')
ScenarioInfo.set_map_description('Team lane defence map.')
ScenarioInfo.set_map_extra_info('- Send biters to your opponents using the market\n- Earn more gold per wave by sending more biters\n- Defend your smelter at all costs!')

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
local containers = b.circular_pattern(lane_container, 4, 220)   -- Change this to add more containers (and later teams)

local sea = b.change_tile(b.full_shape, true, 'water')          -- turn the void to water
sea = b.fish(sea, 0.00125)

local map = b.any{
    starting_area,
    containers,
    sea
}
map = b.apply_effect(map, no_resources)

local function on_tick(event)
    local game_tick = game.tick
    local wave_duration_secs = 60 --in seconds
    local wave_duration_ticks = wave_duration_secs * 60
    local surface = game.surfaces.nauvis

    --if game_tick % 60 == 49 then -- I don't know why I chose these tick multiples. Do I have to do different stuff on different ticks to avoid messing stuff up?
        -- Update the clock gui once per second
    --end

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

local function on_init()

    game.forces.player.research_all_technologies()

    local surface = game.surfaces.nauvis
    surface.map_gen_settings = {
        cliff_settings = {
            name = 'cliff',
            cliff_elevation_0 = 1024,   -- none https://lua-api.factorio.com/latest/Concepts.html#CliffPlacementSettings
            cliff_elevation_interval = 10
        },
    }


    -- for each team
        -- create a friendly force
        -- create an enemy biter force so we can set their attack position
        -- change the force respawn position
        --  global.teamname.set_spawn_position({0,26},global.surface)
    --end

    -- These are visual aids only and will change later to being procedurally generated for each team.
    surface.create_entity({name = 'electric-furnace',  position={0,50}})
    surface.create_entity({name = 'market',  position={0,60}})
    surface.create_entity({name = 'market',  position={10,55}})
    surface.create_entity({name = 'market',  position={-10,55}})

    surface.create_entity({name = 'electric-furnace',  position={0,-50}})
    surface.create_entity({name = 'market',  position={0,-60}})
    surface.create_entity({name = 'market',  position={10,-55}})
    surface.create_entity({name = 'market',  position={-10,-55}})

    surface.create_entity({name = 'electric-furnace',  position={50,0}})
    surface.create_entity({name = 'market',  position={60,0}})
    surface.create_entity({name = 'market',  position={55,10}})
    surface.create_entity({name = 'market',  position={55,-10}})

    surface.create_entity({name = 'electric-furnace',  position={-50,0}})
    surface.create_entity({name = 'market',  position={-60,0}})
    surface.create_entity({name = 'market',  position={-55,10}})
    surface.create_entity({name = 'market',  position={-55,-10}})

end
event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)

return map

