local Random = require 'map_gen.shared.random'
local Token = require 'utils.global_token'

local direction_bit_mask = 0xc0000000
local section_bit_mask = 0x30000000
local level_bit_mask = 0x0fffffff
local not_level_bit_mask = 0xf0000000
local direction_bit_shift = 30
local section_bit_shift = 28

local section_straight = 0
local section_outer_corner = 1
local section_inner_corner = 2

local wall_north_straight = 0x00000001
local wall_east_straight = 0x40000001
local wall_south_straight = 0x80000001
local wall_west_straight = 0xc0000001
local wall_north_outer = 0x10000001
local wall_east_outer = 0x50000001
local wall_south_outer = 0x90000001
local wall_west_outer = 0xd0000001
local wall_north_inner = 0x20000001
local wall_east_inner = 0x60000001
local wall_south_inner = 0xa0000001
local wall_west_inner = 0xe0000001

local function get_direction(part)
    local dir = bit32.band(part, direction_bit_mask)
    return bit32.rshift(dir, direction_bit_shift - 1)
end

local function get_section(part)
    local sec = bit32.band(part, section_bit_mask)
    return bit32.rshift(sec, section_bit_shift)
end

local function get_level(part)
    return bit32.band(part, level_bit_mask)
end

local function set_level(part, level)
    local not_level = bit32.band(part)
    return not_level + level
end

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

local function do_walls(self, blocks, outpost_variance, outpost_min_step)
    local size = blocks.size
    local random = self.random

    local max_variance = size - outpost_variance + 1
    local variance_step = outpost_variance + outpost_min_step

    local x = random:next_int(1, outpost_variance)
    local y = random:next_int(1, outpost_variance)

    local start_x, start_y = x, y

    local i = (y - 1) * size + x

    local pv = -1

    -- top
    while x < size do
        local tx = x + random:next_int(outpost_min_step, variance_step)
        tx = math.min(tx, size)

        if pv == 0 then
            blocks[i] = wall_north_straight
        elseif pv == -1 then
            blocks[i] = wall_north_outer
        else
            blocks[i] = wall_north_inner
        end

        x = x + 1
        i = i + 1

        while x < tx do
            blocks[i] = wall_north_straight
            x = x + 1
            i = i + 1
        end

        if x < size - outpost_min_step then
            local ty = random:next_int(1, outpost_variance)

            if y == ty then
                pv = 0
            elseif y < ty then
                pv = 1
                blocks[i] = wall_north_outer
                y = y + 1
                i = i + size
                while y < ty do
                    blocks[i] = wall_east_straight
                    y = y + 1
                    i = i + size
                end
            else
                pv = -1
                blocks[i] = wall_north_inner
                y = y - 1
                i = i - size
                while y > ty do
                    blocks[i] = wall_west_straight
                    y = y - 1
                    i = i - size
                end
            end
        else
            pv = 0
        end
    end

    pv = 1
    -- right
    while y < size do
        local ty = y + random:next_int(outpost_min_step, variance_step)
        ty = math.min(ty, size)

        if pv == 0 then
            blocks[i] = wall_east_straight
        elseif pv == -1 then
            blocks[i] = wall_east_inner
        else
            blocks[i] = wall_east_outer
        end

        y = y + 1
        i = i + size

        while y < ty do
            blocks[i] = wall_east_straight
            y = y + 1
            i = i + size
        end

        if y < size - outpost_min_step then
            local tx = random:next_int(max_variance, size)

            if x == tx then
                pv = 0
            elseif x < tx then
                pv = 1
                blocks[i] = wall_east_inner
                x = x + 1
                i = i + 1
                while x < tx do
                    blocks[i] = wall_north_straight
                    x = x + 1
                    i = i + 1
                end
            else
                pv = -1
                blocks[i] = wall_east_outer
                x = x - 1
                i = i - 1
                while x > tx do
                    blocks[i] = wall_south_straight
                    x = x - 1
                    i = i - 1
                end
            end
        else
            pv = 0
        end
    end

    pv = 1

    -- bottom
    while x > 1 do
        local tx = x - random:next_int(outpost_min_step, variance_step)
        tx = math.max(tx, 1)

        if pv == 0 then
            blocks[i] = wall_south_straight
        elseif pv == -1 then
            blocks[i] = wall_south_inner
        else
            blocks[i] = wall_south_outer
        end

        x = x - 1
        i = i - 1

        while x > tx do
            blocks[i] = wall_south_straight
            x = x - 1
            i = i - 1
        end

        if x > outpost_min_step + 1 then
            local ty = random:next_int(max_variance, size)

            if y == ty then
                pv = 0
            elseif y < ty then
                pv = 1
                blocks[i] = wall_south_inner
                y = y + 1
                i = i + size
                while y < ty do
                    blocks[i] = wall_east_straight
                    y = y + 1
                    i = i + size
                end
            else
                pv = -1
                blocks[i] = wall_south_outer
                y = y - 1
                i = i - size
                while y > ty do
                    blocks[i] = wall_west_straight
                    y = y - 1
                    i = i - size
                end
            end
        else
            pv = 0
        end
    end

    pv = -1
    -- left
    local bottom_left_y = y
    while y > start_y + variance_step do
        local ty = y - random:next_int(outpost_min_step, variance_step)
        ty = math.max(ty, start_y)

        if pv == 0 then
            blocks[i] = wall_west_straight
        elseif pv == -1 then
            blocks[i] = wall_west_outer
        else
            blocks[i] = wall_west_inner
        end

        y = y - 1
        i = i - size

        while y > ty do
            blocks[i] = wall_west_straight
            y = y - 1
            i = i - size
        end

        if y > start_y + variance_step + outpost_min_step then
            local tx = random:next_int(1, outpost_variance)

            if x == tx then
                pv = 0
            elseif x < tx then
                pv = 1
                blocks[i] = wall_west_outer
                x = x + 1
                i = i + 1
                while x < tx do
                    blocks[i] = wall_north_straight
                    x = x + 1
                    i = i + 1
                end
            else
                pv = -1
                blocks[i] = wall_west_inner
                x = x - 1
                i = i - 1
                while x > tx do
                    blocks[i] = wall_south_straight
                    x = x - 1
                    i = i - 1
                end
            end
        else
            pv = 0
        end
    end

    -- final connection
    if y == bottom_left_y then
        blocks[i] = wall_west_outer

        y = y - 1
        i = i - size

        while y > bottom_left_y - outpost_min_step do
            blocks[i] = wall_west_straight
            y = y - 1
            i = i - size
        end
    end

    if x == start_x then
        pv = 0
    elseif x < start_x then
        pv = 1
        blocks[i] = wall_west_outer
        x = x + 1
        i = i + 1
        while x < start_x do
            blocks[i] = wall_north_straight
            x = x + 1
            i = i + 1
        end
    else
        pv = -1
        blocks[i] = wall_west_inner
        x = x - 1
        i = i - 1
        while x > start_x do
            blocks[i] = wall_south_straight
            x = x - 1
            i = i - 1
        end
    end

    if pv == 0 then
        blocks[i] = wall_west_straight
    elseif pv == -1 then
        blocks[i] = wall_west_outer
    else
        blocks[i] = wall_west_inner
    end

    y = y - 1
    i = i - size

    while y > start_y do
        blocks[i] = wall_west_straight
        y = y - 1
        i = i - size
    end
end

local function fill(blocks)
    local size = blocks.size
    local anti_set = {size = size}
    local anti_stack = {}

    local y_offset = (size - 1) * size
    for x = 1, size do
        if blocks[x] == nil then
            table.insert(anti_stack, {x = x, y = 1})
        end

        if blocks[x + y_offset] == nil then
            table.insert(anti_stack, {x = x, y = size})
        end
    end

    for y = 2, size do
        y_offset = (y - 1) * size
        if blocks[y_offset + 1] == nil then
            table.insert(anti_stack, {x = 1, y = y})
        end

        if blocks[y_offset + size] == nil then
            table.insert(anti_stack, {x = size, y = y})
        end
    end

    while #anti_stack > 0 do
        local point = table.remove(anti_stack)
        local x, y = point.x, point.y

        local offset = (y - 1) * size + x

        anti_set[offset] = true

        if x > 1 then
            local x2 = x - 1
            local offset2 = offset - 1

            if not anti_set[offset2] and not blocks[offset2] then
                table.insert(anti_stack, {x = x2, y = y})
            end
        end
        if x < size then
            local x2 = x + 1
            local offset2 = offset + 1

            if not anti_set[offset2] and not blocks[offset2] then
                table.insert(anti_stack, {x = x2, y = y})
            end
        end
        if y > 1 then
            local y2 = y - 1
            local offset2 = offset - size

            if not anti_set[offset2] and not blocks[offset2] then
                table.insert(anti_stack, {x = x, y = y2})
            end
        end
        if y < size then
            local y2 = y + 1
            local offset2 = offset + size

            if not anti_set[offset2] and not blocks[offset2] then
                table.insert(anti_stack, {x = x, y = y2})
            end
        end
    end

    for y = 1, size do
        local offset = (y - 1) * size
        for x = 1, size do
            local i = offset + x
            if not anti_set[i] and not blocks[i] then
                blocks[i] = 2
            end
        end
    end
end

local function do_levels(blocks, max_level)
    if max_level < 3 then
        return
    end

    local size = blocks.size
    local level = 2

    repeat
        local next_level = level + 1
        for y = 1, size do
            local offset = (y - 1) * size
            for x = 1, size do
                local i = offset + x

                if get_level(blocks[i] or 0) >= level then
                    local count = 0

                    if x > 1 and get_level(blocks[i - 1] or 0) >= level then
                        count = count + 1
                    end
                    if x < size and get_level(blocks[i + 1] or 0) >= level then
                        count = count + 1
                    end
                    if y > 1 and get_level(blocks[i - size] or 0) >= level then
                        count = count + 1
                    end
                    if y < size and get_level(blocks[i + size] or 0) >= level then
                        count = count + 1
                    end

                    if count == 4 then
                        blocks[i] = next_level
                    end
                end
            end
        end

        level = level + 1
    until level == max_level
end

local callback =
    Token.register(
    function(e)
        e.active = false
    end
)

function Public:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, max_level)
    local blocks = {size = outpost_blocks}

    do_walls(self, blocks, outpost_variance, outpost_min_step)
    fill(blocks)
    do_levels(blocks, max_level)

    local size = blocks.size

    return function(x, y)
        x, y = math.floor(x), math.floor(y)
        if x < 1 or x > size or y < 1 or y > size then
            return
        end

        local part = blocks[(y - 1) * blocks.size + x]

        if part then
            local direction = get_direction(part)
            local section = get_section(part)
            local level = get_level(part)

            local name
            if level == 2 then
                name = 'wooden-chest'
            elseif level == 3 then
                name = 'iron-chest'
            elseif level == 4 then
                name = 'steel-chest'
            elseif level > 4 then
                name = 'pipe'
            elseif level < 1 then
                name = 'small-electric-pole'
            else
                if section == section_straight then
                    name = 'stone-wall'
                elseif section == section_outer_corner then
                    name = 'inserter'
                elseif section == section_inner_corner then
                    name = 'transport-belt'
                else
                    name = 'pipe'
                end
            end
            return {name = name, force = 'player', direction = direction, callback = callback}
        end
    end
end

return Public
