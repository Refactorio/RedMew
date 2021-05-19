local Helper = require 'map_gen.maps.danger_ores.modules.helper'
local b = require 'map_gen.shared.builders'
local table = require 'utils.table'

local binary_search = table.binary_search
local bnot = bit32.bnot
local sqrt = math.sqrt
local floor = math.floor


return function(config)
    local main_ores = config.main_ores
    local main_ores_split_count = config.main_ores_split_count or 1

    main_ores = Helper.split_ore(main_ores, main_ores_split_count)

    local function condition_factory(ore_name)
      return function(x, y, _)
        local scale = config.circle_scale or 1
        --local randomize_scale = config.randomize_scale or false
        local ore_table = {}
        for _, ore_data in pairs(main_ores) do
          table.insert(ore_table, {name = ore_data.name, weight = ore_data.weight})
        end
        local weighted = b.prepare_weighted_array(ore_table)
        local i =  floor(sqrt(x * x + y * y) * scale) % weighted.total + 1
        local index = binary_search(weighted, i)
        if index < 0 then
            index = bnot(index)
        end
        return ore_table[index].name == ore_name
      end
    end

    return function(tile_builder, ore_builder, spawn_shape, water_shape, _)

      local shapes = {}
      for _, ore_data in pairs(main_ores) do
          local ore_name = ore_data.name
          local tiles = ore_data.tiles
          local land = tile_builder(tiles)

          local ratios = ore_data.ratios
          local weighted = b.prepare_weighted_array(ratios)
          local amount = ore_data.start

          local ore = ore_builder(ore_name, amount, ratios, weighted)
          local condition = condition_factory(config, ore_name)
          local shape = b.choose(condition, b.apply_entity(land, ore), b.empty_shape)
          table.insert(shapes, shape)
      end

      local ores = b.any(shapes)

      return b.any {spawn_shape, water_shape, ores}
    end
end
