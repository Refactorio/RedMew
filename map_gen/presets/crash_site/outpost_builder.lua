local Random = require 'map_gen.shared.random'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Retailer = require 'features.retailer'
local PlayerStats = require 'features.player_stats'
local RS = require 'map_gen.shared.redmew_surface'
local Server = require 'features.server'
local Color = require 'resources.color_presets'

local table = require 'utils.table'
local next = next
local concat = table.concat

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

local default_part_size = 6
--local inv_part_size = 1 / part_size

local refill_turrets = {index = 1}
local power_sources = {}
local magic_crafters = {index = 1}
local outposts = {}
local outpost_count = 0

Global.register(
    {
        refil_turrets = refill_turrets,
        power_sources = power_sources,
        magic_crafters = magic_crafters,
        outposts = outposts
    },
    function(tbl)
        refill_turrets = tbl.refil_turrets
        power_sources = tbl.power_sources
        magic_crafters = tbl.magic_crafters
        outposts = tbl.outposts
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

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local Public = {}
Public.__index = Public

Public.empty_template = {}

function Public.new(random)
    local obj = {random = random}

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
                --blocks[i] = wall_west_outer
                blocks[i] = wall_north_outer
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
    local size = blocks.size
    local level = 2

    while level < max_level do
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
    end

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

local function get_template(random, templates, templates_count, counts)
    local template
    if templates_count == 0 then
        return nil
    elseif templates_count == 1 then
        template = templates[1]
    else
        local ti = random:next_int(1, templates_count)
        template = templates[ti]
    end

    if template == Public.empty_template then
        return nil
    end

    local count = counts[template] or 0
    local max_count = template.max_count

    while count == max_count do
        template = template.fallback
        if template == nil then
            return nil
        end
        count = counts[template] or 0
        max_count = template.max_count
    end

    counts[template] = count + 1

    return template
end

local function make_blocks(self, blocks, template)
    local random = self.random
    local counts = {}

    local levels = blocks.levels
    local wall_level = levels[1]

    local walls = template.walls
    local wall_template_count = #walls

    while #wall_level > 0 do
        local index = random:next_int(1, #wall_level)
        local i = wall_level[index]

        fast_remove(wall_level, index)

        local block = get_template(random, walls, wall_template_count, counts)

        if block == Public.empty_template then
            blocks[i] = nil
        else
            local block_data = blocks[i]

            local section = get_section(block_data)
            local dir = get_4_way_direction(block_data)

            local new_block = block[section + 1][dir + 1]
            blocks[i] = new_block
        end
    end

    local bases = template.bases

    for l = 2, #levels do
        local level = levels[l]
        local base_templates = bases[l - 1]

        if base_templates then
            local base_template_count = #base_templates

            while #level > 0 do
                local index = random:next_int(1, #level)
                local i = level[index]

                fast_remove(level, index)

                blocks[i] = get_template(random, base_templates, base_template_count, counts)
            end
        else
            for _, i in ipairs(level) do
                blocks[i] = nil
            end
        end
    end
end

local remove_entity_types = {'tree', 'simple-entity'}

local function to_shape(blocks, part_size, on_init)
    part_size = part_size or default_part_size
    local inv_part_size = 1 / part_size
    local size = blocks.size
    local t_size = size * part_size
    local half_t_size = t_size * 0.5

    local outpost_id = outpost_count + 1
    outpost_count = outpost_id

    if on_init then
        outposts[outpost_id] = {
            outpost_id = outpost_id,
            magic_crafters = {},
            turret_count = 0,
            top_left = {nil, nil},
            bottom_right = {nil, nil}
        }
    end

    local function shape(x, y, world)
        x, y = math.floor(x + half_t_size), math.floor(y + half_t_size)
        if x < 0 or y < 0 or x >= t_size or y >= t_size then
            return false
        end

        local x2, y2 = math.floor(x * inv_part_size), math.floor(y * inv_part_size)

        local template = blocks[y2 * size + x2 + 1]
        if not template then
            return false
        end

        local wx, wy = world.x, world.y
        for _, e in ipairs(
            world.surface.find_entities_filtered(
                {
                    area = {{wx, wy}, {wx + 1, wy + 1}},
                    type = remove_entity_types
                }
            )
        ) do
            e.destroy()
        end

        local x3, y3 = x - x2 * part_size, y - y2 * part_size

        local i = y3 * part_size + x3 + 1

        local entry = template[i]
        if not entry then
            return false
        end

        local entity = entry.entity
        local tile = entry.tile or true
        if entity then
            local data
            local callback = entity.callback
            if callback then
                data = {outpost_id = outpost_id}
                local cd = template[callback]

                callback = cd.callback
                data.callback_data = cd.data
            end

            return {
                tile = tile,
                entities = {
                    {
                        name = entity.name,
                        direction = entity.direction,
                        force = entity.force or template.force,
                        callback = callback,
                        data = data,
                        always_place = true
                    }
                }
            }
        end
        return tile
    end

    return b.change_map_gen_collision_hidden_tile(shape, 'water-tile', 'grass-1')
end

Public.to_shape = to_shape

function Public:do_outpost(template, on_init)
    local settings = template.settings
    local blocks = {size = settings.blocks}

    do_walls(self, blocks, settings.variance, settings.min_step)
    fill(blocks)
    do_levels(blocks, settings.max_level)
    make_blocks(self, blocks, template)

    return to_shape(blocks, settings.part_size, on_init)
end

local function change_direction(entity, new_dir)
    local copy = {}

    for k, v in pairs(entity) do
        copy[k] = v
    end
    copy.direction = new_dir

    return copy
end

function Public.make_1_way(data)
    data.__index = data
    return data
end

local function set_tile(tbl, index, tile)
    local entry = tbl[index]
    if entry then
        entry.tile = tile
    else
        tbl[index] = {tile = tile}
    end
end

local function set_entity(tbl, index, entity)
    local entry = tbl[index]

    if entry then
        entry.entity = entity
    else
        tbl[index] = {entity = entity}
    end
end

function Public.make_4_way(data)
    local part_size = data.part_size or default_part_size
    local inv_part_size = 1 / part_size

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

            local x2 = part_size - y + 1
            local y2 = x
            local x3 = part_size - x + 1
            local y3 = part_size - y + 1
            local x4 = y
            local y4 = part_size - x + 1

            local i2 = (y2 - 1) * part_size + x2
            local i3 = (y3 - 1) * part_size + x3
            local i4 = (y4 - 1) * part_size + x4

            local tile = entry.tile
            if tile then
                set_tile(north, i, tile)
                set_tile(east, i2, tile)
                set_tile(south, i3, tile)
                set_tile(west, i4, tile)
            end

            local entity = entry.entity

            if entity then
                local offset = entity.offset

                if offset == 3 then
                    i = i + part_size + 1
                    i2 = i2 + part_size
                    i4 = i4 + 1
                elseif offset == 1 then
                    i = i + 1
                    i2 = i2 + part_size
                elseif offset == 2 then
                    i = i + part_size
                    i4 = i4 + 1
                end

                local dir = entity.direction or 0

                set_entity(north, i, entity)
                set_entity(east, i2, change_direction(entity, (dir + 2) % 8))
                set_entity(south, i3, change_direction(entity, (dir + 4) % 8))
                set_entity(west, i4, change_direction(entity, (dir + 6) % 8))
            end
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

function Public.make_walls(data)
    data.__index = data
    return data
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
    local copy = shallow_copy(tbl)

    local base = {
        Public.extend_4_way(data[1], copy),
        Public.extend_4_way(data[2], copy),
        Public.extend_4_way(data[3], copy)
    }
    base.__index = base

    return setmetatable(copy, base)
end

local function change_wall_ownership(outpost_data)
    local area = {top_left = outpost_data.top_left, bottom_right = outpost_data.bottom_right}
    local walls = RS.get_surface().find_entities_filtered {area = area, force = 'enemy', name = 'stone-wall'}

    for i = 1, #walls do
        walls[i].force = 'player'
    end

    local name = Retailer.get_market_group_label(outpost_data.outpost_id)
    if name ~= 'Market' then
        game.print(concat({'*** ', 'Outpost captured: ' .. name, ' ***'}), Color.lime_green)
        Server.to_discord_bold('Outpost captured: ' .. name)
    end
end

local function do_refill_turrets()
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)

        local outpost_data = outposts[turret_data.outpost_id]

        local turret_count = outpost_data.turret_count - 1
        outpost_data.turret_count = turret_count

        if turret_count == 0 then
            change_wall_ownership(outpost_data)
        end

        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.fluidbox[1] = data
    elseif data then
        turret.insert(data)
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
    function(turret, data)
        local outpost_id = data.outpost_id

        refill_turrets[#refill_turrets + 1] = {outpost_id = outpost_id, turret = turret, data = data.callback_data}

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

Public.refill_liquid_turret_callback =
    Token.register(
    function(turret, data)
        local callback_data = data.callback_data
        callback_data.liquid = true

        local outpost_id = data.outpost_id

        refill_turrets[#refill_turrets + 1] = {outpost_id = outpost_id, turret = turret, data = callback_data}

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

Public.power_source_callback =
    Token.register(
    function(entity, data)
        local outpost_id = data.outpost_id
        local callback_data = data.callback_data

        local power_source =
            entity.surface.create_entity {name = 'hidden-electric-energy-interface', position = entity.position}
        power_source.electric_buffer_size = callback_data.buffer_size
        power_source.power_production = callback_data.power_production
        power_source.destructible = false

        power_sources[entity.unit_number] = {outpost_id = outpost_id, entity = power_source}

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

local function add_magic_crafter_output(entity, output, distance, outpost_id)
    local rate = output.min_rate + output.distance_factor * distance

    local data = {
        entity = entity,
        last_tick = game.tick,
        rate = rate,
        item = output.item,
        fluidbox_index = output.fluidbox_index
    }

    magic_crafters[#magic_crafters + 1] = data
    local outpost_magic_crafters = outposts[outpost_id].magic_crafters
    outpost_magic_crafters[#outpost_magic_crafters + 1] = data
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
        local outpost_id = data.outpost_id
        local callback_data = data.callback_data

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local recipe = callback_data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = callback_data.furance_item
            if furance_item then
                local inv = entity.get_inventory(2) -- defines.inventory.furnace_source
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = math.sqrt(x * x + y * y)

        local output = callback_data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance, outpost_id)
        else
            for _, o in ipairs(callback_data.output) do
                add_magic_crafter_output(entity, o, distance, outpost_id)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, set_inactive_token, entity) -- causes problems with refineries.
        end
    end
)

Public.wall_callback =
    Token.register(
    function(entity, data)
        if not entity.valid then
            return
        end

        local position = entity.position
        local px, py = position.x, position.y

        local outpost_id = data.outpost_id
        local outpost_data = outposts[outpost_id]
        local top_left = outpost_data.top_left
        local bottom_right = outpost_data.bottom_right
        local tx, ty = top_left.x, top_left.y
        local bx, by = bottom_right.x, bottom_right.y

        if not tx or px < tx then
            top_left.x = px
        end
        if not ty or py < ty then
            top_left.y = py
        end

        if not bx or px > bx then
            bottom_right.x = px
        end
        if not by or py > by then
            bottom_right.y = py
        end
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
    if not number then
        return
    end

    local data = power_sources[number]
    if not data then
        return
    end

    power_sources[number] = nil

    local ps_entity = data.entity

    if ps_entity and ps_entity.valid then
        ps_entity.destroy()
    end

    local outpost_data = outposts[data.outpost_id]

    local turret_count = outpost_data.turret_count - 1
    outpost_data.turret_count = turret_count

    if turret_count == 0 then
        change_wall_ownership(outpost_data)
    end
end

Public.market_set_items_callback =
    Token.register(
    function(entity, data)
        if not entity.valid then
            return
        end

        local callback_data = data.callback_data

        entity.destructible = false

        local market_id = data.outpost_id
        Retailer.add_market(market_id, entity)
        Retailer.set_market_group_label(market_id, callback_data.market_name)

        local p = entity.position
        local x, y = p.x, p.y
        local d = math.sqrt(x * x + y * y)

        for i = 1, #callback_data do
            local item = callback_data[i]
            local price = item.price

            local df = item.distance_factor
            if df then
                local min_price = item.min_price or 1

                price = item.price - d * df
                price = math.max(price, min_price)
            end

            Retailer.set_item(
                market_id,
                {name = item.name, price = price, name_label = item.name_label, description = item.description}
            )
        end
    end
)

Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}

Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for _, v in ipairs(loot) do
        total = total + v.weight
        table.insert(weights, total)
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    entity.destructible = false

    local i = math.random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = math.sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert {name = stack.name, count = count}
end

function Public.do_random_fluid_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    entity.destructible = false

    local i = math.random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = math.sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.fluidbox[1] = {name = stack.name, amount = count}
end

function Public.do_factory_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    entity.destructible = false

    local i = math.random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = math.sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    local name = stack.name

    entity.set_recipe(name)
    entity.get_output_inventory().insert {name = name, count = count}
end

local function coin_mined(event)
    local stack = event.item_stack
    if stack.name == 'coin' then
        PlayerStats.change_coin_earned(event.player_index, stack.count)
    end
end

Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_entity_died, remove_power_source)

Event.on_init(
    function()
        game.forces.neutral.recipes['steel-plate'].enabled = true
    end
)

Event.add(defines.events.on_player_mined_item, coin_mined)

return Public
