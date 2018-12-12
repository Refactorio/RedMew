local perlin = require 'map_gen.shared.perlin_noise'
local simplex = require 'map_gen.shared.simplex_noise'

local tree_to_place = {'dry-tree', 'dry-hairy-tree', 'tree-06', 'tree-06', 'tree-01', 'tree-02', 'tree-03'}

function run_terrain_module(event)
    if not global.terrain_seed_A then
        global.terrain_seed_A = math.random(10, 10000)
    end
    if not global.terrain_seed_B then
        global.terrain_seed_B = math.random(10, 10000)
    end

    local area = event.area
    local surface = event.surface
    local tiles = {}
    local tileswater = {}

    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        --if entity.type == "simple-entity" or entity.type == "resource" or entity.type == "tree" then
        if entity.type == 'simple-entity' or entity.type == 'tree' then
            --end
            entity.destroy()
        elseif (run_ores_module ~= nil and entity.type == 'resource') then
            entity.destroy()
        end
    end

    local top_left = area.left_top --make a more direct reference

    --do it only per chunk, cause cheaper than every square, and who care anyway.
    --local distance_bonus = 200 + math.sqrt(top_left.x*top_left.x + top_left.y*top_left.y) * 0.2

    --for x = 0, 31, 1 do
    --  for y = 0, 31, 1 do

    --game.print(top_left.x .."-" ..top_left.y .. " to " .. area.right_bottom.x .. "-" .. area.right_bottom.y)

    for x = top_left.x - 1, top_left.x + 32 do
        for y = top_left.y - 1, top_left.y + 32 do
            --local pos_x = top_left.x + x
            --local pos_y = top_left.y + y
            local tile = surface.get_tile(x, y)

            if tile.name ~= 'out-of-map' then
                local tile_to_insert = 'grass-3'

                local wiggle = 50 + perlin.noise((x * 0.005), (y * 0.005), global.terrain_seed_A + 71) * 60
                local terrain_A = perlin.noise((x * 0.005), (y * 0.005), global.terrain_seed_A + 19) * wiggle --For determining where water is
                local terrain_sqr = terrain_A * terrain_A --we can use this again to mess with other layers as well
                local terrain_D = 10 + perlin.noise((x * 0.001), (y * 0.001), global.terrain_seed_A + 5) * wiggle --terrain layer

                --local wiggle = 50 + Simplex.d2((x*0.005),(y*0.005),global.terrain_seed_A + 71) * 60
                --local terrain_A = Simplex.d2((x*0.005),(y*0.005),global.terrain_seed_A + 19) * wiggle --For determining where water is
                --local terrain_sqr = terrain_A * terrain_A --we can use this again to mess with other layers as well
                --local terrain_D = 10 + Simplex.d2((x*0.001),(y*0.001),global.terrain_seed_A + 5) * wiggle --terrain layer

                if terrain_sqr < 50 then --Main water areas
                    --local deep = (terrain_sqr < 20) and true or false
                    terrain_A = perlin.noise((x * 0.01), (y * 0.01), global.terrain_seed_A + 31) * 90 + (wiggle * -0.2) --we only gen this when we consider placing water
                    --terrain_A = Simplex.d2((x*0.01),(y*0.01),global.terrain_seed_A + 31) * 90 + (wiggle * -0.2)   --we only gen this when we consider placing water

                    if terrain_A * terrain_A > 40 then --creates random bridges over the water by overlapping with another noise layer
                        --table.insert(tileswater, {name = "water", position = {x,y}})
                        --table.insert(tileswater, {name = "water", position = {x+1,y}})
                        --table.insert(tileswater, {name = "water", position = {x,y+1}})
                        --table.insert(tileswater, {name = "water", position = {x+1,y+1}})
                        tile_to_insert = 'water'
                    else
                        if terrain_D >= 20 then
                            tile_to_insert = 'sand-1'
                        end
                    end
                elseif terrain_sqr > 70 then
                    wiggle = 100 + perlin.noise((x * 0.01), (y * 0.01), global.terrain_seed_B + 41) * 60
                    local terrain_C = perlin.noise((x * 0.02), (y * 0.02), global.terrain_seed_A + 13) * wiggle --tree layer

                    --wiggle = 100 + Simplex.d2((x*0.01),(y*0.01),global.terrain_seed_B + 41) * 60
                    --local terrain_C = Simplex.d2((x*0.02),(y*0.02),global.terrain_seed_A + 13) * wiggle   --tree layer

                    --if surface.can_place_entity {name="stone", position={x,y}} then
                    --  surface.create_entity {name="stone", position={x,y}, amount=math.floor(terrain_sqr)}
                    --end

                    if run_ores_module ~= nil then
                        run_ores_module_setup()
                        if x > top_left.x - 1 and x < top_left.x + 32 and y > top_left.y - 1 and y < top_left.y + 32 then
                            run_ores_module_tile(surface, x, y)
                        end
                    end

                    --if terrain_B > 35 then    --we place ores
                    --  local a = 5
                    --
                    --  if terrain_B < 76 then a = math.floor(terrain_B*0.75 + terrain_C*0.5) % 4 + 1 end   --if its not super high we place normal ores
                    --
                    --  local res_amount = distance_bonus + terrain_sqr * 0.1
                    --  res_amount = math.floor(res_amount * random_dense[a])
                    --
                    --  if surface.can_place_entity {name=random_ores[a], position={pos_x,pos_y}} then
                    --      surface.create_entity {name=random_ores[a], position={pos_x,pos_y}, amount=res_amount}
                    --  end
                    --end

                    --wiggle = 100 + perlin.noise((pos_x*0.02),(pos_y*0.02),global.terrain_seed_B + 71) * 60

                    if terrain_D < 20 then
                        if terrain_C < 4 then --we set grass-1 around near forest areas
                            tile_to_insert = 'grass-1'

                            if terrain_C < -20 and math.random(1, 3) == 1 then --dense trees
                                local treenum = math.random(3, 7)
                                if surface.can_place_entity {name = tree_to_place[treenum], position = {x, y}} then
                                    surface.create_entity {name = tree_to_place[treenum], position = {x, y}}
                                end
                            else
                                if terrain_C < 0 and math.random(1, 7) == 1 then --less dense trees
                                    local treenum = math.random(3, 5)
                                    if surface.can_place_entity {name = tree_to_place[treenum], position = {x, y}} then
                                        surface.create_entity {name = tree_to_place[treenum], position = {x, y}}
                                    end
                                end
                            end
                        end
                    else
                        if terrain_D < 30 then
                            tile_to_insert = 'sand-1'

                            if terrain_C < -20 and math.random(1, 7) == 1 then --dense trees
                                local treenum = math.random(1, 3)
                                if surface.can_place_entity {name = tree_to_place[treenum], position = {x, y}} then
                                    surface.create_entity {name = tree_to_place[treenum], position = {x, y}}
                                end
                            elseif terrain_C < 0 and math.random(1, 13) == 1 then --less dense trees
                                local treenum = math.random(1, 2)
                                if surface.can_place_entity {name = tree_to_place[treenum], position = {x, y}} then
                                    surface.create_entity {name = tree_to_place[treenum], position = {x, y}}
                                end
                            end
                        else
                            --if terrain_C > 40 and math.random(1,200) == 1 and surface.can_place_entity {name="crude-oil", position={pos_x,pos_y}} then
                            --  surface.create_entity {name="crude-oil", position={pos_x,pos_y}, amount = math.random(20000,60000) +distance_bonus* 2000 }
                            --end
                            tile_to_insert = 'sand-3'
                        end
                    end

                    if
                        math.floor(terrain_D) % 5 == 1 and math.random(1, 70) == 1 and
                            surface.can_place_entity {name = 'rock-big', position = {x, y}}
                     then
                        surface.create_entity {name = 'rock-big', position = {x, y}}
                    end
                else
                    if terrain_D >= 20 then
                        if terrain_D < 30 then
                            tile_to_insert = 'sand-1'
                        else
                            tile_to_insert = 'sand-3'
                        end
                    end
                end

                --if tile_to_insert == "water" then
                --table.insert(tileswater, {name = tile_to_insert, position = {x,y}})
                --else
                table.insert(tiles, {name = tile_to_insert, position = {x, y}})
            --end
            end
        end
    end
    --game.print("break end")
    --game.print(lowest .. " to " .. highest)

    surface.set_tiles(tiles, true)
    --surface.set_tiles(tileswater,true)
end
