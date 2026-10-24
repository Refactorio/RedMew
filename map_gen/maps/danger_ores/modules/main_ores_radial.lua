-- Main ores in sectors, like main_ores.lua, but each sector's size changes with the distance from
-- spawn (radial_sectors_layout.lua). config.main_ores_radial:
--   {from = 200, to = 300, inner = {['iron-ore'] = 51, ...}, outer = {['iron-ore'] = 15, ...}}
-- with a weight for every ore in config.main_ores. config.main_ores_split_count repeats the
-- pattern around the circle, as in main_ores.lua.
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local Layout = require 'map_gen.maps.danger_ores.modules.radial_sectors_layout'

return function(config)
    local main_ores = config.main_ores
    local radial = config.main_ores_radial
    local shuffle_order = config.main_ores_shuffle_order
    local main_ores_rotate = config.main_ores_rotate or 0
    local split_count = config.main_ores_split_count or 1

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local sectors = {}

        for _, ore_data in pairs(main_ores) do
            local land = tile_builder(ore_data.tiles)
            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local ore = ore_builder(ore_data.name, ore_data.start, ratios, weighted)

            sectors[#sectors + 1] = {name = ore_data.name, shape = b.apply_entity(land, ore)}
        end

        if shuffle_order then
            table.shuffle_table(sectors, random_gen)
        end

        -- Repeat the shuffled order rather than shuffling the copies, so neighbours never share
        -- an ore; more, narrower sectors also bend less as their sizes change.
        local count = #sectors
        for copy = 1, split_count - 1 do
            for i = 1, count do
                sectors[copy * count + i] = sectors[i]
            end
        end

        local layout = {from = radial.from, to = radial.to, inner = {}, outer = {}}
        for i, sector in ipairs(sectors) do
            layout.inner[i] = radial.inner[sector.name]
            layout.outer[i] = radial.outer[sector.name]
        end

        local function ores(x, y, world)
            return sectors[Layout.sector_at(layout, x, y)].shape(x, y, world)
        end

        local shape = ores
        if main_ores_rotate ~= 0 then
            shape = b.rotate(shape, math.rad(main_ores_rotate))
        end

        return b.any {spawn_shape, water_shape, shape}
    end
end
