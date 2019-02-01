local perlin = require 'map_gen.shared.perlin_noise'
local Global = require 'utils.global'

local seed_a
local seed_b

Global.register_init(
    {},
    function(tbl)
        tbl.seed_a = math.random(10, 10000)
        tbl.seed_b = math.random(10, 10000)
    end,
    function(tbl)
        seed_a = tbl.seed_a
        seed_b = tbl.seed_b
    end
)

local tree_to_place = {'dry-tree', 'dry-hairy-tree', 'tree-06', 'tree-06', 'tree-01', 'tree-02', 'tree-03'}

local types = {'simple-entity', 'tree'}

local function run_terrain_module(x, y, world)
    local surface = world.surface

    local wx, wy = world.x, world.y
    local pos = {wx, wy}

    local area = {pos, {wx + 1, wy + 1}}
    local es = surface.find_entities_filtered({area = area, type = types})
    for i = 1, #es do
        es[i].destroy()
    end

    local tile_to_insert = 'grass-3'

    local wiggle = 50 + perlin.noise((x * 0.005), (y * 0.005), seed_a + 71) * 60
    local terrain_A = perlin.noise((x * 0.005), (y * 0.005), seed_a + 19) * wiggle --For determining where water is
    local terrain_sqr = terrain_A * terrain_A --we can use this again to mess with other layers as well
    local terrain_D = 10 + perlin.noise((x * 0.001), (y * 0.001), seed_a + 5) * wiggle --terrain layer

    if terrain_sqr < 50 then --Main water areas
        terrain_A = perlin.noise((x * 0.01), (y * 0.01), seed_a + 31) * 90 + (wiggle * -0.2) --we only gen this when we consider placing water

        if terrain_A * terrain_A > 40 then --creates random bridges over the water by overlapping with another noise layer
            tile_to_insert = 'water'
        else
            if terrain_D >= 20 then
                tile_to_insert = 'sand-1'
            end
        end
    elseif terrain_sqr > 70 then
        wiggle = 100 + perlin.noise((x * 0.01), (y * 0.01), seed_b + 41) * 60
        local terrain_C = perlin.noise((x * 0.02), (y * 0.02), seed_a + 13) * wiggle --tree layer

        if terrain_D < 20 then
            if terrain_C < 4 then --we set grass-1 around near forest areas
                tile_to_insert = 'grass-1'

                if terrain_C < -20 and math.random(1, 3) == 1 then --dense trees
                    local treenum = math.random(3, 7)
                    if surface.can_place_entity {name = tree_to_place[treenum], position = pos} then
                        surface.create_entity {name = tree_to_place[treenum], position = pos}
                    end
                else
                    if terrain_C < 0 and math.random(1, 7) == 1 then --less dense trees
                        local treenum = math.random(3, 5)
                        if surface.can_place_entity {name = tree_to_place[treenum], position = pos} then
                            surface.create_entity {name = tree_to_place[treenum], position = pos}
                        end
                    end
                end
            end
        else
            if terrain_D < 30 then
                tile_to_insert = 'sand-1'

                if terrain_C < -20 and math.random(1, 7) == 1 then --dense trees
                    local treenum = math.random(1, 3)
                    if surface.can_place_entity {name = tree_to_place[treenum], position = pos} then
                        surface.create_entity {name = tree_to_place[treenum], position = pos}
                    end
                elseif terrain_C < 0 and math.random(1, 13) == 1 then --less dense trees
                    local treenum = math.random(1, 2)
                    if surface.can_place_entity {name = tree_to_place[treenum], position = pos} then
                        surface.create_entity {name = tree_to_place[treenum], position = pos}
                    end
                end
            else
                tile_to_insert = 'sand-3'
            end
        end

        if
            math.floor(terrain_D) % 5 == 1 and math.random(1, 70) == 1 and
                surface.can_place_entity {name = 'rock-big', position = pos}
         then
            surface.create_entity {name = 'rock-big', position = pos}
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

    return tile_to_insert
end

return run_terrain_module
