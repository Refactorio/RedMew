Module = {}

local Token = require 'utils.token'
local Task = require 'utils.schedule'
local Queue = require 'utils.q'
local Global = require 'utils.global'

local insert = table.insert

local collision_boxes = {
    {
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
    },
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0},
    },
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0},
    },
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {1, 1, 0, 0},
        {0, 0, 0, 0},
    },
    {
        {0, 0, 0, 0},
        {1, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}, 
    },
    {
        {0, 0, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 1, 0},
        {0, 1, 1, 0},
    },
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 1, 0},
    },
}

local worker = nil
local move_queue = Queue.new()

Global.register(
    {
        move_queue = move_queue,
    },
    function(tbl)
       move_queue = tbl.move_queue
    end
)

local function collides(self, collision_box, x_steps, y_steps)
    local old_collision_box = self.collision_box
    local position = self.position
    local surface = self.surface
    local c_x = position.x
    local c_y = position.y
    for y = 1, 4 do
        for x = 1, 4 do 
            local bit = collision_box[y][x]
            if bit == 1 then
                local y_offset = y + y_steps
                local x_offset = x + x_steps
                if  
                    y_offset < 1 or --Cant collide with itself, so continue checking for collision
                    y_offset > 4 or
                    x_offset < 1 or
                    x_offset > 4 or
                    old_collision_box[y_offset][x_offset] == 0 --check for collision if not colliding with old self
                then 
                    local x_target = x_offset * 16 + c_x + 2 - 16
                    local y_target = y_offset * 16 + c_y + 2 - 16
                    local tile = surface.get_tile{x_target, y_target}
                    if not tile.valid or tile.name ~= "water" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function erase_qchunk(surface, x, y)
    local new_tiles = {}
    for c_x = x + 1 , x + 14 do 
        for c_y = y + 1, y + 14 do 
            insert(new_tiles, {name = "water", position = {c_x, c_y}})
        end
    end
    local y_plus15 = y + 15
    for c_x = x, x + 15 do 
        insert(new_tiles, {name = "deepwater", position = {c_x, y}})
        insert(new_tiles, {name = "deepwater", position = {c_x, y_plus15}})
    end

    local x_plus15 = x + 15
    for c_y = y, y + 14 do 
        insert(new_tiles, {name = "deepwater", position = {x, c_y}})
        insert(new_tiles, {name = "deepwater", position = {x_plus15, c_y}})
    end
    surface.set_tiles(new_tiles)
end

function move_qchunk(surface, x, y, x_offset, y_offset) 
    local entities = surface.find_entities_filtered{area = {{x,y}, {x + 15, y + 15}}}
    local old_tiles = surface.find_tiles_filtered{area = {{x,y}, {x + 16, y + 16}}}
    local new_tiles = {}
    for index, tile in ipairs(old_tiles) do 
        local old_pos = tile.position
        new_tiles[index] = {name = tile.name, position = {x = old_pos.x + x_offset, y = old_pos.y + y_offset}}
    end

    for index,entity in ipairs(entities) do 
        local old_pos = entity.position
        local amount = nil
        if entity.type == "resource" then 
            amount = entity.amount
        end
        surface.create_entity{force=entity.force, amount = amount, name = entity.name, position = {old_pos.x + x_offset, old_pos.y + y_offset}}
    end
    surface.set_tiles(new_tiles)
    erase_qchunk(surface, x, y)
end

function Module.move(self, x_direction, y_direction)
    local surface = self.surface
    local position = self.position
    local collision_box = self.collision_box
    if collides(self, collision_box, x_direction, y_direction) then return false end
    local tetri_x = position.x
    local tetri_y = position.y
    if y_direction == 1 then
        for y = 4, 1, -1 do
            for x = 1, 4 do 
                if collision_box[y] and collision_box[y][x] == 1 then
                    Queue.push(move_queue, {surface = surface, x = tetri_x + (x - 1) * 16, y = tetri_y + (y - 1) * 16 , x_offset = 0, y_offset = 16})
                end
            end
        end
    elseif x_direction ~= 0 then --east or west
        for x = 2.5 + 1.5 * x_direction, 2.5 - 1.5 * x_direction, -x_direction do --go from 1 to 4 or from 4 to 1
            for y = 4, 1, -1 do
                if collision_box[y] and collision_box[y][x] == 1 then
                    Queue.push(move_queue, {surface = surface, x = tetri_x + (x - 1) * 16, y = tetri_y + (y - 1) * 16 , x_offset = x_direction * 16, y_offset = 0})
                end
            end
        end
    end
    position.y = tetri_y + 16 * y_direction
    position.x = tetri_x + 16 * x_direction
    Task.set_timeout_in_ticks(1, worker)
    return true
end

function rotate_collision_box(collision_box, reverse)
    local new_collision_box = {{},{},{},{}}
    local transformation = {{},{},{},{}}
    if reverse then
        for y = 1, 4 do 
            for x = 1, 4 do
                new_collision_box[y][x] = collision_box[5 - x][y]
                transformation[5 - x][y] = {x = x, y = y}
            end
        end
    else
        for y = 1, 4 do 
            for x = 1, 4 do
                new_collision_box[y][x] = collision_box[x][5 - y]
                transformation[x][5 - y] = {x = x, y = y}
            end
        end
    end
    return new_collision_box, transformation
end

function Module.rotate(self, reverse)
    local new_collision_box, transformation = rotate_collision_box(self.collision_box, reverse)
    if collides(self, new_collision_box, 0, 0) then return end

    local old_collision_box = self.collision_box
    local surface = self.surface
    local find_tiles_filtered = surface.find_tiles_filtered
    local find_entities_filtered = surface.find_entities_filtered
    local tetri_x = self.position.x
    local tetri_y = self.position.y
    local insert = insert
    local tiles = {}
    local entities = {}

    for x = 1, 4 do 
        for y = 1, 4 do 
            local target = transformation[y][x]
            if 
                (target.x ~= x or target.y ~= y) and --Do not rotate identity
                old_collision_box[y][x] == 1 --check for existence
            then
                local top_left_x = tetri_x + x * 16 - 16
                local top_left_y = tetri_y + y * 16 - 16
                local area = {{top_left_x, top_left_y},{tetri_x + x * 16 - 1, tetri_y + y * 16 - 1}}

                for _, tile in pairs(find_tiles_filtered{area = {{top_left_x, top_left_y},{tetri_x + x * 16, tetri_y + y * 16}}}) do 
                    insert(tiles, {name = tile.name, position = {tile.position.x + (target.x - x) * 16, tile.position.y + (target.y - y) * 16}})
                end

                for _, entity in pairs(find_entities_filtered{area = {{top_left_x, top_left_y},{tetri_x + x * 16 - 1, tetri_y + y * 16 - 1}}}) do 
                    insert(entities, {name = entity.name, position = {entity.position.x + (target.x - x) * 16, entity.position.y + (target.y - y) * 16}})
                end
                erase_qchunk(surface, top_left_x, top_left_y)
            end 
        end
    end

    surface.set_tiles(tiles)

    self.collision_box = new_collision_box
end

function Module.new(surface, position)
    local number = math.random(7)
    local self = table.deepcopy(Module) -- construct()
    self.position = {x = position.x - 32, y = position.y - 32}
    self.surface = surface
    self.collision_box = collision_boxes[number]
    self.collision_boxes = nil --save space :)

    Map.spawn_tetri(surface, position, number)

    return self
end

worker = Token.register(
    function()
        local quad =  Queue.pop(move_queue)
        if quad then
            Task.set_timeout_in_ticks(1, worker)
            local surface = quad.surface
            local direction = quad.direction
            local x = quad.x
            local y = quad.y
            local x_offset = quad.x_offset
            local y_offset = quad.y_offset
            move_qchunk(surface, x, y, x_offset, y_offset)
        end
    end
)

return function(map_input)
    Map = map_input
    return Module
end