local Random = require 'map_gen.shared.random'
local Token = require 'utils.global_token'

local direction_bit_mask = 0xc0000000
local section_bit_mask = 0x30000000
local level_bit_mask = 0x0fffffff

local function set_block(tbl, x, y, value)
    tbl[(y - 1) * tbl.size + x] = value
end

local function get_block(tbl, x, y)
    local size = tbl.size
    if x < 1 or x > size or y < 1 or y > size then
        return 0
    end
    return tbl[(y - 1) * size + x] or 0
end

local Public = {}
Public.__index = Public

function Public.new(seed)
    local obj = {random = Random.new(seed, seed * 2)}

    return setmetatable(obj, Public)
end

local function set_wall_block(blocks, x, y)
    set_block(blocks, x, y, 1)
    table.insert(blocks.stack, {x = x, y = y})
end

local function goto_point_top(blocks, x, y, tx, ty)
    while x < tx do
        x = x + 1
        set_wall_block(blocks, x, y)
    end

    while y > ty do
        y = y - 1
        set_wall_block(blocks, x, y)
    end

    while y < ty do
        y = y + 1
        set_wall_block(blocks, x, y)
    end
end

local function goto_point_bottom(blocks, x, y, tx, ty)
    while x > tx do
        x = x - 1
        set_wall_block(blocks, x, y)
    end

    while y > ty do
        y = y - 1
        set_wall_block(blocks, x, y)
    end

    while y < ty do
        y = y + 1
        set_wall_block(blocks, x, y)
    end
end

local function goto_point_left(blocks, x, y, tx, ty)
    while y > ty do
        y = y - 1
        set_wall_block(blocks, x, y)
    end

    while x > tx do
        x = x - 1
        set_wall_block(blocks, x, y)
    end

    while x < tx do
        x = x + 1
        set_wall_block(blocks, x, y)
    end
end

local function goto_point_right(blocks, x, y, tx, ty)
    while y < ty do
        y = y + 1
        set_wall_block(blocks, x, y)
    end

    while x > tx do
        x = x - 1
        set_wall_block(blocks, x, y)
    end

    while x < tx do
        x = x + 1
        set_wall_block(blocks, x, y)
    end
end

local function do_walls(self, blocks, outpost_variance, outpost_min_step)
    local size = blocks.size
    local random = self.random

    local max_variance = size - outpost_variance + 1
    local variance_step = outpost_variance + outpost_min_step

    local x = random:next_int(1, outpost_variance)
    local y = random:next_int(1, outpost_variance)

    set_block(blocks, x, y, 1)
    table.insert(blocks.stack, {x = x, y = y})
    local start_x, start_y = x, y

    while x < size do
        local tx = x + random:next_int(outpost_min_step, variance_step)
        tx = math.min(size, tx)
        local ty = random:next_int(1, outpost_variance)

        goto_point_top(blocks, x, y, tx, ty)

        x, y = tx, ty
    end

    while y < size do
        local tx = random:next_int(max_variance, size)
        local ty = y + random:next_int(outpost_min_step, variance_step)
        ty = math.min(size, ty)

        goto_point_right(blocks, x, y, tx, ty)

        x, y = tx, ty
    end

    while x > 1 do
        local tx = x - random:next_int(outpost_min_step, variance_step)
        tx = math.max(1, tx)
        local ty = random:next_int(max_variance, size)

        goto_point_bottom(blocks, x, y, tx, ty)

        x, y = tx, ty
    end

    while y > start_y do
        local tx = random:next_int(1, outpost_variance)
        local ty = y - random:next_int(outpost_min_step, variance_step)

        if ty <= start_y then
            ty = start_y
            tx = start_x
        end

        goto_point_left(blocks, x, y, tx, ty)

        x, y = tx, ty
    end
end

local function remove_surplus_walls(blocks)
    local stack = blocks.stack
    local size = blocks.size

    while #stack > 0 do
        local count = 0
        local nx, ny
        local point = table.remove(stack)
        local x, y = point.x, point.y

        if x > 1 and get_block(blocks, x - 1, y) == 1 then
            nx, ny = x - 1, y
            count = count + 1
        end
        if x < size and get_block(blocks, x + 1, y) == 1 then
            nx, ny = x + 1, y
            count = count + 1
        end
        if y > 1 and get_block(blocks, x, y - 1) == 1 then
            nx, ny = x, y - 1
            count = count + 1
        end
        if y < size and get_block(blocks, x, y + 1) == 1 then
            nx, ny = x, y + 1
            count = count + 1
        end

        if count == 1 then
            set_block(blocks, x, y, 0)
            table.insert(stack, {x = nx, y = ny})
        end
    end
end

local function fill(blocks)
    local size = blocks.size
    local anti_set = {size = size}
    local anti_stack = {}

    local y_offset = (size - 1) * size
    for x = 1, size do
        if blocks[x] ~= 1 then
            table.insert(anti_stack, {x = x, y = 1})
        end

        if blocks[x + y_offset] ~= 1 then
            table.insert(anti_stack, {x = x, y = size})
        end
    end

    for y = 2, size do
        y_offset = (y - 1) * size
        if blocks[y_offset + 1] ~= 1 then
            table.insert(anti_stack, {x = 1, y = y})
        end

        if blocks[y_offset + size] ~= 1 then
            table.insert(anti_stack, {x = size, y = y})
        end
    end

    while #anti_stack > 0 do
        local point = table.remove(anti_stack)
        local x, y = point.x, point.y

        local offset = (y - 1) * size + x

        anti_set[offset] = 1

        if x > 1 then
            local x2 = x - 1
            local offset2 = offset - 1

            if anti_set[offset2] ~= 1 and blocks[offset2] ~= 1 then
                table.insert(anti_stack, {x = x2, y = y})
            end
        end
        if x < size then
            local x2 = x + 1
            local offset2 = offset + 1

            if anti_set[offset2] ~= 1 and blocks[offset2] ~= 1 then
                table.insert(anti_stack, {x = x2, y = y})
            end
        end
        if y > 1 then
            local y2 = y - 1
            local offset2 = offset - size

            if anti_set[offset2] ~= 1 and blocks[offset2] ~= 1 then
                table.insert(anti_stack, {x = x, y = y2})
            end
        end
        if y < size then
            local y2 = y + 1
            local offset2 = offset + size

            if anti_set[offset2] ~= 1 and blocks[offset2] ~= 1 then
                table.insert(anti_stack, {x = x, y = y2})
            end
        end
    end

    for y = 1, size do
        local offset = (y - 1) * size
        for x = 1, size do
            local i = offset + x
            if anti_set[i] ~= 1 then
                blocks[i] = 1
            end
        end
    end
end

local function do_levels(blocks, max_level)
    if max_level < 2 then
        return
    end

    local size = blocks.size

    --[[ for y = 1, size do
        local offset = (y - 1) * size
        for x = 1, size do
            local i = offset + x
        end
    end ]]

    local level = 1
    local next_level = 2

    repeat
        for y = 1, size do
            local offset = (y - 1) * size
            for x = 1, size do
                local i = offset + x

                if (blocks[i] or 0) >= level then
                    local count = 0

                    if x > 1 and (blocks[i - 1] or 0) >= level then
                        count = count + 1
                    end
                    if x < size and (blocks[i + 1] or 0) >= level then
                        count = count + 1
                    end
                    if y > 1 and (blocks[i - size] or 0) >= level then
                        count = count + 1
                    end
                    if y < size and (blocks[i + size] or 0) >= level then
                        count = count + 1
                    end

                    if count == 4 then
                        blocks[i] = next_level
                    end
                end
            end
        end

        level = level + 1
        next_level = next_level + 1
    until next_level == max_level + 1
end

local callback =
    Token.register(
    function(e)
        e.active = false
    end
)

function Public:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, max_level)
    local blocks = {size = outpost_blocks, stack = {}}

    do_walls(self, blocks, outpost_variance, outpost_min_step)
    remove_surplus_walls(blocks)
    fill(blocks)
    do_levels(blocks, max_level)

    return function(x, y)
        x, y = math.floor(x), math.floor(y)
        local level = get_block(blocks, x, y)

        if level == 1 then
            return {name = 'stone-wall', force = 'player'}
        elseif level == 2 then
            return {name = 'transport-belt', force = 'player'}
        elseif level == 3 then
            return {name = 'pipe', force = 'player', callback = callback}
        elseif level == 4 then
            return {name = 'iron-chest', force = 'player'}
        end
    end
end

return Public
