local math = require 'utils.math'

local pi = math.pi
local random = math.random
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local tau = math.tau
local loga = math.log

-- helpers
local inv_pi = 1 / pi

local Builders = {}

local function add_entity(tile, entity)
    if type(tile) == 'table' then
        if tile.entities then
            tile.entities [#tile.entities + 1] = entity
        else
            tile.entities = {entity}
        end
    elseif tile then
        tile = {
            tile = tile,
            entities = {entity}
        }
    end

    return tile
end

function Builders.add_entity(tile, entity)
    return add_entity(tile, entity)
end

-- shape builders
function Builders.empty_shape()
    return false
end

function Builders.full_shape()
    return true
end

function Builders.no_entity()
    return nil
end

function Builders.tile(tile)
    return function()
        return tile
    end
end

function Builders.path(thickness, optional_thickness_height)
    local width = thickness / 2
    local thickness2 = optional_thickness_height or thickness
    local height = thickness2 / 2
    return function(x, y)
        return (x > -width and x <= width) or (y > -height and y <= height)
    end
end

function Builders.rectangle(width, height)
    width = width / 2
    if height then
        height = height / 2
    else
        height = width
    end
    return function(x, y)
        return x > -width and x <= width and y > -height and y <= height
    end
end

function Builders.line_x(thickness)
    thickness = thickness / 2
    return function(_, y)
        return y > -thickness and y <= thickness
    end
end

function Builders.line_y(thickness)
    thickness = thickness / 2
    return function(x, _)
        return x > -thickness and x <= thickness
    end
end

function Builders.square_diamond(size)
    size = size / 2
    return function(x, y)
        return abs(x) + abs(y) <= size
    end
end

local rot = sqrt(2) / 2 -- 45 degree rotation.
function Builders.rectangle_diamond(width, height)
    width = width / 2
    height = height / 2
    return function(x, y)
        local rot_x = rot * (x - y)
        local rot_y = rot * (x + y)
        return abs(rot_x) < width and abs(rot_y) < height
    end
end

function Builders.circle(radius)
    local rr = radius * radius
    return function(x, y)
        return x * x + y * y < rr
    end
end

function Builders.oval(x_radius, y_radius)
    local x_rr = x_radius * x_radius
    local y_rr = y_radius * y_radius
    return function(x, y)
        return ((x * x) / x_rr + (y * y) / y_rr) < 1
    end
end

function Builders.sine_fill(width, height)
    local width_inv = tau / width
    local height_inv = -2 / height
    return function(x, y)
        local x2 = x * width_inv
        local y2 = y * height_inv
        if y <= 0 then
            return y2 < sin(x2)
        else
            return y2 > sin(x2)
        end
    end
end

function Builders.sine_wave(width, height, thickness)
    local width_inv = tau / width
    local height_inv = 2 / height
    thickness = thickness * 0.5
    return function(x, y)
        local x2 = x * width_inv
        local y2 = sin(x2)
        y = y * height_inv
        local d = abs(y2 - y)

        return d < thickness
    end
end

function Builders.rectangular_spiral(x_size, optional_y_size)
    optional_y_size = optional_y_size or x_size

    x_size = 1 / x_size
    optional_y_size = 1 / optional_y_size
    return function(x, y)
        x, y = x * x_size, y * optional_y_size
        x, y = floor(x + 0.5), floor(y + 0.5)
        local a = -max(abs(x), abs(y)) -- because of absolutes, it's faster to use max than an if..then..else

        if a % 2 == 0 then
            return y ~= a or x == a
        else
            return y == a and x ~= a
        end
    end
end

function Builders.circular_spiral(in_thickness, total_thickness)
    local half_total_thickness = total_thickness * 0.5
    return function(x, y)
        local d = sqrt(x * x + y * y)

        local angle = 1 + inv_pi * atan2(x, y)
        local offset = d + (angle * half_total_thickness)

        return offset % total_thickness < in_thickness
    end
end

function Builders.circular_spiral_grow(in_thickness, total_thickness, grow_factor)
    local half_total_thickness = total_thickness * 0.5
    local inv_grow_factor = 1 / grow_factor
    return function(x, y)
        local d = sqrt(x * x + y * y)

        local factor = (d * inv_grow_factor) + 1
        local total_thickness2 = total_thickness * factor
        local in_thickness2 = in_thickness * factor
        local half_total_thickness2 = half_total_thickness * factor

        local angle = 1 + inv_pi * atan2(x, y)
        local offset = d + (angle * half_total_thickness2)

        return offset % total_thickness2 < in_thickness2
    end
end

function Builders.circular_spiral_n_threads(in_thickness, total_thickness, n_threads)
    local half_total_thickness = total_thickness * 0.5 * n_threads
    return function(x, y)
        local d = sqrt(x * x + y * y)

        local angle = 1 + inv_pi * atan2(x, y)
        local offset = d + (angle * half_total_thickness)

        return offset % total_thickness < in_thickness
    end
end

function Builders.circular_spiral_grow_n_threads(in_thickness, total_thickness, grow_factor, n_threads)
    local half_total_thickness = total_thickness * 0.5 * n_threads
    local inv_grow_factor = 1 / grow_factor
    return function(x, y)
        local d = sqrt(x * x + y * y)

        local factor = (d * inv_grow_factor) + 1
        local total_thickness2 = total_thickness * factor
        local in_thickness2 = in_thickness * factor
        local half_total_thickness2 = half_total_thickness * factor

        local angle = 1 + inv_pi * atan2(x, y)
        local offset = d + (angle * half_total_thickness2)

        return offset % total_thickness2 < in_thickness2
    end
end

local tile_map = {
    [1] = false,
    [2] = true,
    [3] = 'concrete',
    [4] = 'deepwater-green',
    [5] = 'deepwater',
    [6] = 'dirt-1',
    [7] = 'dirt-2',
    [8] = 'dirt-3',
    [9] = 'dirt-4',
    [10] = 'dirt-5',
    [11] = 'dirt-6',
    [12] = 'dirt-7',
    [13] = 'dry-dirt',
    [14] = 'grass-1',
    [15] = 'grass-2',
    [16] = 'grass-3',
    [17] = 'grass-4',
    [18] = 'hazard-concrete-left',
    [19] = 'hazard-concrete-right',
    [20] = 'lab-dark-1',
    [21] = 'lab-dark-2',
    [22] = 'lab-white',
    [23] = 'out-of-map',
    [24] = 'red-desert-0',
    [25] = 'red-desert-1',
    [26] = 'red-desert-2',
    [27] = 'red-desert-3',
    [28] = 'sand-1',
    [29] = 'sand-2',
    [30] = 'sand-3',
    [31] = 'stone-path',
    [32] = 'water-green',
    [33] = 'water'
}

function Builders.decompress(pic)
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
            local pixel = tile_map[row[index]]
            local count = row[index + 1]

            for _ = 1, count do
                u_row[x] = pixel
                x = x + 1
            end
        end
    end

    return {width = width, height = height, data = uncompressed}
end

function Builders.picture(pic)
    local data = pic.data
    local width = pic.width
    local height = pic.height

    -- the plus one is because lua tables are one based.
    local half_width = floor(width / 2) + 1
    local half_height = floor(height / 2) + 1
    return function(x, y)
        x = floor(x)
        y = floor(y)
        local x2 = x + half_width
        local y2 = y + half_height

        if y2 > 0 and y2 <= height and x2 > 0 and x2 <= width then
            return data[y2][x2]
        else
            return false
        end
    end
end

-- transforms and shape helpers
function Builders.translate(shape, x_offset, y_offset)
    return function(x, y, world)
        return shape(x - x_offset, y - y_offset, world)
    end
end

function Builders.scale(shape, x_scale, y_scale)
    y_scale = y_scale or x_scale

    x_scale = 1 / x_scale
    y_scale = 1 / y_scale

    return function(x, y, world)
        return shape(x * x_scale, y * y_scale, world)
    end
end

function Builders.rotate(shape, angle)
    local qx = cos(angle)
    local qy = sin(angle)
    return function(x, y, world)
        local rot_x = qx * x - qy * y
        local rot_y = qy * x + qx * y
        return shape(rot_x, rot_y, world)
    end
end

function Builders.flip_x(shape)
    return function(x, y, world)
        return shape(-x, y, world)
    end
end

function Builders.flip_y(shape)
    return function(x, y, world)
        return shape(x, -y, world)
    end
end

function Builders.flip_xy(shape)
    return function(x, y, world)
        return shape(-x, -y, world)
    end
end

function Builders.any(shapes)
    return function(x, y, world)
        for _, s in ipairs(shapes) do
            local tile = s(x, y, world)
            if tile then
                return tile
            end
        end
        return false
    end
end

function Builders.all(shapes)
    return function(x, y, world)
        local tile
        for _, s in ipairs(shapes) do
            tile = s(x, y, world)
            if not tile then
                return false
            end
        end
        return tile
    end
end

function Builders.combine(shapes)
    return function(x, y, world)
        local function combine_table(tile, index)
            local i, s = next(shapes, index)
            while i do
                local t = s(x, y, world)
                if type(t) == 'table' then
                    if not tile.tile then
                        tile.tile = t.tile
                    end

                    local es = t.entities
                    if es then
                        for _, e in ipairs(es) do
                            add_entity(tile, e)
                        end
                    end
                else
                    if not tile.tile then
                        tile.tile = t
                    end
                end

                i, s = next(shapes, i)
            end

            return tile
        end

        local tile = false

        local i, s = next(shapes, nil)
        while i do
            local t = s(x, y, world)
            if not tile then
                tile = t
            elseif type(t) == 'table' then
                t.tile = tile
                return combine_table(t, i)
            end

            if type(tile) == 'table' then
                return combine_table(tile, i)
            end

            i, s = next(shapes, i)
        end

        return tile
    end
end

function Builders.add(shape1, shape2)
    return function(x, y, world)
        return shape1(x, y, world) or shape2(x, y, world)
    end
end

function Builders.subtract(shape, minus_shape)
    return function(x, y, world)
        if minus_shape(x, y, world) then
            return false
        else
            return shape(x, y, world)
        end
    end
end

function Builders.invert(shape)
    return function(x, y, world)
        return not shape(x, y, world)
    end
end

function Builders.throttle_x(shape, x_in, x_size)
    return function(x, y, world)
        if x % x_size < x_in then
            return shape(x, y, world)
        else
            return false
        end
    end
end

function Builders.throttle_y(shape, y_in, y_size)
    return function(x, y, world)
        if y % y_size < y_in then
            return shape(x, y, world)
        else
            return false
        end
    end
end

function Builders.throttle_xy(shape, x_in, x_size, y_in, y_size)
    return function(x, y, world)
        if x % x_size < x_in and y % y_size < y_in then
            return shape(x, y, world)
        else
            return false
        end
    end
end

function Builders.throttle_world_xy(shape, x_in, x_size, y_in, y_size)
    return function(x, y, world)
        if world.x % x_size < x_in and world.y % y_size < y_in then
            return shape(x, y, world)
        else
            return false
        end
    end
end

function Builders.choose(condition, true_shape, false_shape)
    return function(x, y, world)
        if condition(x, y, world) then
            return true_shape(x, y, world)
        else
            return false_shape(x, y, world)
        end
    end
end

function Builders.if_else(shape, else_shape)
    return function(x, y, world)
        return shape(x, y, world) or else_shape(x, y, world)
    end
end

function Builders.linear_grow(shape, size)
    return function(x, y, world)
        local t = ceil((y / size) + 0.5)
        local n = ceil((sqrt(8 * t + 1) - 1) / 2)
        local t_upper = n * (n + 1) * 0.5
        local t_lower = t_upper - n

        y = (y - size * (t_lower + n / 2 - 0.5)) / n
        x = x / n

        return shape(x, y, world)
    end
end

function Builders.grow(in_shape, out_shape, size, offset)
    local half_size = size / 2
    return function(x, y, world)
        local tx = ceil(abs(x) / half_size)
        local ty = ceil(abs(y) / half_size)

        local t
        if tx > ty then
            t = tx
        else
            t = ty
        end

        for i = t, 2.5 * t, 1 do
            local out_t = 1 / (i - offset)
            local in_t = 1 / i

            if out_shape(out_t * x, out_t * y, world) then
                return nil
            end

            local tile = in_shape(in_t * x, in_t * y, world)
            if tile then
                return tile
            end
        end

        return nil
    end
end

function Builders.project(shape, size, r)
    local ln_r = loga(r)
    local r2 = 1 / (r - 1)
    local a = 1 / size

    return function(x, y, world)
        local offset = 0.5 * size
        local sn = ceil(y + offset)

        local n = ceil(loga((r - 1) * sn * a + 1) / ln_r - 1)
        local rn = r ^ n
        local rn2 = 1 / rn
        local c = size * rn

        local sn_upper = size * (r ^ (n + 1) - 1) * r2
        x = x * rn2
        y = (y - (sn_upper - 0.5 * c) + offset) * rn2

        return shape(x, y, world)
    end
end

function Builders.project_pattern(pattern, size, r, columns, rows)
    local ln_r = loga(r)
    local r2 = 1 / (r - 1)
    local a = 1 / size
    local half_size = size / 2

    return function(x, y, world)
        local offset = 0.5 * size
        local sn = ceil(y + offset)

        local n = ceil(loga((r - 1) * sn * a + 1) / ln_r - 1)
        local rn = r ^ n
        local rn2 = 1 / rn
        local c = size * rn

        local sn_upper = size * (r ^ (n + 1) - 1) * r2
        x = x * rn2
        y = (y - (sn_upper - 0.5 * c) + offset) * rn2

        local row_i = n % rows + 1
        local row = pattern[row_i]

        local x2 = ((x + half_size) % size) - half_size
        local col_pos = floor(x / size + 0.5)
        local col_i = col_pos % columns + 1

        local shape = row[col_i]

        return shape(x2, y, world)
    end
end

function Builders.project_overlap(shape, size, r)
    local ln_r = loga(r)
    local r2 = 1 / (r - 1)
    local a = 1 / size
    local offset = 0.5 * size

    return function(x, y, world)
        local sn = ceil(y + offset)

        local n = ceil(loga((r - 1) * sn * a + 1) / ln_r - 1)
        local rn = r ^ n
        local rn2 = 1 / rn
        local c = size * rn

        local sn_upper = size * (r ^ (n + 1) - 1) * r2
        x = x * rn2
        y = (y - (sn_upper - 0.5 * c) + offset) * rn2

        local tile

        tile = shape(x, y, world)
        if tile then
            return tile
        end

        local rn_above = rn / r
        local rn2_above = 1 / rn_above
        local c_above = size * rn_above

        local sn_upper_above = sn_upper - c
        local x_above = x * rn2_above
        local y_above = (y - (sn_upper_above - 0.5 * c_above) + offset) * rn2_above

        tile = shape(x_above, y_above, world)
        if tile then
            return tile
        end

        local rn_below = rn * r
        local rn2_below = 1 / rn_below
        local c_below = size * rn_below

        local sn_upper_below = sn_upper + c_below
        local x_below = x * rn2_below
        local y_below = (y - (sn_upper_below - 0.5 * c_below) + offset) * rn2_below

        return shape(x_below, y_below, world)
    end
end

-- Entity generation
function Builders.entity(shape, name)
    return function(x, y, world)
        if shape(x, y, world) then
            return {name = name}
        end
    end
end

function Builders.entity_func(shape, func)
    return function(x, y, world)
        if shape(x, y, world) then
            return func(x, y, world)
        end
    end
end

function Builders.resource(shape, resource_type, amount_function, always_place)
    amount_function = amount_function or function()
            return 404
        end
    return function(x, y, world)
        if shape(x, y, world) then
            return {
                name = resource_type,
                amount = amount_function(world.x, world.y),
                always_place = always_place
            }
        end
    end
end

function Builders.apply_entity(shape, entity_shape)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if not tile then
            return false
        end

        local e = entity_shape(x, y, world)
        if e then
            tile = add_entity(tile, e)
        end

        return tile
    end
end

function Builders.apply_entities(shape, entity_shapes)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if not tile then
            return false
        end

        for _, es in ipairs(entity_shapes) do
            local e = es(x, y, world)
            if e then
                tile = add_entity(tile, e)
            end
        end

        return tile
    end
end

-- pattern builders.
function Builders.single_pattern(shape, width, height)
    shape = shape or Builders.empty_shape
    local half_width = width / 2
    local half_height
    if height then
        half_height = height / 2
    else
        half_height = half_width
    end

    return function(x, y, world)
        y = ((y + half_height) % height) - half_height
        x = ((x + half_width) % width) - half_width

        return shape(x, y, world)
    end
end

function Builders.single_pattern_overlap(shape, width, height)
    shape = shape or Builders.empty_shape
    local half_width = width / 2
    local half_height
    if height then
        half_height = height / 2
    else
        half_height = half_width
    end

    return function(x, y, world)
        y = ((y + half_height) % height) - half_height
        x = ((x + half_width) % width) - half_width

        return shape(x, y, world) or
        shape(x + width, y, world) or
        shape(x - width, y, world) or
        shape(x, y + height, world) or
        shape(x, y - height, world)
    end
end

function Builders.single_x_pattern(shape, width)
    shape = shape or Builders.empty_shape
    local half_width = width / 2

    return function(x, y, world)
        x = ((x + half_width) % width) - half_width

        return shape(x, y, world)
    end
end

function Builders.single_y_pattern(shape, height)
    shape = shape or Builders.empty_shape
    local half_height = height / 2

    return function(x, y, world)
        y = ((y + half_height) % height) - half_height

        return shape(x, y, world)
    end
end

function Builders.single_grid_pattern(shape, width, height)
    shape = shape or Builders.empty_shape

    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        x = ((x + half_width) % width) - half_width
        y = ((y + half_height) % height) - half_height

        return shape(x, y, world)
    end
end

function Builders.grid_x_pattern(pattern, columns, width)
    local half_width = width / 2

    return function(x, y, world)
        local x2 = ((x + half_width) % width) - half_width
        local columns_pos = floor(x / width + 0.5)
        local column_i = columns_pos % columns + 1
        local shape = pattern[column_i] or Builders.empty_shape

        return shape(x2, y, world)
    end
end

function Builders.grid_y_pattern(pattern, rows, height)
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local shape = pattern[row_i] or Builders.empty_shape

        return shape(x, y2, world)
    end
end

function Builders.grid_pattern(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        local x2 = ((x + half_width) % width) - half_width
        local col_pos = floor(x / width + 0.5)
        local col_i = col_pos % columns + 1

        local shape = row[col_i] or Builders.empty_shape
        return shape(x2, y2, world)
    end
end

function Builders.grid_pattern_overlap(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        local x2 = ((x + half_width) % width) - half_width
        local col_pos = floor(x / width + 0.5)
        local col_i = col_pos % columns + 1

        local shape = row[col_i] or Builders.empty_shape

        local tile = shape(x2, y2, world)
        if tile then
            return tile
        end

        -- edges
        local col_i_left = (col_pos - 1) % columns + 1
        shape = row[col_i_left] or Builders.empty_shape
        tile = shape(x2 + width, y2, world)
        if tile then
            return tile
        end

        local col_i_right = (col_pos + 1) % columns + 1
        shape = row[col_i_right] or Builders.empty_shape
        tile = shape(x2 - width, y2, world)
        if tile then
            return tile
        end

        local row_i_up = (row_pos - 1) % rows + 1
        local row_up = pattern[row_i_up] or {}
        shape = row_up[col_i] or Builders.empty_shape
        tile = shape(x2, y2 + height, world)
        if tile then
            return tile
        end

        local row_i_down = (row_pos + 1) % rows + 1
        local row_down = pattern[row_i_down] or {}
        shape = row_down[col_i] or Builders.empty_shape
        return shape(x2, y2 - height, world)
    end
end

function Builders.grid_pattern_full_overlap(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        local x2 = ((x + half_width) % width) - half_width
        local col_pos = floor(x / width + 0.5)
        local col_i = col_pos % columns + 1

        local row_i_up = (row_pos - 1) % rows + 1
        local row_up = pattern[row_i_up] or {}
        local row_i_down = (row_pos + 1) % rows + 1
        local row_down = pattern[row_i_down] or {}

        local col_i_left = (col_pos - 1) % columns + 1
        local col_i_right = (col_pos + 1) % columns + 1

        -- start from top left, move left to right then down
        local shape = row_up[col_i_left] or Builders.empty_shape
        local tile = shape(x2 + width, y2 + height, world)
        if tile then
            return tile
        end

        shape = row_up[col_i] or Builders.empty_shape
        tile = shape(x2, y2 + height, world)
        if tile then
            return tile
        end

        shape = row_up[col_i_right] or Builders.empty_shape
        tile = shape(x2 - width, y2 + height, world)
        if tile then
            return tile
        end

        shape = row[col_i_left] or Builders.empty_shape
        tile = shape(x2 + width, y2, world)
        if tile then
            return tile
        end

        shape = row[col_i] or Builders.empty_shape
        tile = shape(x2, y2, world)
        if tile then
            return tile
        end

        shape = row[col_i_right] or Builders.empty_shape
        tile = shape(x2 - width, y2, world)
        if tile then
            return tile
        end

        shape = row_down[col_i_left] or Builders.empty_shape
        tile = shape(x2 + width, y2 - height, world)
        if tile then
            return tile
        end

        shape = row_down[col_i] or Builders.empty_shape
        tile = shape(x2, y2 - height, world)
        if tile then
            return tile
        end

        shape = row_down[col_i_right] or Builders.empty_shape
        return shape(x2 - width, y2 - height, world)
    end
end

-- Tile a shape in a circular pattern
function Builders.circular_pattern(shape, quantity, radius)
    local pattern = {}
    local angle = tau / quantity
    for i = 1, quantity do
        local shape2 = Builders.rotate(Builders.translate(shape, 0, radius), i * angle)
        pattern[i] = shape2
    end
    return Builders.any(pattern)
end

local function is_spiral(x, y)
    local a = -max(abs(x), abs(y)) -- because of absolutes, it's faster to use max than an if..then..else

    if a % 2 == 0 then
        return y ~= a or x == a
    else
        return y == a and x ~= a
    end
end

function Builders.single_spiral_pattern(shape, width, height)
    local inv_width = 1 / width
    local inv_height = 1 / height
    return function(x, y, world)
        local x1 = floor(x * inv_width + 0.5)
        local y1 = floor(y * inv_height + 0.5)

        if is_spiral(x1, y1) then
            x1 = x - x1 * width
            y1 = y - y1 * height
            return shape(x1, y1, world)
        else
            return false
        end
    end
end

local function rotate_0(x, y)
    return x, y
end

local function rotate_90(x, y)
    return y, -x
end

local function rotate_180(x, y)
    return -x, -y
end

local function rotate_270(x, y)
    return -y, x
end

local function spiral_rotation(x, y)
    local a = -max(abs(x), abs(y)) -- because of absolutes, it's faster to use max than an if..then..else

    if a % 2 == 0 then
        if y ~= a or x == a then
            if x == a then
                return rotate_0
            elseif y >= x then
                return rotate_270
            else
                return rotate_180
            end
        end
    else
        if y == a and x ~= a then
            return rotate_90
        end
    end
end

function Builders.single_spiral_rotate_pattern(shape, width, optional_height)
    optional_height = optional_height or width

    local inv_width = 1 / width
    local inv_height = 1 / optional_height
    return function(x, y, world)
        local x1 = floor(x * inv_width + 0.5)
        local y1 = floor(y * inv_height + 0.5)

        local t = spiral_rotation(x1, y1)
        if t then
            x1 = x - x1 * width
            y1 = y - y1 * optional_height
            x1, y1 = t(x1, y1)
            return shape(x1, y1, world)
        else
            return false
        end
    end
end

function Builders.circular_spiral_pattern(in_thickness, total_thickness, pattern)
    local n_threads = #pattern
    total_thickness = total_thickness * n_threads
    local half_total_thickness = total_thickness * 0.5
    local delta = total_thickness / n_threads
    return function(x, y, world)
        local d = sqrt(x * x + y * y)

        local angle = 1 + inv_pi * atan2(x, y)

        local offset = d + (angle * half_total_thickness)
        if offset % total_thickness < in_thickness then
            return pattern[1](x, y, world)
        end

        for i = 2, n_threads do
            offset = offset + delta
            if offset % total_thickness < in_thickness then
                return pattern[i](x, y, world)
            end
        end

        return false
    end
end

function Builders.circular_spiral_grow_pattern(in_thickness, total_thickness, grow_factor, pattern)
    local n_threads = #pattern
    total_thickness = total_thickness * n_threads
    local half_total_thickness = total_thickness * 0.5
    local inv_grow_factor = 1 / grow_factor
    local delta = total_thickness / n_threads
    return function(x, y, world)
        local d = sqrt(x * x + y * y)

        local factor = (d * inv_grow_factor) + 1
        local total_thickness2 = total_thickness * factor
        local in_thickness2 = in_thickness * factor
        local half_total_thickness2 = half_total_thickness * factor
        local delta2 = delta * factor

        local angle = 1 + inv_pi * atan2(x, y)

        local offset = d + (angle * half_total_thickness2)
        if offset % total_thickness2 < in_thickness2 then
            return pattern[1](x, y, world)
        end

        for i = 2, n_threads do
            offset = offset + delta2
            if offset % total_thickness2 < in_thickness2 then
                return pattern[i](x, y, world)
            end
        end

        return false
    end
end

function Builders.segment_pattern(pattern)
    local count = #pattern

    return function(x, y, world)
        local angle = atan2(-y, x)
        local index = floor(angle / tau * count) % count + 1
        local shape = pattern[index] or Builders.empty_shape
        return shape(x, y, world)
    end
end

function Builders.pyramid_pattern(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        if row_pos % 2 ~= 0 then
            x = x - half_width
        end

        local x2 = ((x + half_width) % width) - half_width
        local col_pos = floor(x / width + 0.5)
        local col_i = col_pos % columns + 1

        if col_pos > row_pos / 2 or -col_pos > (row_pos + 1) / 2 then
            return false
        end

        local shape = row[col_i] or Builders.empty_shape
        return shape(x2, y2, world)
    end
end

function Builders.pyramid_pattern_inner_overlap(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        local x_odd
        local x_even
        if row_pos % 2 == 0 then
            x_even = x
            x_odd = x - half_width
        else
            x_even = x - half_width
            x_odd = x
            x = x - half_width
        end

        x_even = ((x_even + half_width) % width) - half_width
        x_odd = ((x_odd + half_width) % width) - half_width

        local col_pos = floor(x / width + 0.5)

        local offset = 1
        local offset_odd = 0
        if (col_pos % 2) == (row_pos % 2) then
            offset = 0
            offset_odd = 1
        end

        local col_i = (col_pos - offset) % columns + 1
        local col_i_odd = (col_pos - offset_odd) % columns + 1

        if col_pos > row_pos / 2 or -col_pos > (row_pos + 1) / 2 then
            return false
        end

        local row_i_up = (row_pos - 1) % rows + 1
        local row_up = pattern[row_i_up] or {}
        local row_i_down = (row_pos + 1) % rows + 1
        local row_down = pattern[row_i_down] or {}

        local col_i_left = (col_pos - 1) % columns + 1
        local col_i_right = (col_pos + 1) % columns + 1

        -- start from top left, move left to right then down
        local shape = row_up[col_i_left] or Builders.empty_shape
        local tile = shape(x_even + width, y2 + height, world)
        if tile then
            return tile
        end

        shape = row_up[col_i_odd] or Builders.empty_shape
        tile = shape(x_odd, y2 + height, world)
        if tile then
            return tile
        end

        shape = row_up[col_i_right] or Builders.empty_shape
        tile = shape(x_even - width, y2 + height, world)
        if tile then
            return tile
        end

        shape = row[col_i_left] or Builders.empty_shape
        tile = shape(x_even + width, y2, world)
        if tile then
            return tile
        end

        shape = row[col_i] or Builders.empty_shape
        tile = shape(x_even, y2, world)
        if tile then
            return tile
        end

        shape = row[col_i_right] or Builders.empty_shape
        tile = shape(x_even - width, y2, world)
        if tile then
            return tile
        end

        shape = row_down[col_i_left] or Builders.empty_shape
        tile = shape(x_even + width, y2 - height, world)
        if tile then
            return tile
        end

        shape = row_down[col_i_odd] or Builders.empty_shape
        tile = shape(x_odd, y2 - height, world)
        if tile then
            return tile
        end

        shape = row_down[col_i_right] or Builders.empty_shape
        return shape(x_even - width, y2 - height, world)
    end
end

function Builders.grid_pattern_offset(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2

    return function(x, y, world)
        local y2 = ((y + half_height) % height) - half_height
        local row_pos = floor(y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}

        local x2 = ((x + half_width) % width) - half_width
        local col_pos = floor(x / width + 0.5)
        local col_i = col_pos % columns + 1

        y2 = y2 + height * floor((row_pos + 1) / rows)
        x2 = x2 + width * floor((col_pos + 1) / columns)

        local shape = row[col_i] or Builders.empty_shape
        return shape(x2, y2, world)
    end
end

-- tile converters
function Builders.change_tile(shape, old_tile, new_tile)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            if tile.tile == old_tile then
                tile.tile = new_tile
            end
        else
            if tile == old_tile then
                tile = new_tile
            end
        end

        return tile
    end
end

local path_tiles = {
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['stone-path'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true
}

Builders.path_tiles = path_tiles

function Builders.set_hidden_tile(shape, hidden_tile)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if type(tile) == 'table' and path_tiles[tile.tile] then
            tile.hidden_tile = hidden_tile
        elseif path_tiles[tile] then
            tile = {tile = tile, hidden_tile = hidden_tile}
        end

        return tile
    end
end

local collision_map = {
    ['concrete'] = 'ground-tile',
    ['deepwater-green'] = 'water-tile',
    ['deepwater'] = 'water-tile',
    ['dirt-1'] = 'ground-tile',
    ['dirt-2'] = 'ground-tile',
    ['dirt-3'] = 'ground-tile',
    ['dirt-4'] = 'ground-tile',
    ['dirt-5'] = 'ground-tile',
    ['dirt-6'] = 'ground-tile',
    ['dirt-7'] = 'ground-tile',
    ['dry-dirt'] = 'ground-tile',
    ['grass-1'] = 'ground-tile',
    ['grass-2'] = 'ground-tile',
    ['grass-3'] = 'ground-tile',
    ['grass-4'] = 'ground-tile',
    ['hazard-concrete-left'] = 'ground-tile',
    ['hazard-concrete-right'] = 'ground-tile',
    ['lab-dark-1'] = 'ground-tile',
    ['lab-dark-2'] = 'ground-tile',
    ['lab-white'] = 'ground-tile',
    ['out-of-map'] = false,
    ['red-desert-0'] = 'ground-tile',
    ['red-desert-1'] = 'ground-tile',
    ['red-desert-2'] = 'ground-tile',
    ['red-desert-3'] = 'ground-tile',
    ['sand-1'] = 'ground-tile',
    ['sand-2'] = 'ground-tile',
    ['sand-3'] = 'ground-tile',
    ['stone-path'] = 'ground-tile',
    ['water-green'] = 'water-tile',
    ['water'] = 'water-tile',
    ['refined-concrete'] = 'ground-tile',
    ['refined-hazard-concrete-left'] = 'ground-tile',
    ['refined-hazard-concrete-right'] = 'ground-tile'
}

function Builders.change_collision_tile(shape, collides, new_tile)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            if collision_map[tile.tile] == collides then
                tile.tile = new_tile
                return tile
            end
        else
            if collision_map[tile] == collides then
                return new_tile
            end
        end

        return tile
    end
end

-- only changes tiles made by the factorio map generator.
function Builders.change_map_gen_tile(shape, old_tile, new_tile)
    return function(x, y, world)
        local function handle_tile(tile)
            if type(tile) == 'boolean' and tile then
                local gen_tile = world.surface.get_tile(world.x, world.y).name
                if gen_tile == old_tile then
                    return new_tile
                end
            end
            return tile
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            tile.tile = handle_tile(tile.tile)
        else
            tile = handle_tile(tile)
        end

        return tile
    end
end

function Builders.change_map_gen_hidden_tile(shape, old_tile, hidden_tile)
    return function(x, y, world)
        local function is_collides()
            local gen_tile = world.surface.get_tile(world.x, world.y)
            return gen_tile.name == old_tile
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            if path_tiles[tile.tile] and is_collides() then
                tile.hidden_tile = hidden_tile
            end
        elseif path_tiles[tile] and is_collides() then
            tile = {tile = tile, hidden_tile = hidden_tile}
        end

        return tile
    end
end

-- only changes tiles made by the factorio map generator.
function Builders.change_map_gen_collision_tile(shape, collides, new_tile)
    return function(x, y, world)
        local function handle_tile(tile)
            if type(tile) == 'boolean' and tile then
                local gen_tile = world.surface.get_tile(world.x, world.y)
                if gen_tile.collides_with(collides) then
                    return new_tile
                end
            end
            return tile
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            tile.tile = handle_tile(tile.tile)
        else
            tile = handle_tile(tile)
        end

        return tile
    end
end

function Builders.change_map_gen_collision_hidden_tile(shape, collides, hidden_tile)
    return function(x, y, world)
        local function is_collides()
            local gen_tile = world.surface.get_tile(world.x, world.y)
            return gen_tile.collides_with(collides)
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            if path_tiles[tile.tile] and is_collides() then
                tile.hidden_tile = hidden_tile
            end
        elseif path_tiles[tile] and is_collides() then
            tile = {tile = tile, hidden_tile = hidden_tile}
        end

        return tile
    end
end

local bad_tiles = {
    ['out-of-map'] = true,
    ['water'] = true,
    ['deepwater'] = true,
    ['water-green'] = true,
    ['deepwater-green'] = true
}

function Builders.overlay_tile_land(shape, tile_shape)
    return function(x, y, world)
        local function handle_tile(tile)
            if type(tile) == 'boolean' then
                return tile and not world.surface.get_tile(world.x, world.y).collides_with('water-tile')
            else
                return not bad_tiles[tile]
            end
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            if handle_tile(tile.tile) then
                tile.tile = tile_shape(x, y, world) or tile.tile
            end
        else
            if handle_tile(tile) then
                tile = tile_shape(x, y, world) or tile
            end
        end

        return tile
    end
end

local water_tiles = {
    ['water'] = true,
    ['deepwater'] = true,
    ['water-green'] = true,
    ['deepwater-green'] = true
}

function Builders.fish(shape, spawn_rate)
    return function(x, y, world)
        local function handle_tile(tile)
            if type(tile) == 'string' then
                if water_tiles[tile] and spawn_rate >= random() then
                    return {name = 'fish'}
                end
            elseif tile then
                if world.surface.get_tile(world.x, world.y).collides_with('water-tile') and spawn_rate >= random() then
                    return {name = 'fish'}
                end
            end
        end

        local tile = shape(x, y, world)

        if type(tile) == 'table' then
            local entity = handle_tile(tile.tile)
            if entity then
                add_entity(tile, entity)
            end
        else
            local entity = handle_tile(tile)
            if entity then
                tile = {
                    tile = tile,
                    entities = {entity}
                }
            end
        end

        return tile
    end
end

function Builders.apply_effect(shape, func)
    return function(x, y, world)
        local tile = shape(x, y, world)

        if not tile then
            return tile
        end

        return func(x, y, world, tile)
    end
end

function Builders.manhattan_value(base, mult)
    return function(x, y)
        return mult * (abs(x) + abs(y)) + base
    end
end

function Builders.euclidean_value(base, mult)
    return function(x, y)
        return mult * sqrt(x * x + y * y) + base
    end
end

function Builders.exponential_value(base, mult, pow)
    return function(x, y)
        local d_sq = x * x + y * y
        return base + mult * d_sq ^ (pow / 2)
    end
end

function Builders.prepare_weighted_array(array)
    local total = 0
    local weights = {}
    local weight_counter = 1
    for _, v in ipairs(array) do
        total = total + v.weight
        weights[weight_counter] = total
        weight_counter = weight_counter + 1
    end

    weights.total = total

    return weights
end

return Builders
