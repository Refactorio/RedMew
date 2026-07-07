local b = require 'map_gen.shared.builders'
local Layout = require 'map_gen.maps.danger_ores.modules.voronoi_layout'

local CELL_SIZE = 32     -- tiles per cell-space unit (only sets the scale; boundaries are smooth)
local SUPER_TILE = 64    -- cell-space units per super-tile side; repeats every SUPER_TILE*CELL_SIZE tiles
local SEED_SPACING = 4   -- cell-space units between seeds; avg cell ~ SEED_SPACING*CELL_SIZE tiles (~128)
local RELAXATION = 2     -- Lloyd passes: 0 = jittered, 2-3 = even/relaxed

return function(config)
    local main_ores = config.main_ores

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local shapes = {}
        for _, ore_data in ipairs(main_ores) do
            local land = tile_builder(ore_data.tiles)
            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local ore = ore_builder(ore_data.name, ore_data.start, ratios, weighted)
            shapes[#shapes + 1] = b.apply_entity(land, ore)
        end

        local layout = Layout.build {
            size = SUPER_TILE,
            spacing = SEED_SPACING,
            relaxation = RELAXATION,
            num_ores = #shapes,
            random = random_gen,
        }

        local function voronoi(x, y, world)
            -- continuous cell-space coords -> smooth (tile-resolution) Voronoi boundaries
            local fx = (x / CELL_SIZE) % SUPER_TILE
            local fy = (y / CELL_SIZE) % SUPER_TILE
            return shapes[Layout.ore_at(layout, fx, fy)](x, y, world)
        end

        return b.any { spawn_shape, water_shape, voronoi }
    end
end
