local perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

local block_size = 1 -- in tiles
local start_size = 64 -- in blocks
local strike_time = 1 -- in ticks

-- dud blocks don't spawn meteors, with a block_weight = 1 and dud weight = 3, every 3 out of 4 blocks will be a dud block
local block_weight = 1
local dud_weight = 0
local min_blocks_in_list = 10 -- no dud meteors if the number of blocks in the list is less than or equal to this

global.blocks = nil
global.used_blocks = nil
global.strike_time = strike_time
global.weight_count = 0

local half_start_size = (start_size * block_size) / 2
local total_weight = block_weight + dud_weight

local function init_blocks()
    local blocks = {}
    local used_blocks = {}
    local half = start_size / 2
    for i = -half, half - 1 do
        table.insert(blocks, {x = i, y = -half - 1})
        used_blocks[i .. ',' .. (-half - 1)] = true
        table.insert(blocks, {x = i, y = half})
        used_blocks[i .. ',' .. half] = true
        table.insert(blocks, {x = -half - 1, y = i})
        used_blocks[(-half - 1) .. ',' .. i] = true
        table.insert(blocks, {x = half, y = i})
        used_blocks[half .. ',' .. i] = true

        for j = -half, half - 1 do
            used_blocks[i .. ',' .. j] = true
        end
    end

    global.blocks = blocks
    global.used_blocks = used_blocks
end

local function get_resource(x, y)
    local value = perlin.noise(x / 16, y / 16)
    value = value + 1
    value = value * 500

    local name

    if value < 450 then
        return nil
    elseif value < 550 then
        name = 'iron-ore'
    elseif value < 650 then
        name = 'copper-ore'
    elseif value < 750 then
        name = 'coal'
    elseif value < 850 then
        name = 'stone'
    else
        return nil
    end

    value = perlin.noise(y / 64, x / 64)
    value = value + 1
    value = value * 500

    return {name = name, position = {x, y}, amount = value}
end

function run_combined_module(event) -- luacheck: globals run_combined_module
    if not global.blocks then
        init_blocks()
    end

    local area = event.area
    local surface = event.surface
    local top_x = area.left_top.x
    local top_y = area.left_top.y

    local tiles = {}
    local entities = {}

    for y = top_y, top_y + 31 do
        for x = top_x, top_x + 31 do
            if -x > half_start_size or x >= half_start_size or -y > half_start_size or y >= half_start_size then
                table.insert(tiles, {name = 'out-of-map', position = {x, y}})
            end

            local e = get_resource(x, y)
            if e then
                table.insert(entities, e)
            end
        end
    end

    surface.set_tiles(tiles, false)

    for _, e in ipairs(entities) do
        if surface.can_place_entity(e) then
            surface.create_entity(e)
        end
    end
end

local function get_block()
    local blocks = global.blocks
    local count = global.weight_count
    while count >= block_weight and count < total_weight and #blocks > min_blocks_in_list do
        local index = math.random(#blocks)
        table.remove(blocks, index)
        count = count + 1
    end

    if count < block_weight then
        count = count + 1
    end

    if count == total_weight then
        global.weight_count = 0
    else
        global.weight_count = count
    end

    local index = math.random(#blocks)
    return table.remove(blocks, index)
end

local function do_strike()
    local block = get_block()

    local function add(x, y)
        local key = x .. ',' .. y
        if not global.used_blocks[key] then
            table.insert(global.blocks, {x = x, y = y})
            global.used_blocks[key] = true
        end
    end

    add(block.x, block.y - 1)
    add(block.x + 1, block.y)
    add(block.x, block.y + 1)
    add(block.x - 1, block.y)

    local tiles = {}
    local bx = block.x * block_size
    local by = block.y * block_size

    for x = bx, bx + block_size - 1 do
        for y = by, by + block_size - 1 do
            table.insert(tiles, {name = 'dry-dirt', position = {x, y}})
        end
    end
    local surface = RS.get_surface()
    surface.set_tiles(tiles, false)

    game.forces.player.chart(surface, {{bx, by}, {bx + block_size, by + block_size}})
end

local function on_tick()
    if global.strike_time == 0 then
        do_strike()
        global.strike_time = strike_time
    else
        global.strike_time = global.strike_time - 1
    end
end

Event.add(defines.events.on_tick, on_tick)
