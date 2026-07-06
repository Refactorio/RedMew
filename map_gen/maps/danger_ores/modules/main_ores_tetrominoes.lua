local b = require 'map_gen.shared.builders'
local Layout = require 'map_gen.maps.danger_ores.modules.tetromino_layout'
local palette = require 'map_gen.maps.danger_ores.config.tetromino_shapes'

local floor = math.floor

local CELL_SIZE = 64  -- tiles per grid cell; each tetromino is 4 cells (32 = 1 chunk; 64 = 2x larger, 48 = 1.5x)
local SUPER_TILE = 32 -- layout cells per super-tile; pattern repeats every SUPER_TILE*CELL_SIZE tiles

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

        local ore_grid = Layout.generate {
            size = SUPER_TILE,
            palette = palette,
            num_ores = #shapes,
            random = random_gen,
        }

        local function tetrominoes(x, y, world)
            local cx = floor(x / CELL_SIZE) % SUPER_TILE
            local cy = floor(y / CELL_SIZE) % SUPER_TILE
            local index = ore_grid[cx][cy]
            return shapes[index](x, y, world)
        end

        return b.any { spawn_shape, water_shape, tetrominoes }
    end
end
