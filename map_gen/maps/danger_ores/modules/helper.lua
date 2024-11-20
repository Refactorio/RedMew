local MGSP = require 'resources.map_gen_settings'

local Public = {}

function Public.split_ore(ores, split_count)
    local new_ores = {}
    for _ = 1, split_count do
        for _, ore in pairs(ores) do
            new_ores[#new_ores + 1] = ore
        end
    end
    return new_ores
end

function Public.ore_oil_none(resource_list)
    if not resource_list then
        return MGSP.ore_oil_none
    end
    local ore_oil_none = {}
    for _, v in pairs(resource_list) do
        ore_oil_none[v] = { frequency = 1, richness = 1, size = 0 }
    end
    return { autoplace_controls = ore_oil_none }
end

function Public.empty_map_settings(resource_list)
    return {
        MGSP.grass_only,
        MGSP.enable_water,
        MGSP.starting_area_very_low,
        MGSP.enemy_none,
        MGSP.cliff_none,
        MGSP.tree_none,
        { terrain_segmentation = 'normal', water = 'normal' },
        Public.ore_oil_none(resource_list)
    }
end

return Public