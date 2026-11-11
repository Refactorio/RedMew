-- Mosaic: a monumental mural of space and industry laid out in ore (see mosaic_layout.lua),
-- which says which main ore each tile gets. `config.main_ores_mosaic` overrides the layout's
-- defaults (the inks and their weights, the line ore, panel sizes...).
local b = require 'map_gen.shared.builders'
local Layout = require 'map_gen.maps.danger_ores.modules.mosaic_layout'

return function(config)
    local main_ores = config.main_ores
    local overrides = config.main_ores_mosaic or {}

    return function(tile_builder, ore_builder, spawn_shape, water_shape, random_gen)
        local shapes = {}
        for _, ore_data in ipairs(main_ores) do
            local land = tile_builder(ore_data.tiles)
            local ratios = ore_data.ratios
            local weighted = b.prepare_weighted_array(ratios)
            local ore = ore_builder(ore_data.name, ore_data.start, ratios, weighted)
            shapes[ore_data.name] = b.apply_entity(land, ore)
        end

        local options = {random = random_gen}
        for key, value in pairs(overrides) do
            options[key] = value
        end
        local layout = Layout.new(options)

        local used = {layout.settings.line_ink}
        for _, ink in ipairs(layout.settings.inks) do
            used[#used + 1] = ink[1]
        end
        for _, s in ipairs(layout.settings.spawn_symbols) do
            used[#used + 1] = s[2]
        end
        for _, name in ipairs(layout.settings.medallion_inks) do
            used[#used + 1] = name
        end
        for _, name in ipairs(used) do
            if not shapes[name] then
                error('Mosaic: ' .. name .. ' is not one of the main ores')
            end
        end

        local ore_at = layout.ore_at
        local function mosaic(x, y, world)
            return shapes[ore_at(x, y)](x, y, world)
        end

        return b.any {spawn_shape, water_shape, mosaic}
    end
end
