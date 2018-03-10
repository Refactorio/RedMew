-- helpers
tau = 2 * math.pi
deg_to_rad = tau / 360
function degrees(angle)
    return angle * deg_to_rad
end

-- shape builders
function empty_builder()
    return false
end

function full_builder()
    return true
end

function tile_builder(tile)
    return function()
        return tile;
    end
end

function path_builder(thickness, optional_thickness_height)
    local width = thickness / 2
    local thickness2 = optional_thickness_height or thickness
    local height = thickness2 / 2
    return function(x, y)
        return (x > -width and x <= width) or (y > -height and y <= height)
    end
end

function rectangle_builder(width, height)
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

function line_x_builder(thickness)
    thickness = thickness / 2
    return function(x, y)
        return y > -thickness and y <= thickness
    end
end

function line_y_builder(thickness)
    thickness = thickness / 2
    return function(x, y)
        return x > -thickness and x <= thickness
    end
end

function square_diamond_builder(size)
    size = size / 2
    return function(x, y)
        return math.abs(x) + math.abs(y) <= size
    end
end

local rot = math.sqrt(2) / 2 -- 45 degree rotation.
function rectangle_diamond_builder(width, height)
    width = width / 2
    height = height / 2
    return function(x, y)
        local rot_x = rot * (x - y)
        local rot_y = rot * (x + y)
        return math.abs(rot_x) < width and math.abs(rot_y) < height
    end
end

function circle_builder(radius)
    local rr = radius * radius
    return function(x, y)
        return x * x + y * y < rr
    end
end

function oval_builder(x_radius, y_radius)
    local x_rr = x_radius * x_radius
    local y_rr = y_radius * y_radius
    return function(x, y)
        return ((x * x) / x_rr + (y * y) / y_rr) < 1
    end
end

local tile_map = {
    [1] = false,
    [2] = true,
    [3] = "concrete",
    [4] = "deepwater-green",
    [5] = "deepwater",
    [6] = "dirt-1",
    [7] = "dirt-2",
    [8] = "dirt-3",
    [9] = "dirt-4",
    [10] = "dirt-5",
    [11] = "dirt-6",
    [12] = "dirt-7",
    [13] = "dry-dirt",
    [14] = "grass-1",
    [15] = "grass-2",
    [16] = "grass-3",
    [17] = "grass-4",
    [18] = "hazard-concrete-left",
    [19] = "hazard-concrete-right",
    [20] = "lab-dark-1",
    [21] = "lab-dark-2",
    [22] = "lab-white",
    [23] = "out-of-map",
    [24] = "red-desert-0",
    [25] = "red-desert-1",
    [26] = "red-desert-2",
    [27] = "red-desert-3",
    [28] = "sand-1",
    [29] = "sand-2",
    [30] = "sand-3",
    [31] = "stone-path",
    [32] = "water-green",
    [33] = "water"
}

function decompress(pic)
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
            
            for i = 1, count do
                u_row[x] = pixel
                x = x + 1
            end
        end
    end
    
    return {width = width, height = height, data = uncompressed}
end

function picture_builder(pic)
    local data = pic.data
    local width = pic.width
    local height = pic.height
    
    -- the plus one is because lua tables are one based.
    local half_width = math.floor(width / 2) + 1
    local half_height = math.floor(height / 2) + 1
    return function(x, y)
        x = math.floor(x)
        y = math.floor(y)
        local x2 = x + half_width
        local y2 = y + half_height
        
        if y2 > 0 and y2 <= height and x2 > 0 and x2 <= width then
            local pixel = data[y2][x2]
            return pixel
        else
            return false
        end
    end
end

-- transforms and shape helpers
function translate(builder, x_offset, y_offset)
    return function(x, y, world_x, world_y, surface)
        return builder(x - x_offset, y - y_offset, world_x, world_y, surface)
    end
end

function scale(builder, x_scale, y_scale)
    x_scale = 1 / x_scale
    y_scale = 1 / y_scale
    return function(x, y, world_x, world_y, surface)
        return builder(x * x_scale, y * y_scale, world_x, world_y, surface)
    end
end

function rotate(builder, angle)
    local qx = math.cos(angle)
    local qy = math.sin(angle)
    return function(x, y, world_x, world_y, surface)
        local rot_x = qx * x - qy * y
        local rot_y = qy * x + qx * y
        return builder(rot_x, rot_y, world_x, world_y, surface)
    end
end

function scale_rotate_translate(builder, x_scale, y_scale, angle, x_offset, y_offset)
    local transform = translate(rotate(scale(builder, x_scale, y_scale), angle), x_offset, y_offset)
    return function(x, y, world_x, world_y, surface)
        return transform(x, y, world_x, world_y, surface)
    end
end

function flip_x(builder)
    return function(x, y, world_x, world_y, surface)
        return builder(-x, y, world_x, world_y, surface)
    end
end

function flip_y(builder)
    return function(x, y, world_x, world_y, surface)
        return builder(x, -y, world_x, world_y, surface)
    end
end

function flip_xy(builder)
    return function(x, y, world_x, world_y, surface)
        return builder(-x, -y, world_x, world_y, surface)
    end
end

-- For resource_module_builder it will return the first success.
function compound_or(builders)
    return function(x, y, world_x, world_y, surface)
        for _, v in ipairs(builders) do
            local tile, entity = v(x, y, world_x, world_y, surface)
            if tile then
                return tile, entity
            end
        end
        return false
    end
end

-- Wont work correctly with resource_module_builder becasues I don't know which one to return.
function compound_and(builders)
    return function(x, y, world_x, world_y, surface)
        for _, v in ipairs(builders) do
            if not v(x, y, world_x, world_y, surface) then
                return false
            end
        end
        return true
    end
end

function invert(builder)
    return function(x, y, world_x, world_y, surface)
        local tile, entity = builder(x, y, world_x, world_y, surface)
        return not tile, entity
    end
end

function throttle_x(builder, x_in, x_size)
    return function(x, y, world_x, world_y, surface)
        if x % x_size < x_in then
            return builder(x, y, world_x, world_y, surface)
        else
            return false
        end
    end
end

function throttle_y(builder, y_in, y_size)
    return function(x, y, world_x, world_y, surface)
        if y % y_size < y_in then
            return builder(x, y, world_x, world_y, surface)
        else
            return false
        end
    end
end

function throttle_xy(builder, x_in, x_size, y_in, y_size)
    return function(x, y, world_x, world_y, surface)
        if x % x_size < x_in and y % y_size < y_in then
            return builder(x, y, world_x, world_y, surface)
        else
            return false
        end
    end
end

function throttle_xy(builder, x_in, x_size, y_in, y_size)
    return function(x, y, world_x, world_y, surface)
        if x % x_size < x_in and y % y_size < y_in then
            return builder(x, y, world_x, world_y, surface)
        else
            return false
        end
    end
end

function throttle_world_xy(builder, x_in, x_size, y_in, y_size)
    return function(x, y, world_x, world_y, surface)
        if world_x % x_size < x_in and world_y % y_size < y_in then
            return builder(x, y, world_x, world_y, surface)
        else
            return false
        end
    end
end

function choose(condition, true_shape, false_shape)
    return function(local_x, local_y, world_x, world_y, surface)
        if condition(local_x, local_y, world_x, world_y, surface) then
            return true_shape(local_x, local_y, world_x, world_y, surface)
        else
            return false_shape(local_x, local_y, world_x, world_y, surface)
        end
    end
end

function shape_or_else(shape, else_shape)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = shape(local_x, local_y, world_x, world_y, surface)
        if (tile) then
            return tile, entity
        else
            return else_shape(local_x, local_y, world_x, world_y, surface)
        end
    end
end

function linear_grow(shape, size)
    local half_size = size / 2
    return function(local_x, local_y, world_x, world_y, surface)
        local t = math.ceil((local_y / size) + 0.5)
        local n = math.ceil((math.sqrt(8 * t + 1) - 1) / 2)
        local t_upper = n * (n + 1) * 0.5
        local t_lower = t_upper - n
        
        local y = (local_y - size * (t_lower + n / 2 - 0.5)) / n
        local x = local_x / n
        
        return shape(x, y, world_x, world_y, surface)
    end
end

function grow(in_shape, out_shape, size, offset)
    local half_size = size / 2
    return function(local_x, local_y, world_x, world_y, surface)
        local tx = math.ceil(math.abs(local_x) / half_size)
        local ty = math.ceil(math.abs(local_y) / half_size)
        local t = math.max(tx, ty)
        
        local tile, entity
        
        for i = t, 2.5 * t, 1 do
            local out_t = 1 / (i - offset)
            local in_t = 1 / i
            
            tile = out_shape(out_t * local_x, out_t * local_y, world_x, world_y, surface)
            if tile then
                return false
            end
            
            tile, entity = in_shape(in_t * local_x, in_t * local_y, world_x, world_y, surface)
            if tile then
                return tile, entity
            end
        end
        
        return false
    end
end

function project(shape, size, r)
    local ln_r = math.log(r)
    local r2 = 1 / (r - 1)
    local a = 1 / size
    
    return function(local_x, local_y, world_x, world_y, surface)
        local offset = 0.5 * size
        local sn = math.ceil(local_y + offset)
        
        local n = math.ceil(math.log((r - 1) * sn * a + 1) / ln_r - 1)
        local rn = r ^ n
        local rn2 = 1 / rn
        local c = size * rn
        
        local sn_upper = size * (r ^ (n + 1) - 1) * r2
        local x = local_x * rn2
        local y = (local_y - (sn_upper - 0.5 * c) + offset) * rn2
        
        return shape(x, y, world_x, world_y, surface)
    end
end

function project_overlap(shape, size, r)
    local ln_r = math.log(r)
    local r2 = 1 / (r - 1)
    local a = 1 / size
    local offset = 0.5 * size
    
    return function(local_x, local_y, world_x, world_y, surface)
        local sn = math.ceil(local_y + offset)
        
        local n = math.ceil(math.log((r - 1) * sn * a + 1) / ln_r - 1)
        local rn = r ^ n
        local rn2 = 1 / rn
        local c = size * rn
        
        local sn_upper = size * (r ^ (n + 1) - 1) * r2
        local x = local_x * rn2
        local y = (local_y - (sn_upper - 0.5 * c) + offset) * rn2
        
        local tile
        local entity
        
        tile, entity = shape(x, y, world_x, world_y, surface)
        if tile then
            return tile, entity
        end
        
        local n_above = n - 1
        local rn_above = rn / r
        local rn2_above = 1 / rn_above
        local c_above = size * rn_above
        
        local sn_upper_above = sn_upper - c
        local x_above = local_x * rn2_above
        local y_above = (local_y - (sn_upper_above - 0.5 * c_above) + offset) * rn2_above
        
        tile, entity = shape(x_above, y_above, world_x, world_y, surface)
        if tile then
            return tile, entity
        end
        
        local n_below = n + 1
        local rn_below = rn * r
        local rn2_below = 1 / rn_below
        local c_below = size * rn_below
        
        local sn_upper_below = sn_upper + c_below
        local x_below = local_x * rn2_below
        local y_below = (local_y - (sn_upper_below - 0.5 * c_below) + offset) * rn2_below
        
        return shape(x_below, y_below, world_x, world_y, surface)
    end
end

-- ore generation.
-- builder is the shape of the ore patch.
function resource_module_builder(builder, resource_type, amount_function)
    amount_function = amount_function or function(a, b)
        return 603
    end
    return function(x, y, world_x, world_y, surface)
        if builder(x, y, world_x, world_y, surface) then
            return {
                name = resource_type,
                position = {world_x, world_y},
                amount = amount_function(world_x, world_y)
            }
        else
            return nil
        end
    end
end

function builder_with_resource(land_builder, resource_module)
    return function(x, y, world_x, world_y, surface)
        local tile = land_builder(x, y, world_x, world_y, surface)
        if tile then
            local entity = resource_module(x, y, world_x, world_y, surface)
            return tile, entity
        else
            return false
        end
    end
end

-- pattern builders.
function single_pattern_builder(shape, width, height)
    shape = shape or empty_builder
    local half_width = width / 2
    local half_height
    if height then
        half_height = height / 2
    else
        half_height = half_width
    end
    
    return function(local_x, local_y, world_x, world_y, surface)
        local_y = ((local_y + half_height) % height) - half_height
        local_x = ((local_x + half_width) % width) - half_width
        
        return shape(local_x, local_y, world_x, world_y, surface)
    end
end

function single_pattern_overlap_builder(shape, width, height)
    shape = shape or empty_builder
    local half_width = width / 2
    local half_height
    if height then
        half_height = height / 2
    else
        half_height = half_width
    end
    
    return function(local_x, local_y, world_x, world_y, surface)
        local_y = ((local_y + half_height) % height) - half_height
        local_x = ((local_x + half_width) % width) - half_width
        
        return shape(local_x, local_y, world_x, world_y, surface) or
            shape(local_x + width, local_y, world_x, world_y, surface) or
            shape(local_x - width, local_y, world_x, world_y, surface) or
            shape(local_x, local_y + height, world_x, world_y, surface) or
            shape(local_x, local_y - height, world_x, world_y, surface)
    end
end

function single_x_pattern_builder(shape, width)
    shape = shape or empty_builder
    local half_width = width / 2
    
    return function(local_x, local_y, world_x, world_y, surface)
        local_x = ((local_x + half_width) % width) - half_width
        
        return shape(local_x, local_y, world_x, world_y, surface)
    end
end

function single_y_pattern_builder(shape, height)
    shape = shape or empty_builder
    local half_height = height / 2
    
    return function(local_x, local_y, world_x, world_y, surface)
        local_y = ((local_y + half_height) % height) - half_height
        
        return shape(local_x, local_y, world_x, world_y, surface)
    end
end

function grid_pattern_builder(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2
    
    return function(local_x, local_y, world_x, world_y, surface)
        local local_y2 = ((local_y + half_height) % height) - half_height
        local row_pos = math.floor(local_y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}
        
        local local_x2 = ((local_x + half_width) % width) - half_width
        local col_pos = math.floor(local_x / width + 0.5)
        local col_i = col_pos % columns + 1
        
        local shape = row[col_i] or empty_builder
        return shape(local_x2, local_y2, world_x, world_y, surface)
    end
end

function grid_pattern_overlap_builder(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2
    
    return function(local_x, local_y, world_x, world_y, surface)
        local local_y2 = ((local_y + half_height) % height) - half_height
        local row_pos = math.floor(local_y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}
        
        local local_x2 = ((local_x + half_width) % width) - half_width
        local col_pos = math.floor(local_x / width + 0.5)
        local col_i = col_pos % columns + 1
        
        local shape = row[col_i] or empty_builder
        
        local tile, entity = shape(local_x2, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        -- edges
        local col_i_left = (col_pos - 1) % columns + 1
        shape = row[col_i_left] or empty_builder
        tile, entity = shape(local_x2 + width, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local col_i_right = (col_pos + 1) % columns + 1
        shape = row[col_i_right] or empty_builder
        tile, entity = shape(local_x2 - width, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local row_i_up = (row_pos - 1) % rows + 1
        local row_up = pattern[row_i_up] or {}
        shape = row_up[col_i]
        tile, entity = shape(local_x2, local_y2 + height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local row_i_down = (row_pos + 1) % rows + 1
        local row_down = pattern[row_i_down] or {}
        shape = row_down[col_i]
        tile, entity = shape(local_x2, local_y2 - height, world_x, world_y, surface)
        if tile then return tile, entity end
    end
end

function grid_pattern_full_overlap_builder(pattern, columns, rows, width, height)
    local half_width = width / 2
    local half_height = height / 2
    
    return function(local_x, local_y, world_x, world_y, surface)
        local local_y2 = ((local_y + half_height) % height) - half_height
        local row_pos = math.floor(local_y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {}
        
        local local_x2 = ((local_x + half_width) % width) - half_width
        local col_pos = math.floor(local_x / width + 0.5)
        local col_i = col_pos % columns + 1
        
        local shape = row[col_i] or empty_builder
        
        local tile, entity = shape(local_x2, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        -- edges
        local col_i_left = (col_pos - 1) % columns + 1
        shape = row[col_i_left] or empty_builder
        tile, entity = shape(local_x2 + width, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local col_i_right = (col_pos + 1) % columns + 1
        shape = row[col_i_right] or empty_builder
        tile, entity = shape(local_x2 - width, local_y2, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local row_i_up = (row_pos - 1) % rows + 1
        local row_up = pattern[row_i_up] or {}
        shape = row_up[col_i]
        tile, entity = shape(local_x2, local_y2 + height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        local row_i_down = (row_pos + 1) % rows + 1
        local row_down = pattern[row_i_down] or {}
        shape = row_down[col_i]
        tile, entity = shape(local_x2, local_y2 - height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        -- corners
        shape = row_up[col_i_left] or empty_builder
        tile, entity = shape(local_x2 + width, local_y2 + height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        shape = row_up[col_i_right] or empty_builder
        tile, entity = shape(local_x2 - width, local_y2 + height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        shape = row_down[col_i_left]
        tile, entity = shape(local_x2 + width, local_y2 - height, world_x, world_y, surface)
        if tile then return tile, entity end
        
        shape = row_down[col_i_right]
        tile, entity = shape(local_x2 - width, local_y2 - height, world_x, world_y, surface)
        if tile then return tile, entity end    
    end
end

function segment_pattern_builder(pattern)
    local count = #pattern
    
    return function(local_x, local_y, world_x, world_y, surface)
        local angle = math.atan2(-local_y, local_x)
        local index = math.floor(angle / tau * count) % count + 1
        local shape = pattern[index] or empty_builder
        return shape(local_x, local_y, world_x, world_y, surface)
    end
end

-- tile converters
function change_tile(builder, old_tile, new_tile)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        if tile == old_tile then
            tile = new_tile
        end
        return tile, entity
    end
end

function change_collision_tile(builder, collides, new_tile)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        if tile.collides_with(collides) then
            tile = new_tile
        end
        return tile, entity
    end
end

-- only changes tiles made by the factorio map generator.
function change_map_gen_tile(builder, old_tile, new_tile)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        if type(tile) == "boolean" and tile then
            local gen_tile = surface.get_tile(world_x, world_y).name
            if old_tile == gen_tile then
                tile = new_tile
            end
        end
        return tile, entity
    end
end

-- only changes tiles made by the factorio map generator.
function change_map_gen_collision_tile(builder, collides, new_tile)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        if type(tile) == "boolean" and tile then
            local gen_tile = surface.get_tile(world_x, world_y)
            if gen_tile.collides_with(collides) then
                tile = new_tile
            end
        end
        return tile, entity
    end
end

function spawn_fish(builder, spawn_rate)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        if type(tile) == "string" then
            if tile == "water" or tile == "deepwater" or tile == "water-green" or tile == "deepwater-green" then
                if spawn_rate >= math.random() then
                    entity = {name = "fish", position = {world_x, world_y}}
                end
            end
        elseif tile then
            if surface.get_tile(world_x, world_y).collides_with("water-tile") and spawn_rate >= math.random() then
                entity = {name = "fish", position = {world_x, world_y}}
            end
        end
        return tile, entity
    end
end

function spawn_entity(builder, name)
    return function(local_x, local_y, world_x, world_y, surface)
        if builder(local_x, local_y, world_x, world_y, surface) then
            return {name = name, position = {world_x, world_y}}
        else
            return nil
        end
    end
end

function apply_effect(builder, func)
    return function(local_x, local_y, world_x, world_y, surface)
        local tile, entity = builder(local_x, local_y, world_x, world_y, surface)
        tile, entity = func(local_x, local_y, world_x, world_y, tile, entity, surface)
        return tile, entity
    end
end

function manhattan_ore_value(base, mult)
    return function(x, y)
        return mult * (math.abs(x) + math.abs(y)) + base
    end
end

function euclidean_ore_value(base, mult)
    return function(x, y)
        return mult * math.sqrt(x * x + y * y) + base
    end
end
