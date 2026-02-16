local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local math = require 'utils.math'
local random = math.random
local binary_search = table.binary_search
local bnot = bit32.bnot
local floor = math.floor

local function decompress(pic)
    local data = pic.data
    local width = pic.width
    local height = pic.height

    local uncompressed = {}

    for y = 1, height do
        local row = data[y]
        local u_row = {}
        uncompressed[y] = u_row
        local x = 1
        for index = 1, #row, 2 do
            local key = row[index]

            local count = row[index + 1]
            for _ = 1, count do
                u_row[x] = key
                x = x + 1
            end
        end
    end

    return {
        width = width,
        height = height,
        data = uncompressed,
        tile_map = pic.tile_map,
        func_map = pic.func_map
    }
end

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

local function picture(pic)
    local data = pic.data
    local width = pic.width
    local height = pic.height
    local func_map = pic.func_map
    local tile_map = pic.tile_map

    -- the plus one is because lua tables are one based.
    local half_width = floor(width / 2) + 1
    local half_height = floor(height / 2) + 1
    return function(x, y, world)
        x = floor(x)
        y = floor(y)
        local x2 = x + half_width
        local y2 = y + half_height

        if y2 > 0 and y2 <= height and x2 > 0 and x2 <= width then
            local key = data[y2][x2]
            local callback = func_map[key]
            local entity = callback and callback(x, y, world)
            if entity then
                return {
                    tile = tile_map[key],
                    entities = { entity }
                }
            else
                return tile_map[key]
            end
        else
            return false
        end
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
    pic.tile_map = config.tile_map or b.default_tile_map

    for key, v in pairs(func_map) do
        pic.func_map[key] = ore_builder(from_name(ores, v))
    end

    return picture(decompress(pic))
end
