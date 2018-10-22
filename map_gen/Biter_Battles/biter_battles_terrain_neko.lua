
local simplex_noise = require 'map_gen.shared.simplex_noise'
local Event = require 'utils.event'
biter_battles_terrain = {}

--no need to constantly work out each chunk
local radius = 24  --starting pond radius    
local radsquare = radius*radius
local ore_amount = 1400
    local ores = {"copper-ore", "iron-ore", "stone", "coal", "uranium-ore"}

-- /c game.forces["north"].chart(game.player.surface, {left_top = {x = -1024, y = -1024}, right_bottom = {x = 1024, y = 1024}})
    
local function on_chunk_generated(event)
    if not global.noise_seed then global.noise_seed = math.random(1,5000000) end
    local left_top = event.area.left_top    --decreased var calls in later loop with more direct 
    local surface = game.surfaces[1]    
    local noise = {}    
    
    local entities = surface.find_entities(event.area)
    for _, entity in pairs(entities) do
        if entity.type == "resource" then
            entity.destroy()
        end
    end
    
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos_x = left_top.x + x
            local pos_y = left_top.y + y                                                        
            --noise[1] = simplex_noise.d2(pos_x/350, pos_y/350,global.noise_seed)
            noise[1] = simplex_noise.d2(pos_x*0.008, pos_y*0.008,global.noise_seed)    --100
            noise[2] = simplex_noise.d2(pos_x*0.05, pos_y*0.05,global.noise_seed+10000)        
            noise[3] = noise[1] + noise[2] * 0.1            
                        
            --local xx = 1
            --for yy = 1, 17, 1 do
                --local z = (yy % 4) + 1
                --xx = xx - 0.010
                --if noise[3] > xx then
                if noise[3] > 0.65 then
                    local a = ore_amount * (1+(noise[2]*0.3))    --moved to when used
                    --local z = (yy % 4) + 1
                    noise[4] = simplex_noise.d2(pos_x*0.005, pos_y*0.005,global.noise_seed+5000)
                    noise[5] = simplex_noise.d2(pos_x*0.005, pos_y*0.005,global.noise_seed+3000)
                    local z = 2
                    
                    if noise[4] > 0.2 then
                        if noise[5] > 0.05 then
                            z = 3
                        elseif noise[5] < -0.05 then
                            z = 4
                        else
                            z = 5
                        end
                    elseif noise[4] < -0.2 then
                        if noise[5] > 0.05 then
                            z = 1
                        elseif noise[5] < -0.05 then
                            z = 2
                        else
                            z = 5
                        end
                    else
                        z = math.floor((noise[3]+noise[2]*0.1)* 40) % 4 + 1
                    end
                    
                    --if noise[4] > 0.0 and noise[4] < 0.05 then z = (math.floor((noise[3]+noise[2]*0.1)* 40) % 4) + 1 end
                    if surface.can_place_entity {name=ores[z], position={pos_x,pos_y}, amount=a} then
                        surface.create_entity {name=ores[z], position={pos_x,pos_y}, amount=a}
                    end
                    --break
                elseif noise[3] < -0.85 then
                    if math.random(1,250) == 1 and surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
                        surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount = math.random(140000,380000) }
                    end
                end                
            --end                        
        end                            
    end
    
    if left_top.y > 96 or left_top.y < -128 then return end    --tweaked range
    local tiles = {}
    local spawn_tile = surface.get_tile(game.forces.south.get_spawn_position(surface))    

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos_x = left_top.x + x
            local pos_y = left_top.y + y                                                        
            local tile_to_insert = false                
            local tile_distance_to_center = pos_x^2 + pos_y^2
            noise[4] = simplex_noise.d2(pos_x*0.0118, pos_y*0.0118,global.noise_seed+20000)        
            noise[5] = simplex_noise.d2(pos_x*0.15, pos_y*0.15,global.noise_seed+30000)    
            noise[7] = 1 + (noise[4]+(noise[5]*0.75))*0.1                        
            if pos_y >= ((global.horizontal_border_width/2)*-1)*noise[7] and pos_y <= (global.horizontal_border_width/2)*noise[7] then
                local entities = surface.find_entities({{pos_x, pos_y}, {pos_x+1, pos_y+1}})
                for _, e in pairs(entities) do
                    if e.type == "simple-entity" or e.type == "resource" or e.type == "tree" then
                        e.destroy()
                    end
                end                                
                tile_to_insert = "deepwater"
            else
                local t = surface.get_tile(pos_x,pos_y)
                if t.name == "deepwater" or t.name =="water" then                    
                    if tile_distance_to_center < 20000 then
                        if spawn_tile.name == "water" or spawn_tile.name == "deepwater" then 
                            tile_to_insert = "sand-1"
                        else
                            tile_to_insert = spawn_tile.name
                        end
                    end
                end
            end                    
            if tile_distance_to_center <= radsquare then
                    if tile_distance_to_center >= radsquare/10 then
                        tile_to_insert = "deepwater"
                    else
                        tile_to_insert = "sand-1"
                        if tile_distance_to_center >= radsquare/18 then
                            tile_to_insert = "refined-concrete"
                        end
                    end
            end            
            if tile_to_insert then table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) end
        end
    end                        
    surface.set_tiles(tiles,true)
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do            
            local pos_x = left_top.x + x
            local pos_y = left_top.y + y    
            local t = surface.get_tile(pos_x,pos_y)
            if t.name == "water" or t.name == "deepwater" or t.name == "water-green" then 
                if surface.can_place_entity{name="fish", position={pos_x,pos_y}} and math.random(1,40) == 1 then
                    surface.create_entity {name="fish", position={pos_x,pos_y}} 
                end            
            end            
        end
    end
end

local function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
    local x = position.x
    local y = position.y
    if not surface then surface = game.surfaces[1] end
    local scan_radius = 50
    if not tilename then return end
    if not mode then mode = "ball" end
    if not density then density = 1 end
    local cluster_tiles = {}
    local auto_correct = true
    
    local scanned_tile = surface.get_tile(x,y)
    if scanned_tile.name ~= tilename then
        table.insert(cluster_tiles, {name = tilename, position = {x,y}})
        surface.set_tiles(cluster_tiles,auto_correct)
        return true, x, y
    end
    
    local i = 2
    local r = 1        
    
    if mode == "ball" then
        if math.random(1,2) == 1 then 
            density = density * -1
        end
        r = math.random(1,4)
    end
    if mode == "line" then
        density = 1
        r = math.random(1,4)
    end
    if mode == "line_down" then
        density = density * -1
        r = math.random(1,4)
    end
    if mode == "line_up" then
        density = 1
        r = math.random(1,4)
    end
    if mode == "block" then
        r = 1
        density = 1
    end    
    
    if r == 1 then
        --start placing at -1,-1
        while i <= scan_radius do
            y = y - density                        
            x = x - density                
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)                
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                x = x + density
            end        
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                y = y + density
            end        
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                x = x - density
            end        
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
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
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end        
            for a = 1, i, 1 do
                y = y + density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end        
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end        
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
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
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                y = y + density
            end        
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                x = x - density
            end        
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
                y = y - density
            end
            for a = 1, i, 1 do                
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
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
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end        
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end        
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x + density
                local scanned_tile = surface.get_tile(x,y)
                if scanned_tile.name ~= tilename then    
                    table.insert(cluster_tiles, {name = tilename, position = {x,y}})
                    surface.set_tiles(cluster_tiles,auto_correct)
                    return true, x, y
                end
            end            
            i = i + 2
        end
    end    
    return false
end

local function create_tile_cluster(tilename,position,amount)
    local mode = "ball"
    local cluster_tiles = {}
    local surface = game.surfaces[1]
    local pos = position
    local x = pos.x
    local y = pos.y
    for i = 1, amount, 1 do
        local b,x,y = find_tile_placement_spot_around_target_position(tilename, pos, mode)
        if b == true then                        
            if 1 == math.random(1,16) then
                pos.x = x
                pos.y = y
            end            
        end
        if b == false then return false,x,y end
        if i >= amount then return true,x,y end
    end        
end

function biter_battles_terrain.generate_spawn_water_pond()
    local x = 1
    local surface = game.surfaces[1]
    for _, silo in pairs(global.rocket_silo) do
        local pos = {}
        local wreck_pos = {}
        pos["x"]=silo.position.x + 60*x
        pos["y"]=silo.position.y - 5*x
        wreck_pos["x"]=silo.position.x + 60*x
        wreck_pos["y"]=silo.position.y - 5*x
        create_tile_cluster("water-green",pos,450)            
        local p = surface.find_non_colliding_position("big-ship-wreck-1", {wreck_pos.x,wreck_pos.y-3*x}, 20,1)
        local e = surface.create_entity {name="big-ship-wreck-1", position=p, force=silo.force.name}
        e.insert({name = 'copper-cable', count = 7})
        e.insert({name = 'iron-stick', count = 3})        
        local p = surface.find_non_colliding_position("big-ship-wreck-3", {pos.x-3*x,pos.y}, 20,1)
        local e = surface.create_entity {name="big-ship-wreck-3", position=p, force=silo.force.name}                        
        e.insert({name = 'land-mine', count = 6})
        pos["x"]=silo.position.x - math.random(80,90)*x
        pos["y"]=silo.position.y - math.random(50,70)*x        
        create_tile_cluster("water-green",pos,300)
        local p = surface.find_non_colliding_position("big-ship-wreck-2", {pos.x+3*x,pos.y+1*x}, 20,1)
        local e = surface.create_entity {name="big-ship-wreck-2", position=p, force=silo.force.name}
        e.insert({name = 'empty-barrel', count = 1})
        e.insert({name = 'lubricant-barrel', count = 2})
        local p = surface.find_non_colliding_position("crude-oil", {pos.x-5*x,pos.y+5*x}, 50,1)
        local e = surface.create_entity {name="crude-oil", position=p, amount=225000}    
        x = -1
    end
end

function biter_battles_terrain.clear_spawn_ores()
    local surface = game.surfaces[1]            
    for x = -200,200,1 do
        for y = -200,200,1 do
            local tile_distance_to_center =  math.sqrt(x^2 + y^2)
            if tile_distance_to_center < 150 then
                local entities = surface.find_entities({{x, y}, {x+1, y+1}})
                for _, e in pairs(entities) do
                    if e.type == "resource" then
                        e.destroy()
                    end
                end                                                
            end
        end
    end
end

function biter_battles_terrain.generate_spawn_ores(ore_layout)        
    local surface = game.surfaces[1]
    local tiles = {}
    --generate ores around silos
    local ore_layout = "windows"
    --local ore_layout = "4squares"
    local ore_amount = 1000
            
    if ore_layout == "4squares" then
        local size = 22            
        for _, rocket_silo in pairs(global.rocket_silo) do
            local tiles = {}
            for x = (size+1)*-1, size+1, 1 do
                for y = (size+1)*-1, size+1, 1 do
                    table.insert(tiles, {name = "stone-path", position = {rocket_silo.position.x + x,rocket_silo.position.y + y}})                            
                end
            end
            surface.set_tiles(tiles,true)
            local entities = surface.find_entities({{(rocket_silo.position.x-4)-size/2, (rocket_silo.position.y-5)-size/2}, {rocket_silo.position.x+4+size/2, rocket_silo.position.y+5+size/2}})
            for _, entity in pairs(entities) do
                if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
                    entity.destroy()                    
                end
            end                    
        end                            
        for x = size*-1, size, 1 do
            for y = size*-1, size, 1 do                
                if x > 0 and y < 0 then
                    if surface.can_place_entity {name="stone", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="stone", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y < 0 then
                    if surface.can_place_entity {name="coal", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="coal", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y > 0 then
                    if surface.can_place_entity {name="copper-ore", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="copper-ore", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y > 0 then
                    if surface.can_place_entity {name="iron-ore", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="iron-ore", position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount}
                    end
                end                    
                if x < 0 and y > 0 then
                    if surface.can_place_entity {name="stone", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="stone", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y > 0 then
                    if surface.can_place_entity {name="coal", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="coal", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount}
                    end
                end
                if x > 0 and y < 0 then
                    if surface.can_place_entity {name="copper-ore", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="copper-ore", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount}
                    end
                end
                if x < 0 and y < 0 then
                    if surface.can_place_entity {name="iron-ore", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name="iron-ore", position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount}
                    end
                end
            end
        end
        for _, rocket_silo in pairs(global.rocket_silo) do
            local entities = surface.find_entities({{rocket_silo.position.x-5, rocket_silo.position.y-6}, {rocket_silo.position.x+5, rocket_silo.position.y+6}})
            for _, entity in pairs(entities) do
                if entity.type == "resource" then
                    entity.destroy()                    
                end
            end    
        end
    end
    
    if ore_layout == "windows" then
        for x = -24, 24, 1 do
            for y = -25, 24, 1 do
                table.insert(tiles, {name = "stone-path", position = {global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}})    
                table.insert(tiles, {name = "stone-path", position = {global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}})    
            end
        end
        surface.set_tiles(tiles,true)
        local ore = {"stone","stone","stone","stone","coal","coal","coal","coal","coal","copper-ore","copper-ore","copper-ore","copper-ore","copper-ore","iron-ore","iron-ore","iron-ore","iron-ore","iron-ore"}
        for z = 1, 19, 1 do
            for x = -4-z, 4+z, 1 do
                for y = -5-z, 4+z, 1 do                
                    if surface.can_place_entity {name=ore[z], position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name=ore[z], position={global.rocket_silo["south"].position.x + x,global.rocket_silo["south"].position.y + y}, amount=ore_amount}
                    end                
                end
            end
        end
        for z = 1, 19, 1 do
            for x = -4-z, 4+z, 1 do
                for y = -5-z, 4+z, 1 do                
                    if surface.can_place_entity {name=ore[z], position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount} then
                        surface.create_entity {name=ore[z], position={global.rocket_silo["north"].position.x + x,global.rocket_silo["north"].position.y + y}, amount=ore_amount}
                    end                
                end
            end
        end
    end
    
    for _, rocket_silo in pairs(global.rocket_silo) do
        local entities = surface.find_entities({{rocket_silo.position.x-4, rocket_silo.position.y-5}, {rocket_silo.position.x+4, rocket_silo.position.y+5}})
        for _, entity in pairs(entities) do
            if entity.type == "resource" then
                entity.destroy()                    
            end
        end    
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return biter_battles_ores
