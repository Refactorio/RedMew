Module = {}

local Token = require 'utils.token'
local Task = require 'utils.schedule'
local Queue = require 'utils.q'

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


local function collides(self, collision_box, center, x_steps, y_steps)
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
                if 
                    y_offset > 0 or --Cant collide with itself, so continue checking for collision
                    y_offset < 5 or 
                    collision_box[y + y_steps][x + x_steps] == 0 or --Skip if colliding with itself
                    old_collision_box[y + y_steps][x + y_steps] == 0 --Skip if colliding with old self
                then 
                    local x_target = (x + x_steps - 3) * 16 + c_x + 2
                    local y_target = (y_offset - 3) * 16 + c_y + 2
                    local tile = surface.get_tile{x_target, y_target}
                    if tile.name ~= "water" then 
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function erase_qchunk(surface, x, y)
    local surface = self.surface
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

local function move_east(self)
    local surface = self.surface
    if collides(self, 0, 1) then return end
    for x = 5 * 32, -5 * 32, -32 do
        for y =  0,  -15 * 32, -32 do
            Queue.push(move_queue, {surface = surface, x = x + 16, y = y, x_offset = 16, y_offset = 0})
            Queue.push(move_queue, {surface = surface, x = x + 16, y = y + 16, x_offset = 16, y_offset = 0})
            Queue.push(move_queue, {surface = surface, x = x, y = y, x_offset = 16, y_offset = 0})
            Queue.push(move_queue, {surface = surface, x = x, y = y + 16, x_offset = 16, y_offset = 0})
        end
    end
    Task.set_timeout_in_ticks(1, worker)
end

local function move_south(self)
    local surface = self.surface
    local position = self.position
    local collision_box = self.collision_box
    if collides(self, 0, 1) then return end
    local tetri_x = position.x
    local tetri_y = position.y
    for y = 4, 1, -1 do
        for x = 1, 3 do 
            if collision_box[y] and collision_box[y][x] == 1 then
                Queue.push(move_queue, {surface = surface, x = tetri_x + (x - 3) * 16, y = tetri_y + (y - 3) * 16 , x_offset = 0, y_offset = 16})
            end
        end
    end
    position.y = tetri_y + 16
    Task.set_timeout_in_ticks(1, worker)
end

local function move(self, x_direction, y_direction)
    local surface = self.surface
    local position = self.position
    local collision_box = self.collision_box
    if collides(self, 0, 1) then return end
    local tetri_x = position.x
    local tetri_y = position.y
    
    for x = x_start, x_end do 
        for y = 4, 1, -1 do
            if collision_box[y] and collision_box[y][x] == 1 then
                Queue.push(move_queue, {surface = surface, x = tetri_x + (x - 3) * 16, y = tetri_y + (y - 3) * 16 , x_offset = -16, y_offset = 0})
            end
        end
    end
    position.x = tetri_x - 16
    Task.set_timeout_in_ticks(1, worker)
end



function Module.new(surface, position, number)
    local self = table.deepcopy(Module) -- construct()
    self.position = position
    self.surface = surface
    self.collision_box = collision_boxes[number]
    self.collision_boxes = nil --save space :)

    Map.spawn_tetri(position, number)

    return self
end



local worker = nil
worker =
    Token.register(
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