--- @class This module provides a class that provides Tetrimino object functionallity
local Tetrimino = {}

--- @type LuaTetrimino
-- @field number number identifies the kind of Tetrimino
-- @field collision_box LuaTetriminoCollisionBox @see LuaTetriminoCollisionBox
-- @field position LuaPosition The current position of top left corner of the collision box of the tetrimino.
--    Only x/y divisible by 16 are legal coordinates.

--- @type LuaTetriminoCollisionBox represents the collision box of a tetrimino. Contains a 4x4 2d array.
-- @description If a cell is 1 the quad chunk represented by the array position is occupied. 0 if not
-- @field 1 table of numbers first row
-- @field 2 table of numbers second row
-- @field 3 table of numbers thrid row
-- @field 4 table of numbers forth  row

local table = require 'utils.table'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Queue = require 'utils.queue'
local Global = require 'utils.global'
local Game = require 'utils.game'

local insert = table.insert

--- Holds collision boxes for all tetriminos.
-- The index of this table is what defines the tetriminos kind.
-- IE: tetrimino with 1 is the "I" tetrimino
-- @table containing LuaTetriminoCollisionBox
local collision_boxes = {
    {
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0}
    },
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0}
    },
    {
        {0, 0, 0, 0},
        {0, 1, 1, 0},
        {1, 1, 0, 0},
        {0, 0, 0, 0}
    },
    {
        {0, 0, 0, 0},
        {1, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0}
    },
    {
        {0, 0, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 1, 0},
        {0, 1, 1, 0}
    },
    {
        {0, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 1, 0}
    }
}

local worker = nil
local move_queue = Queue.new()
local Map = nil
local sequence = {1, 2, 3, 4, 5, 6, 7, _head = 8}

Global.register(
    {
        move_queue = move_queue,
        sequence = sequence
    },
    function(tbl)
        move_queue = tbl.move_queue
        sequence = tbl.sequence
    end
)

--- Does this tetrimino collide with anything but itself with a new collision box(rotation) and an x/y offset
-- @param self LuaTetrimino (See @LuaTetrimino) The tetrimino that may collide
-- @param collision_box LuaTetriminoCollisionBox (See @LuaTetriminoCollisionBox) The suggested new collision box of self.
-- @param x_steps number either -1, 0 or 1. Represent going left by 16 tiles, not moving in x direction or going right by 16 tiles
-- @param y_steps number either -1, 0 or 1. Represent going up by 16 tiles, not moving in y direction or going down by 16 tiles
-- @return boolean
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
                        old_collision_box[y_offset][x_offset] == 0
                 then --check for collision if not colliding with old self
                    local x_target = x_offset * 16 + c_x + 2 - 16
                    local y_target = y_offset * 16 + c_y + 2 - 16
                    local tile = surface.get_tile {x_target, y_target}
                    if not tile.valid or tile.name ~= 'water' then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--- Replaces a quad chunk with water and destroys all entities on it
-- @param surface LuaSurface
-- @param x number top left x position of the quad chunk
-- @param y number top left y position of the quad chunk
local function erase_qchunk(surface, x, y)
    local new_tiles = {}
    for c_x = x + 1, x + 14 do
        for c_y = y + 1, y + 14 do
            insert(new_tiles, {name = 'water', position = {c_x, c_y}})
        end
    end
    local y_plus15 = y + 15
    for c_x = x, x + 15 do
        insert(new_tiles, {name = 'deepwater', position = {c_x, y}})
        insert(new_tiles, {name = 'deepwater', position = {c_x, y_plus15}})
    end

    local x_plus15 = x + 15
    for c_y = y, y + 14 do
        insert(new_tiles, {name = 'deepwater', position = {x, c_y}})
        insert(new_tiles, {name = 'deepwater', position = {x_plus15, c_y}})
    end
    surface.set_tiles(new_tiles)
end

--- Moves a quad chunk (16x16 tiles)
-- @param surface LuaSurface
-- @param x number x position of the quad chunk
-- @param y number y position of the quad chunk
-- @param x_offset number tiles to move in x direction
-- @param y_offset number tiles to move in y direction
local function move_qchunk(surface, x, y, x_offset, y_offset)
    local entities = surface.find_entities_filtered {area = {{x, y}, {x + 15, y + 15}}}
    local old_tiles = surface.find_tiles_filtered {area = {{x, y}, {x + 16, y + 16}}}
    local new_tiles = {}
    local player_positions = {}
    for index, tile in pairs(old_tiles) do
        local old_pos = tile.position
        new_tiles[index] = {name = tile.name, position = {x = old_pos.x + x_offset, y = old_pos.y + y_offset}}
    end

    for index, entity in pairs(entities) do
        local old_pos = entity.position

        local success,
            e =
            pcall(
            function()
                entity.teleport {old_pos.x + x_offset, old_pos.y + y_offset}
            end
        )
        if not success then --I will remove this after the beta :)
            game.print('PLEASE TELL VALANSCH OR WE WILL ALL DIE: ')
            game.print(entity.name)
            game.print(entity.type)

            log(entity.name)
            log(entity.type)
            log('error in create entity ' .. tostring(e))
        end
    end
    surface.set_tiles(new_tiles)
    erase_qchunk(surface, x, y)
    for player_index, position in pairs(player_positions) do
        Game.get_player_by_index(player_index).teleport(position)
    end
end

--- Moves the tetrimino in a supplied direction
-- @param self LuaTetrimino
-- @param x_direction number (-1, 0 or 1)
-- @param y_direction number (-1, 0 or 1)
-- @return boolean success
function Tetrimino.move(self, x_direction, y_direction)
    local surface = self.surface
    local position = self.position
    local collision_box = self.collision_box
    if collides(self, collision_box, x_direction, y_direction) then
        return false
    end
    local tetri_x = position.x
    local tetri_y = position.y
    if y_direction == 1 then
        for y = 4, 1, -1 do
            for x = 1, 4 do
                if collision_box[y] and collision_box[y][x] == 1 then
                    Queue.push(move_queue, {surface = surface, x = tetri_x + (x - 1) * 16, y = tetri_y + (y - 1) * 16, x_offset = 0, y_offset = 16})
                end
            end
        end
    elseif x_direction ~= 0 then --east or west
        for x = 2.5 + 1.5 * x_direction, 2.5 - 1.5 * x_direction, -x_direction do --go from 1 to 4 or from 4 to 1
            for y = 4, 1, -1 do
                if collision_box[y] and collision_box[y][x] == 1 then
                    Queue.push(
                        move_queue,
                        {surface = surface, x = tetri_x + (x - 1) * 16, y = tetri_y + (y - 1) * 16, x_offset = x_direction * 16, y_offset = 0}
                    )
                end
            end
        end
    end
    position.y = tetri_y + 16 * y_direction
    position.x = tetri_x + 16 * x_direction
    Task.set_timeout_in_ticks(1, worker)
    return true
end

--- Do nothing. Literally.
function Tetrimino.noop()
end

--- Returns a rotated version of a supplied collision box by 90° in mathematically positive direction
-- @param collision_box LuaTetriminoCollisionBox
-- @param[opt=false] reverse boolean rotate in mathematically negative direction?
-- @treturn LuaTetriminoCollisionBox the rotated collision box
local function rotate_collision_box(collision_box, reverse)
    local new_collision_box = {{}, {}, {}, {}}
    local transformation = {{}, {}, {}, {}}
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

--- Returns the collision box positions of the occupied qchunks in the tetris collision box
-- @param self LuaTetrimino
-- @return table of LuaPosition
function Tetrimino.active_qchunks(self)
    local collision_box = self.collision_box
    local result = {nil, nil, nil, nil}
    for x = 1, 4 do
        for y = 1, 4 do
            if collision_box[y][x] == 1 then
                insert(result, {x = x, y = y})
            end
        end
    end
    return result
end

--- Rotates a tetrimino, if it doesnt collide
-- @param self LuaTetrimino
-- @param[opt=false] reverse boolean rotate in mathmatically negative direction?
-- @return boolean success
function Tetrimino.rotate(self, reverse)
    local new_collision_box, transformation = rotate_collision_box(self.collision_box, reverse)
    if collides(self, new_collision_box, 0, 0) then
        return false
    end

    if self.number == 2 then
        game.print("You are a smart motherfucker, that's right.")
    end

    local old_collision_box = self.collision_box
    local surface = self.surface
    local find_tiles_filtered = surface.find_tiles_filtered
    local find_entities_filtered = surface.find_entities_filtered
    local tetri_x = self.position.x
    local tetri_y = self.position.y
    local insert = insert -- luacheck: ignore 431 (intentional upvalue shadow)
    local tiles = {}
    local entities = {}
    for x = 1, 4 do
        for y = 1, 4 do
            local target = transformation[y][x]
            if
                (target.x ~= x or target.y ~= y) and --Do not rotate identity
                    old_collision_box[y][x] == 1
             then --check for existence
                local top_left_x = tetri_x + x * 16 - 16
                local top_left_y = tetri_y + y * 16 - 16

                for _, tile in pairs(find_tiles_filtered {area = {{top_left_x, top_left_y}, {tetri_x + x * 16, tetri_y + y * 16}}}) do
                    insert(tiles, {name = tile.name, position = {tile.position.x + (target.x - x) * 16, tile.position.y + (target.y - y) * 16}})
                end

                for _, entity in pairs(find_entities_filtered {area = {{top_left_x, top_left_y}, {tetri_x + x * 16 - 1, tetri_y + y * 16 - 1}}}) do
                    entity.teleport {entity.position.x + (target.x - x) * 16, entity.position.y + (target.y - y) * 16}
                end
                if new_collision_box[y][x] == 0 then
                    erase_qchunk(surface, top_left_x, top_left_y)
                end
            end
        end
    end

    for _, e in pairs(entities) do
        surface.create_entity(e)
    end

    surface.set_tiles(tiles)
    self.collision_box = new_collision_box

    return true
end

local function get_next_tetri_number()
    local head = sequence._head
    if head > 7 then
        table.shuffle_table(sequence)
        head = 1
        sequence._head = 0
    end
    sequence._head = head + 1
    return sequence[head]
end

--- Constructs a new tetri and places it on the map
-- @param surface LuaSurface the surface the tetri will be placed on
-- @param position LuaPosition the position the tetri will be placed at. Legal values for x and y must be divisable by 16
-- @return LuaTetrimino @see LuaTetrimino
function Tetrimino.new(surface, position)
    local number = get_next_tetri_number()
    local self = {}
    self.number = number
    self.position = {x = position.x - 32, y = position.y - 32}
    self.surface = surface
    self.collision_box = collision_boxes[number]

    Map.spawn_tetri(surface, position, number)
    return self
end

--Works on one quad chunk in the move_queue
worker =
    Token.register(
    function()
        local quad = Queue.pop(move_queue)
        if quad then
            Task.set_timeout_in_ticks(1, worker)
            local surface = quad.surface
            local x = quad.x
            local y = quad.y
            local x_offset = quad.x_offset
            local y_offset = quad.y_offset
            move_qchunk(surface, x, y, x_offset, y_offset)
        end
    end
)

--- This module requires a map module as input.
--- @param map_input table containing the function field spawn_tetri(surface, position, number)
return function(map_input)
    Map = map_input
    return Tetrimino
end
