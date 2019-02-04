local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local math = require 'utils.math'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

local track_seed1 = 37000
local track_seed2 = track_seed1 * 2
local ore_seed1 = 15000
local ore_seed2 = ore_seed1 * 2

local block_size = 30 * 1
local track_lines = 32
local track_chance = 1 / 3
local block_chance = 1 / 5
local number_blocks = 25

local ore_blocks = 32
local ore_block_size = 30

RS.set_map_gen_settings(
    {
        MGSP.ore_oil_none,
        MGSP.cliff_none,
        MGSP.enemy_none
    }
)

local blocks_size = track_lines * block_size
local offset = (track_lines * 0.5 + 0.5) * block_size

local h_track = {
    b.line_x(2),
    b.translate(b.line_x(2), 0, -3),
    b.translate(b.line_x(2), 0, 3),
    b.rectangle(2, 10)
}

h_track = b.any(h_track)
h_track = b.single_x_pattern(h_track, 15)

local v_track = {
    b.line_y(2),
    b.translate(b.line_y(2), -3, 0),
    b.translate(b.line_y(2), 3, 0),
    b.rectangle(10, 2)
}

v_track = b.any(v_track)
v_track = b.single_y_pattern(v_track, 15)

local v_line_left = b.translate(v_track, -12, 0)
local v_line_right = b.translate(v_track, 18, 0)
local h_line_top = b.translate(h_track, 0, -12)
local h_line_bottom = b.translate(h_track, 0, 18)

local random = Random.new(track_seed1, track_seed2)
local random_ore = Random.new(ore_seed1, ore_seed2)

local function do_track_lines(lines, track_shape, first_track, last_track)
    if #lines == 0 then
        return
    end

    local track_pattern = {}

    table.insert(track_pattern, first_track)

    local n_i = 2
    local n = lines[n_i]

    for i = 2, track_lines - 1 do
        local shape
        if i == n then
            shape = track_shape
            n_i = n_i + 1
            n = lines[n_i]
        else
            shape = b.empty_shape
        end

        track_pattern[i] = shape
    end

    table.insert(track_pattern, last_track)

    return track_pattern
end

local squares = {
    {shape = b.rectangle(16), weight = 3},
    {shape = b.rectangle(32), weight = 2},
    {shape = b.rectangle(48), weight = 1}
}

local total_square_weights = {}
local square_t = 0
for _, v in ipairs(squares) do
    square_t = square_t + v.weight
    table.insert(total_square_weights, square_t)
end

local value = b.exponential_value

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.5)
    return b.throttle_world_xy(shape, 1, 4, 1, 4)
end

local function empty_transform()
    return b.empty_shape
end

local ores = {
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.12), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.1), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 5},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(200, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50, 1.075), weight = 6},
    {transform = empty_transform, weight = 400}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local function do_resources()
    local pattern = {}

    for r = 1, ore_blocks do
        local row = {}
        pattern[r] = row
        for c = 1, ore_blocks do
            local shape
            local i = random_ore:next_int(1, square_t)
            local index = table.binary_search(total_square_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            shape = squares[index].shape

            local ore_data
            i = random_ore:next_int(1, ore_t)
            index = table.binary_search(total_ore_weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end
            ore_data = ores[index]

            shape = ore_data.transform(shape)
            local ore = b.resource(shape, ore_data.resource, ore_data.value)

            row[c] = ore
        end
    end

    local ore_shape = b.grid_pattern_full_overlap(pattern, ore_blocks, ore_blocks, ore_block_size, ore_block_size)
    return ore_shape
end

local worm_names = {
    'small-worm-turret',
    'medium-worm-turret',
    'big-worm-turret'
}

local max_worm_chance = 1 / 128
local worm_chance_factor = 1 / (192 * 512)

local function worms(_, _, world)
    local wx, wy = world.x, world.y
    local d = math.sqrt(wx * wx + wy * wy)

    local worm_chance = d - 300

    if worm_chance > 0 then
        worm_chance = worm_chance * worm_chance_factor
        worm_chance = math.min(worm_chance, max_worm_chance)

        if math.random() < worm_chance then
            if d < 512 then
                return {name = 'small-worm-turret'}
            else
                local max_lvl
                local min_lvl
                if d < 768 then
                    max_lvl = 2
                    min_lvl = 1
                else
                    max_lvl = 3
                    min_lvl = 2
                end
                local lvl = math.random() ^ (512 / d) * max_lvl
                lvl = math.ceil(lvl)
                lvl = math.clamp(lvl, min_lvl, 3)
                return {name = worm_names[lvl]}
            end
        end
    end
end

local empty = b.empty_shape
local water = b.tile('water')

local function do_blocks()
    local vertical_lines = {1}
    local horizontal_lines = {1}

    local prev_v, prev_h = false, false

    for i = 3, track_lines - 2 do
        if prev_v then
            prev_v = false
        else
            if random:next() < track_chance then
                prev_v = true
                table.insert(vertical_lines, i)
            end
        end
        if prev_h then
            prev_h = false
        else
            if random:next() < track_chance then
                prev_h = true
                table.insert(horizontal_lines, i)
            end
        end
    end

    if #vertical_lines == 1 then
        table.insert(vertical_lines, track_lines - 2)
    end
    if #horizontal_lines == 1 then
        table.insert(horizontal_lines, track_lines - 2)
    end

    local block_pattern = {}
    for _ = 1, track_lines do
        table.insert(block_pattern, {})
    end

    for hi = 1, #horizontal_lines - 1 do
        local h = horizontal_lines[hi]
        local h_next = horizontal_lines[hi + 1]

        for vi = 1, #vertical_lines - 1 do
            local v = vertical_lines[vi]
            local v_next = vertical_lines[vi + 1]

            local shape
            if random:next() < block_chance then
                shape = b.full_shape
            else
                shape = empty
            end

            for row_i = h, h_next do
                local row = block_pattern[row_i]
                for col_i = v, v_next do
                    if row[col_i] ~= b.full_shape then
                        row[col_i] = shape
                    end
                end
            end
        end
    end

    local v_last = vertical_lines[#vertical_lines]
    local h_last = horizontal_lines[#horizontal_lines]
    for h = 1, track_lines do
        local row = block_pattern[h]
        for _ = v_last, track_lines do
            table.insert(row, empty)
        end
    end

    for _ = 1, track_lines - 1 do
        for h = h_last, track_lines do
            local row = block_pattern[h]

            table.insert(row, empty)
        end
    end

    local blocks = b.grid_pattern(block_pattern, track_lines, track_lines, block_size, block_size)
    local resources = do_resources()
    blocks = b.apply_entity(blocks, resources)
    blocks = b.apply_entity(blocks, worms)

    local h_tracks = do_track_lines(horizontal_lines, h_track, h_line_top, h_line_bottom)
    h_tracks = b.grid_y_pattern(h_tracks, track_lines, block_size)

    local v_tracks = do_track_lines(vertical_lines, v_track, v_line_left, v_line_right)
    v_tracks = b.grid_x_pattern(v_tracks, track_lines, block_size)

    local tracks = b.any {h_tracks, v_tracks}

    local map = b.any {blocks, tracks}

    map = b.if_else(map, water)

    map = b.translate(map, offset, offset)

    return map
end

local blocks_pattern = {}

for _ = 1, number_blocks do
    local row = {}
    for _ = 1, number_blocks do
        table.insert(row, do_blocks())
    end
    table.insert(blocks_pattern, row)
end

local map = b.grid_pattern(blocks_pattern, number_blocks, number_blocks, blocks_size, blocks_size)
map = b.change_map_gen_collision_tile(map, 'water-tile', 'grass-1')
map = b.fish(map, 0.00125)

map = b.translate(map, 191, -1825)

return map
