require 'map_gen.shared.ent_functions'
local simplex_noise = require 'map_gen.shared.simplex_noise'
local Event = require 'utils.event'

local random = math.random
local sqrt = math.sqrt
local insert = table.insert

local biter_battles_terrain = {}

local function on_chunk_generated(event)
    if not global.noise_seed then global.noise_seed = random(1,5000000) end

    local surface = game.surfaces.battle_surface
    if not surface then return end

    local horizontal_border_width = global.horizontal_border_width
    local noise_seed = global.noise_seed
    local can_place_entity = surface.can_place_entity
    local create_entity = surface.create_entity
    local set_tiles = surface.set_tiles
    local get_tile = surface.get_tile

    local ore_amount = 2500
    local ores = {"copper-ore", "iron-ore", "stone", "coal"}

    local tiles = {}
    local fishies = {}

    local aa = 0.0113
    local bb = 21
    local xx = 1.1
    local cc = xx - (aa * bb)

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos_x = event.area.left_top.x + x
            local pos_y = event.area.left_top.y + y
            local tile_to_insert = false
            local entity_has_been_placed = false

            local noise = {}
            noise[1] = simplex_noise.d2(pos_x/250, pos_y/250,noise_seed)
            noise[2] = simplex_noise.d2(pos_x/75, pos_y/75,noise_seed+10000)
            noise[8] = simplex_noise.d2(pos_x/15, pos_y/15,noise_seed+40000)
            noise[3] = noise[1] + noise[2] * 0.2 + noise[8]*0.02

            noise[4] = simplex_noise.d2(pos_x/200, pos_y/200,noise_seed+15000)
            noise[5] = simplex_noise.d2(pos_x/20, pos_y/20,noise_seed+20000)
            noise[6] = simplex_noise.d2(pos_x/8, pos_y/8,noise_seed+25000)
            noise[7] = simplex_noise.d2(pos_x/400, pos_y/400,noise_seed+35000)
            local water_noise = noise[4] + (noise[6] * 0.006) + (noise[5] * 0.04)

            local a = ore_amount * (1+(noise[2]*0.3))
            xx = 1.1
            if noise[3] >= cc then
                for yy = 1, bb, 1 do
                    local z = (yy % 4) + 1
                    xx = xx - aa
                    if noise[3] > xx then
                        if can_place_entity {name=ores[z], position={pos_x,pos_y}, amount=a} then
                            create_entity {name=ores[z], position={pos_x,pos_y}, amount=a}
                        end
                        entity_has_been_placed = true
                        break
                    end
                end
            end
            if entity_has_been_placed == false then
                if water_noise < -0.92 and water_noise < noise[7] then
                    tile_to_insert = "water"
                end
                if water_noise < -0.97 and water_noise < noise[7] then
                    tile_to_insert = "deepwater"
                end
            end
            if tile_to_insert then
                insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
            end

            if tile_to_insert == "water" or tile_to_insert == "deepwater" and random(1,12) == 1 then
                insert(fishies, {pos_x,pos_y})
            end
        end
    end

    local south_spawn_position = game.forces.south.get_spawn_position(surface)
    if event.area.left_top.y < 160 or event.area.left_top.y > -192 then
        local spawn_tile = get_tile(south_spawn_position)
        local half_width = horizontal_border_width / 2

        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local pos_x = event.area.left_top.x + x
                local pos_y = event.area.left_top.y + y
                local tile_to_insert = false
                local tile_distance_to_center = pos_x^2 + pos_y^2

                local noise = {}
                noise[4] = simplex_noise.d2(pos_x/85, pos_y/85,noise_seed+20000)
                noise[5] = simplex_noise.d2(pos_x/7, pos_y/7,noise_seed+30000)
                noise[7] = 1 + (noise[4]+(noise[5]*0.75))*0.11
                if pos_y >= (half_width*-1)*noise[7] and pos_y <= half_width*noise[7] then
                    tile_to_insert = "deepwater"
                else
                    local t = get_tile(pos_x,pos_y)
                    if t.valid and (t.name == "deepwater" or t.name =="water") and tile_distance_to_center < 20000 then
                        if spawn_tile.name == "water" or spawn_tile.name == "deepwater" then
                            tile_to_insert = "sand-1"
                        else
                            tile_to_insert = spawn_tile.name
                        end
                    end
                end
                if tile_distance_to_center <= 576 then
                    if tile_distance_to_center >= 57.6 then
                        tile_to_insert = "deepwater"
                    else
                        tile_to_insert = "sand-1"
                        if tile_distance_to_center >= 32 then
                            tile_to_insert = "refined-concrete"
                        end
                    end
                end

                if tile_to_insert then
                    insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}})
                end

                if tile_to_insert == "deepwater" and random(1,35) == 1 then
                    insert(fishies, {pos_x,pos_y})
                end
            end
        end
    end

    if #tiles > 0 then
        set_tiles(tiles)
    end

    for _, position in pairs(fishies) do
        create_entity({name="fish", position = position})
    end
end

function biter_battles_terrain.generate_spawn_water_pond()
    local x = 1
    local surface = game.surfaces.battle_surface
    local find_non_colliding_position = surface.find_non_colliding_position
    local create_entity = surface.create_entity
    local get_tile = surface.get_tile
    local can_place_entity = surface.can_place_entity

    for _, silo in pairs(global.rocket_silo) do
        local silo_position_x = silo.position.x
        local silo_position_y = silo.position.y
        local silo_name = silo.force.name

        local pos = {}
        local wreck_pos = {}
        pos["x"] = silo_position_x + 60*x
        pos["y"] = silo_position_y - 5*x
        wreck_pos["x"] = silo_position_x + 60*x
        wreck_pos["y"] = silo_position_y - 5*x
        create_tile_cluster("water-green",pos,450)

        local p = find_non_colliding_position("big-ship-wreck-1", {wreck_pos.x,wreck_pos.y-3*x}, 20,1)
        local e = create_entity {name="big-ship-wreck-1", position=p, force=silo_name}
        e.insert({name = 'copper-cable', count = 7})
        e.insert({name = 'iron-stick', count = 3})

        local p = find_non_colliding_position("big-ship-wreck-3", {pos.x-3*x,pos.y}, 20,1)
        local e = create_entity {name="big-ship-wreck-3", position=p, force=silo_name}
        e.insert({name = 'land-mine', count = 6})
        pos["x"] = silo_position_x - random(80,90)*x
        pos["y"] = silo_position_y - random(50,70)*x
        create_tile_cluster("water-green",pos,300)

        local p = find_non_colliding_position("big-ship-wreck-2", {pos.x+3*x,pos.y+1*x}, 20,1)
        local e = create_entity {name="big-ship-wreck-2", position=p, force=silo_name}
        e.insert({name = 'empty-barrel', count = 1})
        e.insert({name = 'lubricant-barrel', count = 2})

        local p = find_non_colliding_position("crude-oil", {pos.x-5*x,pos.y+5*x}, 50,1)
        create_entity {name="crude-oil", position=p, amount=225000}
        x = -1
    end

    for x = -200, 200, 1 do
        for y = -200, 200, 1 do
            local t = get_tile(x,y)
            if t.name == "water-green" then
                if can_place_entity{name="fish", position={x,y}} and random(1,10) == 1 then
                    create_entity {name="fish", position={x,y}}
                end
            end
        end
    end
end

function biter_battles_terrain.clear_spawn_ores()
    local surface = game.surfaces.battle_surface
    local find_entities = surface.find_entities
    for x = -200,200,1 do
        for y = -200,200,1 do
            local tile_distance_to_center =  sqrt(x^2 + y^2)
            if tile_distance_to_center < 150 then
                local entities = find_entities({{x, y}, {x+1, y+1}})
                for _, e in pairs(entities) do
                    if e.type == "resource" then
                        e.destroy()
                    end
                end
            end
        end
    end
end

function biter_battles_terrain.generate_market()
    local surface = game.surfaces.battle_surface
    local find_non_colliding_position = surface.find_non_colliding_position
    local create_entity = surface.create_entity
    local find_entities = surface.find_entities
    local rocket_silos = global.rocket_silo

    for z = -1, 1, 2 do
        local f = "north"
        if z == 1 then f = "south" end
        local x = rocket_silos[f].position.x + (80 * z)
        local y = rocket_silos[f].position.y + (60 * z)
        local p = find_non_colliding_position("market",{x,y}, 20,1)
        local market = create_entity { name="market", position=p, force=f}
        local entities = find_entities({ { market.position.x-1, market.position.y-1}, { market.position.x+1, market.position.y+1}})
        for _, ee in pairs(entities) do
            if ee.type == "simple-entity" or ee.type == "resource" or ee.type == "tree" then
                ee.destroy()
            end
        end
        market.minable=false
        market.destructible=false
        local add_market_item = market.add_market_item
        add_market_item{price={{"raw-fish", 1}}, offer={ type="give-item", item="small-electric-pole", count=2}}
        add_market_item{price={{"raw-fish", 1}}, offer={ type="give-item", item="firearm-magazine", count=2}}
        add_market_item{price={{"raw-fish", 2}}, offer={ type="give-item", item="grenade"}}
        add_market_item{price={{"raw-fish", 2}}, offer={ type="give-item", item="land-mine", count=3}}
        add_market_item{price={{"raw-fish", 5}}, offer={ type="give-item", item="light-armor"}}
        add_market_item{price={{"raw-fish", 8}}, offer={ type="give-item", item="radar"}}
        add_market_item{price={{"iron-ore", 50}}, offer={ type="give-item", item="raw-fish"}}
        add_market_item{price={{"copper-ore", 50}}, offer={ type="give-item", item="raw-fish"}}
        add_market_item{price={{"stone", 50}}, offer={ type="give-item", item="raw-fish"}}
        add_market_item{price={{"coal", 50}}, offer={ type="give-item", item="raw-fish"}}
    end
end

function biter_battles_terrain.generate_spawn_ores(ore_layout)
    local surface = game.surfaces.battle_surface
    local find_entities = surface.find_entities
    local set_tiles = surface.set_tiles
    local create_entity = surface.create_entity
    local can_place_entity = surface.can_place_entity
    local rocket_silos = global.rocket_silo

    local silo_north = rocket_silos["north"]
    local silo_south = rocket_silos["south"]
    local silo_north_x = silo_north.position.x
    local silo_north_y = silo_north.position.y
    local silo_south_x = silo_south.position.x
    local silo_south_y = silo_south.position.y

    --generate ores around silos
    ore_layout = ore_layout or "windows"
    local ore_amount = 850

    if ore_layout == "4squares" then
        local size = 22
        for _, rocket_silo in pairs(rocket_silos) do
            local silo_pos = rocket_silo.position
            local silo_x = silo_pos.x
            local silo_y = silo_pos.y

            local tiles = {}
            for x = (size+1)*-1, size+1, 1 do
                for y = (size+1)*-1, size+1, 1 do
                    insert(tiles, {name = "stone-path", position = {silo_x + x,silo_y + y}})
                end
            end
            set_tiles(tiles,true)
            local entities = find_entities({{(silo_x-4)-size/2, (silo_y-5)-size/2}, {silo_x+4+size/2, silo_y+5+size/2}})
            for _, entity in pairs(entities) do
                if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
                    entity.destroy()
                end
            end
        end

        for x = size*-1, size, 1 do
            for y = size*-1, size, 1 do
                if x > 0 and y < 0 then
                    if can_place_entity {name="stone", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount} then
                        create_entity {name="stone", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y < 0 then
                    if can_place_entity {name="coal", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount} then
                        create_entity {name="coal", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y > 0 then
                    if can_place_entity {name="copper-ore", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount} then
                        create_entity {name="copper-ore", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y > 0 then
                    if can_place_entity {name="iron-ore", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount} then
                        create_entity {name="iron-ore", position={silo_south_x + x,silo_south_y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y > 0 then
                    if can_place_entity {name="stone", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount} then
                        create_entity {name="stone", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y > 0 then
                    if can_place_entity {name="coal", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount} then
                        create_entity {name="coal", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y < 0 then
                    if can_place_entity {name="copper-ore", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount} then
                        create_entity {name="copper-ore", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y < 0 then
                    if can_place_entity {name="iron-ore", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount} then
                        create_entity {name="iron-ore", position={silo_north_x + x,silo_north_y + y}, amount=ore_amount}
                    end
                end
            end
        end
        for _, rocket_silo in pairs(rocket_silos) do
            local silo_pos = rocket_silo.position
            local silo_x = silo_pos.x
            local silo_y = silo_pos.y
            local entities = find_entities({{silo_x-5, silo_y-6}, {silo_x+5, silo_y+6}})
            for _, entity in pairs(entities) do
                if entity.type == "resource" then
                    entity.destroy()
                end
            end
        end
    end

    if ore_layout == "windows" then
        local tiles = {}

        local m1 = 0.09
        local m2 = 0
        local m3 = 1
        local m4 = 23

        for x = m4*-1, m4, 1 do
            local noise = simplex_noise.d2(x*m1, 1*m1,global.noise_seed+50000)
            noise = noise*m2 + m3
            for y = (m4+1)*-1*noise, m4*noise, 1 do
                insert(tiles, {name = "stone-path", position = {silo_north_x + x,silo_north_y + y}})
            end
            local noise = simplex_noise.d2(x*m1, 1*m1,global.noise_seed+60000)
            noise = noise*m2 + m3
            for y = (m4+1)*-1*noise, m4*noise, 1 do
                insert(tiles, {name = "stone-path", position = {silo_south_x + x,silo_south_y + y}})
            end
        end
        for y = (m4+1)*-1, m4, 1 do
            local noise = simplex_noise.d2(y*m1, 1*m1,global.noise_seed+50000)
            noise = noise*m2 + m3
            for x = m4*-1*noise, m4*noise, 1 do
                insert(tiles, {name = "stone-path", position = {silo_north_x + x,silo_north_y + y}})
            end
            local noise = simplex_noise.d2(y*m1, 1*m1,global.noise_seed+60000)
            noise = noise*m2 + m3
            for x = m4*-1*noise, m4*noise, 1 do
                insert(tiles, {name = "stone-path", position = {silo_south_x + x,silo_south_y + y}})
            end
        end
        set_tiles(tiles)
        local ore = {"stone","stone","stone","stone","coal","coal","coal","coal","coal","copper-ore","copper-ore","copper-ore","copper-ore","copper-ore","iron-ore","iron-ore","iron-ore","iron-ore","iron-ore"}
        for z = 1, 19, 1 do
            for x = -4-z, 4+z, 1 do
                for y = -5-z, 4+z, 1 do
                    if can_place_entity {name=ore[z], position={silo_south_x + x,silo_south_y + y}, amount=ore_amount} then
                        create_entity {name=ore[z], position={silo_south_x + x,silo_south_y + y}, amount=ore_amount}
                    end
                end
            end
        end
        for z = 1, 19, 1 do
            for x = -4-z, 4+z, 1 do
                for y = -5-z, 4+z, 1 do
                    if can_place_entity {name=ore[z], position={silo_north_x + x,silo_north_y + y}, amount=ore_amount} then
                        create_entity {name=ore[z], position={silo_north_x + x,silo_north_y + y}, amount=ore_amount}
                    end
                end
            end
        end
    end

    for _, rocket_silo in pairs(rocket_silos) do
        local silo_pos = rocket_silo.position
        local silo_x = silo_pos.x
        local silo_y = silo_pos.y
        local entities = find_entities({{silo_x-4, silo_y-5}, {silo_x+4, silo_y+5}})
        for _, entity in pairs(entities) do
            if entity.type == "resource" then
                entity.destroy()
            end
        end
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return biter_battles_terrain
