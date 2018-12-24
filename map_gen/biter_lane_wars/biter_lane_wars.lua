-- WORK IN PROGRESS

-- Read /presets/biter_lane_wars/info.lua for map premise.

--[[
TO DO:
- Setup teams
- Write market management code
- Set each force spawn point and enemy force spawn point
- Write a score board
- Write a starting GUI
- Set teams to spectators if more than 2 teams and 1 lose
- make biters drop coins
- Add auto reset on game win condition
- make the lanes fork shaped
]]--

local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local ScenarioInfo = require 'features.gui.info'
local wave_number = 0
require 'utils.table'
local Retailer = require 'features.retailer'
local format = 'string.format'

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

Event.add(Retailer.events.on_market_purchase, function (event)
    event.player.print(format('You\'ve bought %d of %s, costing a total of %d', event.count, event.item.name, event.item.price * event.count))
end)

--Event.add(
    -- Upon biter death
    -- Look up the type of biter that was killed
    -- Give the player that killed it gold coins as a reward. Will be balanced wrt to the biter type and the market prices.
    -- Makes staying back disadvantageous and makes some players get stronger than others
--end)

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

    game.create_force("team_1")
    game.create_force("team_2")
    game.create_force("spectator")

    -- eventually break out the following into its own file to tidy it up
    --require 'map_gen.presets.biter_lane_wars.market_items'
    -- setup the following as a table, then loop through and add them to retailer
    --return {        {name = ...},    }

    Retailer.set_item('items', {price = 5, name = 'raw-fish'})
     Retailer.set_item('items', {price = 10, name = 'steel-axe'})
     Retailer.set_item('items', {price = 10, name = 'submachine-gun'})
     Retailer.set_item('items', {price = 10, name = 'combat-shotgun'})
     Retailer.set_item('items', {price = 10, name = 'railgun'})
     Retailer.set_item('items', {price = 10, name = 'flamethrower'})
     Retailer.set_item('items', {price = 10, name = 'rocket-launcher'})
     Retailer.set_item('items', {price = 10, name = 'tank-cannon'})
     Retailer.set_item('items', {price = 10, name = 'tank-machine-gun'})
     Retailer.set_item('items', {price = 10, name = 'firearm-magazine'})
     Retailer.set_item('items', {price = 10, name = 'piercing-rounds-magazine'})
     Retailer.set_item('items', {price = 10, name = 'uranium-rounds-magazine'})
     Retailer.set_item('items', {price = 10, name = 'shotgun-shell'})
     Retailer.set_item('items', {price = 10, name = 'piercing-shotgun-shell'})
     Retailer.set_item('items', {price = 10, name = 'railgun-dart'})
     Retailer.set_item('items', {price = 10, name = 'flamethrower-ammo'})
     Retailer.set_item('items', {price = 10, name = 'rocket'})
     Retailer.set_item('items', {price = 10, name = 'explosive-rocket'})
     Retailer.set_item('items', {price = 10, name = 'atomic-bomb'})
     Retailer.set_item('items', {price = 10, name = 'cannon-shell'})
     Retailer.set_item('items', {price = 10, name = 'explosive-cannon-shell'})
     Retailer.set_item('items', {price = 10, name = 'explosive-uranium-cannon-shell'})
     Retailer.set_item('items', {price = 10, name = 'land-mine'})
     Retailer.set_item('items', {price = 10, name = 'grenade'})
     Retailer.set_item('items', {price = 10, name = 'cluster-grenade'})
     Retailer.set_item('items', {price = 10, name = 'slowdown-capsule'})
     Retailer.set_item('items', {price = 10, name = 'poison-capsule'})
     -- add more later

     -- Creep market items
    Retailer.set_item('creeps', {price = 10, name = 'raw-fish'})
    --local icon = require 'map_gen.presets.biter_lane_wars.assets.big-spitter.png'
    Retailer.set_item('creeps', {price = 5, name = 'grenade', sprite="entity/small-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'poison-capsule', sprite="entity/medium-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'atomic-bomb', sprite="entity/big-biter"})
    Retailer.set_item('creeps', {price = 5, name = 'rocket', sprite="entity/behemoth-biter"})
    Retailer.set_item('creeps', {price = 10, name = 'steel-axe'})
    Retailer.set_item('creeps', {price = 5, name = 'tank-cannon', sprite="entity/small-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'railgun', sprite="entity/medium-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'railgun-dart', sprite="entity/big-spitter"})
    Retailer.set_item('creeps', {price = 5, name = 'explosive-uranium-cannon-shell', sprite="entity/behemoth-spitter"})

     -- Tome market items
     Retailer.set_item('tomes', {price = 10, name = 'steel-axe'})

    --
     Retailer.set_market_group_label('items', 'Items Market')
     Retailer.set_market_group_label('creeps', 'Creeps Market')
     Retailer.set_market_group_label('tomes', 'Tomes Market')

    -- TEAM 1 BUILDINGS
    local item_market_1 = surface.create_entity({name = 'market',  position={0,60}})
    local creep_market_1 = surface.create_entity({name = 'market',  position={10,55}})
    local tomes_market_1 = surface.create_entity({name = 'market',  position={-10,55}})
    local furnace_1 = surface.create_entity({name = 'electric-furnace',  position={0,50}})

    item_market_1.destructible = false
    creep_market_1.destructible = false
    tomes_market_1.destructible = false
    Retailer.add_market('items', item_market_1)
    Retailer.add_market('creeps', creep_market_1)
    Retailer.add_market('tomes', tomes_market_1)
    Retailer.add_market('tomes', tomes_market_1)

    -- TEAM 2 BUILDINGS
    local item_market_2 = surface.create_entity({name = 'market',  position={0,-60}})
    local creep_market_2 = surface.create_entity({name = 'market',  position={10,-55}})
    local tomes_market_2 = surface.create_entity({name = 'market',  position={-10,-55}})
    local furnace_2 = surface.create_entity({name = 'electric-furnace',  position={0,-50}})
    item_market_2.destructible = false
    creep_market_2.destructible = false
    tomes_market_2.destructible = false
    Retailer.add_market('items', item_market_2)
    Retailer.add_market('creeps', creep_market_2)
    Retailer.add_market('tomes', tomes_market_2)

end

--local function on_player_joined_game(event)
    -- if in list of players, set force
    -- else set to spectator
--end

local function draw_gui()
    -- draw public gui
    -- if admin draw admin gui
        -- reset game
        -- add spectator to team, useful if someone quit
        -- force start

end

local function refresh_gui()
end


event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)

return map
