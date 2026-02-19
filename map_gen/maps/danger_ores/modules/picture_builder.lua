local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local math = require 'utils.math'
local random = math.random
local binary_search = table.binary_search
local bnot = bit32.bnot

local function from_name(tbl, name)
    for _, v in pairs(tbl) do
        if v.name == name then
            return v
        end
    end
end

local function ore_builder(ore_data)
    local weighted = b.prepare_weighted_array(ore_data.ratios)
    local ratios = ore_data.ratios
    local total = weighted.total

    return function(x, y, world)
        local i = random() * total
        local index = binary_search(weighted, i)
        if index < 0 then
            index = bnot(index)
        end

        local resource = ratios[index].resource
        local entity = resource(x, y, world)

        if entity then
            entity.enable_tree_removal = false
        end

        if entity.amount and entity.amount < 1 then
            entity.amount = 1
        end

        return entity
    end
end

---@field pic { height: number, width: number, data: table } - the preset data from a picture
---@field ores table - the ore configuration to be used
---@field func_map table[number, number] - maps values of the preset to a specific ore function
---@field tile_map? table[number, string] - maps values of the preset to a specific tile (custom)
return function(config)
    local pic = config.pic
    local ores = config.ores
    local func_map = config.func_map

    pic.func_map = {}
    pic.tile_map = config.tile_map

    for key, v in pairs(func_map) do
        pic.func_map[key] = ore_builder(from_name(ores, v))
    end

    return b.picture(b.decompress(pic))
end
