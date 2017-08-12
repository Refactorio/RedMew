
-- helpers

tau = 2 * math.pi
deg_to_rad = tau / 360
function degrees(angle)
    return  angle * deg_to_rad
end

-- shape builders

function empty_builder(x, y)
    return false
end

function full_builder(x, y)
    return true
end

function path_builder(thickness)	
    thickness = thickness / 2    
	return function(x, y)        
        return  math.abs(x) < thickness or math.abs(y) < thickness
    end
end

function rectangle_builder(width, height)    
    width = width / 2
    height = height / 2
    return function (x, y)                    
        return  math.abs(x) < width and math.abs(y) < height
    end
end

function square_diamond_builder(size)
    size = size / 2
    return function (x, y)        
        return  math.abs(x) + math.abs(y) < size
    end
end

local rot = math.sqrt(2) / 2 -- 45 degree rotate.
function rectangle_diamond_builder(width, height)
    width = width / 2
    height = height / 2
    return function (x, y)
        local rot_x = rot * (x - y)
        local rot_y = rot * (x + y)
        return math.abs(rot_x) < width and math.abs(rot_y) < height
    end
end

function circle_builder(radius)  
    local rr = radius * radius
    return function (x, y)
        return  x * x + y * y < rr
    end
end

function oval_builder(x_radius, y_radius)    
    local x_rr = x_radius * x_radius
    local y_rr = y_radius * y_radius
    return function (x, y)
        return  ((x * x) / x_rr + (y * y) / y_rr) < 1
    end
end

function picture_builder(data, width, height)
    local half_width = math.floor(width / 2)
    local half_height = math.floor(height / 2)
    return function(x, y)
        x = math.floor(x)
        y = math.floor(y)
        local x2 = x + half_width + 1
        local y2 = y + half_height  + 1     

        if y2 > 0 and y2 <= height and x2 > 0 and x2 <= width  then
            local pixel = data[y2][x2]            
            return pixel
        else
            return false
        end        
    end
end

-- transforms and shape helpers

function translate(builder, x_offset, y_offset)
    return function(x, y, world_x, world_y)
        return builder(x - x_offset, y - y_offset, world_x, world_y)
    end
end

function scale(builder, x_scale, y_scale)
    x_scale = 1 / x_scale
    y_scale = 1 / y_scale
    return function(x, y, world_x, world_y)
        return builder(x * x_scale, y * y_scale, world_x, world_y)
    end
end
    
function rotate(builder, angle)
    local qx = math.cos(angle)
    local qy = math.sin(angle)
    return function(x, y, world_x, world_y)
        local rot_x = qx * x - qy * y
        local rot_y = qy * x + qx * y
        return builder(rot_x, rot_y, world_x, world_y)
    end
end

function scale_rotate_translate(builder, x_scale, y_scale, angle, x_offset, y_offset)
    local transform = translate(rotate(scale(builder, x_scale, y_scale), angle), x_offset, y_offset)
    return function(x, y, world_x, world_y)
        return transform(x, y, world_x, world_y)
    end
end

function flip_x(builder)
    return function(x, y, world_x, world_y)
        return builder(-x, y, world_x, world_y)
    end
end

function flip_y(builder)
    return function(x, y, world_x, world_y)
        return builder(x, -y, world_x, world_y)
    end
end

function flip_xy(builder)
    return function(x, y, world_x, world_y)
        return builder(-x, -y, world_x, world_y)
    end
end

-- For resource_module_builder it will return the first success.
function compound_or(builders)
    return function(x, y, world_x, world_y)
        for _, v in ipairs(builders) do   
            local tile, entity = v(x, y, world_x, world_y)         
            if tile then return tile, entity end
        end
        return false
    end
end

-- Wont work correctly with resource_module_builder becasues I don't know which one to return.
function compound_and(builders)
    return function(x, y, world_x, world_y)
        for _, v in ipairs(builders) do
            if not v(x, y, world_x, world_y) then return false end
        end
        return true
    end
end

function invert(builder)
    return function(x, y, world_x, world_y)
        local tile, entity = builder(x, y, world_x, world_y)
        return not tile, entity
    end
end

function throttle_xy(builder, x_in, x_size, y_in, y_size)
    return function(x, y, world_x, world_y)
        if x % x_size < x_in and y % y_size < y_in then     
            return builder(x, y, world_x, world_y) 
        else
            return false
        end
    end
end

-- ore generation.

-- builder is the shape of the ore patch.
function resource_module_builder(builder, resource_type, amount_function)
    amount_function = amount_function or function(a, b) return 603 end
    return function(x, y, world_x, world_y)
        if builder(x, y, world_x, world_y) then
            return 
            {
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
    return function (x, y, world_x, world_y)
        local tile = land_builder(x, y)
        if tile then
            local entity = resource_module(x, y ,world_x, world_y)
            return tile, entity        
        else
            return false            
        end
    end
end

-- pattern builders.

function single_pattern_builder(shape, width, height)

    shape = shape or empty_builder
    local half_width  = width / 2
    local half_height = height / 2

    return function (local_x, local_y, world_x, world_y)      
        local_y = ((local_y + half_height) % height) - half_height + 0.5     
        local_x = ((local_x + half_width) % width) - half_width + 0.5 

        return shape(local_x, local_y, world_x, world_y)
    end
end

function grid_pattern_builder(pattern, columns, rows, width, height)
    
    local half_width  = width / 2
    local half_height = height / 2

    return function (local_x, local_y, world_x, world_y)
        local local_y2 = ((local_y + half_height) % height) - half_height + 0.5 
        local row_pos = math.floor(local_y / height + 0.5)
        local row_i = row_pos % rows + 1
        local row = pattern[row_i] or {} 

        local local_x2 = ((local_x + half_width) % width) - half_width + 0.5 
        local col_pos = math.floor(local_x / width + 0.5)  
        local col_i = col_pos % columns + 1

        local shape = row[col_i] or empty_builder
        return shape(local_x2, local_y2, world_x, world_y)
    end
end

-- tile converters

function change_tile(builder, old_tile, new_tile)
    return function (local_x, local_y, world_x, world_y )
        local tile, entity = builder(local_x, local_y, world_x, world_y)
        if tile == old_tile then
            tile = new_tile
        end
        return tile, entity
    end
end

function change_collision_tile(builder, collides, new_tile)
    return function (local_x, local_y, world_x, world_y )
        local tile, entity = builder(local_x, local_y, world_x, world_y)
        if tile.collides_with(collides) then
            tile = new_tile
        end
        return tile, entity
    end
end

-- only changes tiles made by the factorio map generator.
function change_map_gen_tile(builder, old_tile, new_tile)
    return function (local_x, local_y, world_x, world_y )
        local tile, entity = builder(local_x, local_y, world_x, world_y)
        if type(tile) == "boolean" and tile then
            local gen_tile = MAP_GEN_SURFACE.get_tile(world_x, world_y)
            if old_tile == gen_tile then
                tile = new_tile
            end
        end
        return tile, entity
    end
end

-- only changes tiles made by the factorio map generator.
function change_map_gen_collision_tile(builder, collides, new_tile)
    return function (local_x, local_y, world_x, world_y )
        local tile, entity = builder(local_x, local_y, world_x, world_y)
        if type(tile) == "boolean" and tile then
            local gen_tile = MAP_GEN_SURFACE.get_tile(world_x, world_y)
            if gen_tile.collides_with(collides) then
                tile = new_tile
            end
        end
        return tile, entity
    end
end