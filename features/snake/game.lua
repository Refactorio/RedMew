local Global = require 'utils.global'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Queue = require 'utils.queue'

local random = math.random
local queue_new = Queue.new
local push = Queue.push
local push_to_end = Queue.push_to_end
local pop = Queue.pop
local peek = Queue.peek
local peek_start = Queue.peek_start
local peek_index = Queue.peek_index
local queue_size = Queue.size
local queue_pairs = Queue.pairs
local pairs = pairs

local Public = {}

local snakes = {} -- player_index -> snake_data {is_marked_for_destroy:bool, queue :Queue of {entity, cord} }
local board = {
    size = 0,
    surface = nil,
    position = nil,
    food_count = 0,
    is_running = false,
    update_rate = 30,
    max_food = 6
}
local cords_map = {} -- cords -> positions

Global.register(
    {snakes = snakes, board = board, cords_map = cords_map},
    function(tbl)
        snakes = tbl.snakes
        board = tbl.board
        cords_map = tbl.cords_map
    end
)

local vectors = {
    [0] = {x = 0, y = -1},
    [1] = {x = 0, y = -1},
    [2] = {x = 1, y = 0},
    [3] = {x = 1, y = 0},
    [4] = {x = 0, y = 1},
    [5] = {x = 0, y = 1},
    [6] = {x = -1, y = 0},
    [7] = {x = -1, y = 0}
}

local function destroy_snake(index, snake)
    for _, element in queue_pairs(snake.queue) do
        local e = element.entity
        if e and e.valid then
            e.destroy()
        end
    end
    snakes[index] = nil

    local player = game.get_player(index)
    if not player or not player.valid then
        return
    end

    player.set_controller{type = defines.controllers.spectator}

    local score = queue_size(snake.queue)
    game.print({'snake.snake_destroyed', player.name, score})

    script.raise_event(Public.events.on_snake_player_died, {
        player = player,
        score = score
    })
end

local function destroy_dead_snakes()
    for index, snake in pairs(snakes) do
        if snake.is_marked_for_destroy then
            destroy_snake(index, snake)
        end
    end
end

local function spawn_food()
    local size = board.size
    local center = math.ceil(size / 2)
    local surface = board.surface
    local find_entity = surface.find_entity

    local food_count = board.food_count
    local max_food = board.max_food
    local tries = max_food - food_count + 10

    while food_count < max_food and tries > 0 do
        while tries > 0 do
            tries = tries - 1
            local x, y = random(size), random(size)

            if x == center and y == center then
                goto continue
            end

            local pos = cords_map[x][y]

            local entity = find_entity('character', pos) or find_entity('compilatron', pos)
            if entity then
                goto continue
            end

            entity =
                surface.create_entity({name = 'compilatron', position = pos, force = 'neutral', direction = random(7)})
            entity.active = false
            entity.destructible = false
            food_count = food_count + 1

            break

            ::continue::
        end
    end

    board.food_count = food_count
end

local function destroy_food()
    local position = board.position
    local size = board.size
    local food =
        board.surface.find_entities_filtered(
        {
            name = 'compilatron',
            area = {left_top = position, right_bottom = {position.x + size * 2, position.y + size * 2}}
        }
    )

    for i = 1, #food do
        local e = food[i]
        if e.valid then
            e.destroy()
        end
    end

    board.food_count = 0
end

local function get_new_head_cord(head_cord, direction)
    local vector = vectors[direction]
    local vec_x, vec_y = vector.x, vector.y
    local x, y = head_cord.x + vec_x, head_cord.y + vec_y

    return x, y
end

local function tick_snake(index, snake)
    local player = game.get_player(index)

    if not player or not player.valid then
        snake.is_marked_for_destroy = true
        return
    end

    local character = player.character
    if not character or not character.valid then
        snake.is_marked_for_destroy = true
        return
    end

    local surface = board.surface
    local find_entity = surface.find_entity
    local snake_queue = snake.queue
    local snake_size = queue_size(snake_queue)
    local head = peek_start(snake_queue)
    local tail = peek(snake_queue)
    local head_cord = head.cord
    local tail_entity = tail.entity
    local tail_cord = tail.cord
    local size = board.size

    local walking_state = character.walking_state
    walking_state.walking = true
    local direction = walking_state.direction
    local x, y = get_new_head_cord(head_cord, direction)

    if x <= 0 or x > size or y <= 0 or y > size then
        snake.is_marked_for_destroy = true
        tail_entity.destroy()
        return
    end

    local new_head_position = cords_map[x][y]

    if snake_size > 1 and find_entity('character', new_head_position) == peek_index(snake_queue, snake_size - 1).entity then
        direction = (direction + 4) % 8
        walking_state.direction = direction
        x, y = get_new_head_cord(head_cord, direction)
    end

    if x <= 0 or x > size or y <= 0 or y > size then
        snake.is_marked_for_destroy = true
        tail_entity.destroy()
        return
    end

    new_head_position = cords_map[x][y]

    tail_entity.teleport(new_head_position)
    tail.cord = {x = x, y = y}

    pop(snake_queue)
    push(snake_queue, tail)

    player.character = nil
    player.character = tail_entity
    tail_entity.walking_state = walking_state
    head.entity.active = false
    tail_entity.active = true

    local entity = find_entity('compilatron', new_head_position)
    if entity and entity.valid then
        entity.destroy()

        entity =
            surface.create_entity {name = 'character', position = cords_map[tail_cord.x][tail_cord.y], force = 'player'}
        entity.character_running_speed_modifier = -1
        entity.color = player.color
        entity.active = false
        entity.destructible = false
        push_to_end(snake_queue, {entity = entity, cord = tail_cord})

        board.food_count = board.food_count - 1
    end
end

local function tick_snakes()
    for index, snake in pairs(snakes) do
        tick_snake(index, snake)
    end
end

local function check_snakes_for_collisions()
    local count_entities_filtered = board.surface.count_entities_filtered
    for index, snake in pairs(snakes) do
        if snake.is_marked_for_destroy then
            goto continue
        end

        if count_entities_filtered({name = 'character', position = peek_start(snake.queue).entity.position}) > 1 then
            snake.is_marked_for_destroy = true
        end

        ::continue::
    end
end

local tick =
    Token.register(
    function()
        tick_snakes()
        check_snakes_for_collisions()
        destroy_dead_snakes()
        spawn_food()
    end
)

local function make_board()
    local size = board.size
    local position = board.position
    local surface = board.surface

    local pos_x, pos_y = position.x, position.y

    for x = 1, size do
        local col = {}
        cords_map[x] = col
        for y = 1, size do
            col[y] = {pos_x + 2 * x - 0.5, pos_y + 2 * y - 0.5}
        end
    end

    size = size * 2
    local tiles = {}

    for x = 0, size do
        for y = 0, size do
            local pos = {pos_x + x, pos_y + y}
            local tile_name

            if x == 0 or x == size or y == 0 or y == size then
                tile_name = 'deepwater'
            elseif x % 2 == 1 and y % 2 == 1 then
                tile_name = 'grass-1'
            else
                tile_name = 'water'
            end

            tiles[#tiles + 1] = {position = pos, name = tile_name}
        end
    end

    surface.set_tiles(tiles)
end

local function find_new_snake_position()
    local size = board.size
    local find_entity = board.surface.find_entity

    local min = math.min(4, size)
    local max = math.max(1, size - 4)

    if min > max then
        min, max = max, min
    elseif min == max then
        min = 1
        max = size
    end

    local tries = 10

    while tries > 0 do
        tries = tries - 1

        local x, y = random(min, max), random(min, max)
        local pos = cords_map[x][y]

        local entity = find_entity('character', pos) or find_entity('compilatron', pos)
        if not entity then
            return {x = x, y = y}, pos
        end
    end
end

local function new_snake(player)
    if not board.is_running then
        return
    end

    if not player or not player.valid then
        return
    end

    if snakes[player.index] then
        return
    end

    local character = player.character
    if character and character.valid then
        character.destroy()
    end

    local cord, pos = find_new_snake_position()

    if not cord then
        player.print({'snake.spawn_snake_fail'})
        return
    end

    player.teleport(pos, board.surface)
    player.set_controller{type = defines.controllers.god}
    player.create_character()
    character = player.character
    character.character_running_speed_modifier = -1
    character.destructible = false

    local queue = queue_new()
    push(queue, {entity = character, cord = cord})
    local snake = {queue = queue}

    snakes[player.index] = snake
end

local function new_game(surface, position, size, update_rate, max_food)
    board.size = size or 15
    board.surface = surface
    position = position or {x = 1, y = 1}
    position.x = position.x or position[1]
    position.y = position.y or position[2]
    board.position = position
    board.update_rate = update_rate or 30
    board.max_food = max_food or 6

    make_board()
    destroy_food()
    spawn_food()

    board.is_running = true

    Event.add_removable_nth_tick(board.update_rate, tick)
end

Public = {
    events = {
        --[[
        on_snake_player_died
        Called when a player have died in a game of snake
        Contains
            name :: uint: Unique identifier of the event
            tick :: uint: Tick the event was generated.
            player :: LuaPlayer
            score :: uint: Score reached
        ]]
        on_snake_player_died = Event.generate_event_name('on_snake_player_died')
    }
}

function Public.start_game(surface, top_left_position, size, update_rate, max_food)
    if board.is_running then
        error('Snake game is already running you must end the game first.', 2)
    end

    if not surface then
        error('Surface must be set.', 2)
    end

    new_game(surface, top_left_position, size, update_rate or board.update_rate, max_food or board.max_food)
end

function Public.end_game()
    for index, snake in pairs(snakes) do
        destroy_snake(index, snake)
    end

    destroy_food()

    Event.remove_removable_nth_tick(board.update_rate, tick)

    board.is_running = false
end

function Public.new_snake(player)
    new_snake(player)
end

function Public.is_running()
    return board.is_running
end

return Public
