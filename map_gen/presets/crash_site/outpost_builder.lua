local Random = require 'map_gen.shared.random'
local Token = require 'utils.global_token'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Task = require 'utils.Task'

local b = require 'map_gen.shared.builders'

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

local part_size = 6
local inv_part_size = 1 / part_size

local refill_turrets = {index = 1}
local power_sources = {}
local magic_crafters = {index = 1}

Global.register(
    {
        refil_turrets = refill_turrets,
        power_sources = power_sources,
        magic_crafters = magic_crafters
    },
    function(tbl)
        refill_turrets = tbl.refil_turrets
        power_sources = tbl.power_sources
        magic_crafters = tbl.magic_crafters
    end
)

local function get_direction(part)
    local dir = bit32.band(part, direction_bit_mask)
    return bit32.rshift(dir, direction_bit_shift - 1)
end

local function get_4_way_direction(part)
    local dir = bit32.band(part, direction_bit_mask)
    return bit32.rshift(dir, direction_bit_shift)
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

Public.empty_template = {}

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
            blocks[i] = wall_east_inner
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
                blocks[i] = wall_east_outer
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
            blocks[i] = wall_south_inner
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
                blocks[i] = wall_south_outer
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
            blocks[i] = wall_west_inner
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
                blocks[i] = wall_west_outer
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
            blocks[i] = wall_north_inner
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
        blocks[i] = wall_north_outer
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
        blocks[i] = wall_north_inner
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

    local levels = {}
    blocks.levels = levels

    for i = 1, max_level do
        levels[i] = {}
    end

    for y = 1, size do
        local offset = (y - 1) * size
        for x = 1, size do
            local i = offset + x
            local block = blocks[i]
            if block then
                local l = get_level(block)
                table.insert(levels[l], i)
            end
        end
    end
end

local function make_blocks(self, blocks, templates)
    local random = self.random

    local levels = blocks.levels
    local wall_level = levels[1]

    local walls = templates[1]
    local wall_template_count = #walls
    for _, i in ipairs(wall_level) do
        local ti = random:next_int(1, wall_template_count)
        local template = walls[ti]

        if template == Public.empty_template then
            blocks[i] = nil
        else
            local block = blocks[i]

            local section = get_section(block)
            local dir = get_4_way_direction(block)

            local new_block = template[section + 1][dir + 1]
            blocks[i] = new_block
        end
    end

    for l = 2, #levels do
        local level = levels[l]
        local base_templates = templates[l]

        if base_templates then
            local base_template_count = #base_templates

            for _, i in ipairs(level) do
                local template
                if base_template_count == 0 then
                    template = nil
                elseif base_template_count == 1 then
                    template = base_templates[1]
                else
                    local ti = random:next_int(1, base_template_count)
                    template = base_templates[ti]
                end

                if template == Public.empty_template then
                    blocks[i] = nil
                else
                    blocks[i] = template
                end
            end
        else
            for _, i in ipairs(level) do
                blocks[i] = nil
            end
        end
    end
end

local function to_shape(blocks)
    local size = blocks.size
    local t_size = size * part_size
    local half_t_size = t_size * 0.5

    return function(x, y)
        x, y = math.floor(x + half_t_size), math.floor(y + half_t_size)
        if x < 0 or y < 0 or x >= t_size or y >= t_size then
            return true
        end

        local x2, y2 = math.floor(x * inv_part_size), math.floor(y * inv_part_size)

        local template = blocks[y2 * size + x2 + 1]
        if not template then
            return true
        end

        local x3, y3 = x - x2 * part_size, y - y2 * part_size

        local i = y3 * part_size + x3 + 1

        local entry = template[i]
        if not entry then
            return true
        end

        local entity = entry.entity
        local tile = entry.tile or true
        if entity then
            local data
            local callback = entity.callback
            if callback then
                local cd = template[callback]

                callback = cd.callback
                data = cd.data
            end
            return {
                tile = tile,
                entities = {
                    {
                        name = entity.name,
                        direction = entity.direction,
                        force = template.force,
                        callback = callback,
                        data = data
                    }
                }
            }
        end
        return tile
    end
end

function Public:do_outpost(outpost_blocks, outpost_variance, outpost_min_step, max_level, templates)
    local blocks = {size = outpost_blocks}

    do_walls(self, blocks, outpost_variance, outpost_min_step)
    fill(blocks)
    do_levels(blocks, max_level)
    make_blocks(self, blocks, templates)

    return to_shape(blocks)
end

function Public.to_shape(blocks)
    return to_shape(blocks)
end

local function change_direction(entry, new_dir)
    local e = entry.entity
    if not e then
        return entry
    end

    local copy = {}
    copy.tile = entry.tile

    local ce = {}

    copy.entity = ce
    for k, v in pairs(e) do
        ce[k] = v
    end
    ce.direction = new_dir

    return copy
end

function Public.make_1_way(data)
    data.__index = data
    return data
end

function Public.make_4_way(data)
    local props = {}

    local north = {}
    local east = {}
    local south = {}
    local west = {}
    local res = {north, east, south, west}

    for i, entry in pairs(data) do
        if type(i) == 'string' then
            props[i] = entry
        else
            local y = math.ceil(i * inv_part_size)
            local x = i - (y - 1) * part_size

            local e = entry.entity or {}
            local offset = e.offset

            local x2 = part_size - y + 1
            local y2 = x
            local x3 = part_size - x + 1
            local y3 = part_size - y + 1
            local x4 = y
            local y4 = part_size - x + 1

            local i2 = (y2 - 1) * part_size + x2
            local i3 = (y3 - 1) * part_size + x3
            local i4 = (y4 - 1) * part_size + x4

            if offset == 3 then
                i = i + 7
                i2 = i2 + 6
                i4 = i4 + 1
            elseif offset == 1 then
                i = i + 1
                i4 = i4 + 1
            elseif offset == 2 then
                i = i + 6
                i2 = i2 + 6
            end

            local dir = e.direction or 0

            north[i] = entry
            east[i2] = change_direction(entry, (dir + 2) % 8)
            south[i3] = change_direction(entry, (dir + 4) % 8)
            west[i4] = change_direction(entry, (dir + 6) % 8)
        end
    end

    north.__index = north
    east.__index = east
    south.__index = south
    west.__index = west

    for k, v in pairs(props) do
        north[k] = v
        east[k] = v
        south[k] = v
        west[k] = v
    end

    return res
end

local function shallow_copy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

function Public.extend_1_way(data, tbl)
    return setmetatable(shallow_copy(tbl), data)
end

function Public.extend_4_way(data, tbl)
    return {
        setmetatable(shallow_copy(tbl), data[1]),
        setmetatable(shallow_copy(tbl), data[2]),
        setmetatable(shallow_copy(tbl), data[3]),
        setmetatable(shallow_copy(tbl), data[4])
    }
end

function Public.extend_walls(data, tbl)
    return {
        Public.extend_4_way(data[1], tbl),
        Public.extend_4_way(data[2], tbl),
        Public.extend_4_way(data[3], tbl)
    }
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function do_refill_turrets()
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local data = refill_turrets[index]
    local turret = data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local ammo = data.ammo
    if data.liquid then
        turret.fluidbox[1] = ammo
    elseif ammo then
        turret.insert(ammo)
    end
end

local function do_magic_crafters()
    local index = magic_crafters.index

    if index > #magic_crafters then
        magic_crafters.index = 1
        return
    end

    local data = magic_crafters[index]

    local entity = data.entity
    if not entity.valid then
        fast_remove(magic_crafters, index)
        return
    end

    magic_crafters.index = index + 1

    local tick = game.tick
    local last_tick = data.last_tick
    local rate = data.rate

    local count = (tick - last_tick) * rate

    local fcount = math.floor(count)

    if fcount > 0 then
        local fluidbox_index = data.fluidbox_index
        if fluidbox_index then
            local fb = entity.fluidbox

            local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
            fb_data.amount = fb_data.amount + fcount
            fb[fluidbox_index] = fb_data
        else
            entity.get_output_inventory().insert {name = data.item, count = fcount}
        end
        data.last_tick = tick - (count - fcount) / rate
    end
end

local function tick()
    do_refill_turrets()
    do_magic_crafters()
end

Public.refill_turret_callback =
    Token.register(
    function(turret, ammo)
        table.insert(refill_turrets, {turret = turret, ammo = ammo})
    end
)

Public.refill_liquid_turret_callback =
    Token.register(
    function(turret, ammo)
        table.insert(refill_turrets, {turret = turret, ammo = ammo, liquid = true})
    end
)

Public.power_source_callback =
    Token.register(
    function(entity, data)
        local power_source =
            entity.surface.create_entity {name = 'hidden-electric-energy-interface', position = entity.position}
        power_source.electric_buffer_size = data.buffer_size
        power_source.power_production = data.power_production

        power_sources[entity.unit_number] = power_source
    end
)

local function add_magic_crafter_output(entity, output, distance)
    local rate = output.min_rate + output.distance_factor * distance
    table.insert(
        magic_crafters,
        {
            entity = entity,
            last_tick = game.tick,
            rate = rate,
            item = output.item,
            fluidbox_index = output.fluidbox_index
        }
    )
end

local set_inactive_token =
    Token.register(
    function(entity)
        if entity.valid then
            entity.active = false
        end
    end
)

Public.magic_item_crafting_callback =
    Token.register(
    function(entity, data)
        entity.minable = false
        entity.operable = false
        entity.destructible = false

        local recipe = data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = data.furance_item
            if furance_item then
                local inv = entity.get_inventory(2) -- defines.inventory.furnace_source
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local distance = math.sqrt(p.x * p.x + p.y * p.y)

        local output = data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for _, o in ipairs(data.output) do
                add_magic_crafter_output(entity, o, distance)
            end
        end

        Task.set_timeout_in_ticks(1, set_inactive_token, entity)
    end
)

Public.deactivate_callback =
    Token.register(
    function(entity)
        entity.active = false
        entity.operable = false
        entity.destructible = false
    end
)

local function remove_power_source(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local number = entity.unit_number
    local ps = power_sources[number]
    power_sources[number] = nil

    if ps and ps.valid then
        ps.destroy()
    end
end

Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}

Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_entity_died, remove_power_source)

return Public
