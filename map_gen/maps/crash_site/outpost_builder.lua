--local Random = require 'map_gen.shared.random'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Retailer = require 'features.retailer'
local PlayerStats = require 'features.player_stats'
local Donator = require 'features.donator'
local RS = require 'map_gen.shared.redmew_surface'
local Server = require 'features.server'
local CrashSiteToast = require 'map_gen.maps.crash_site.crash_site_toast'

local table = require 'utils.table'
--local next = next
local pairs = pairs
local concat = table.concat
local floor = math.floor
local format = string.format
local tostring = tostring
local draw_text = rendering.draw_text
local render_mode_game = defines.render_mode.game

local b = require 'map_gen.shared.builders'

local direction_bit_mask = 0xc0000000
local section_bit_mask = 0x30000000
local level_bit_mask = 0x0fffffff
--local not_level_bit_mask = 0xf0000000
local direction_bit_shift = 30
local section_bit_shift = 28

--local section_straight = 0
--local section_outer_corner = 1
--local section_inner_corner = 2

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

local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8

local refill_turrets = {index = 1}
local power_sources = {}
local turret_to_outpost = {}
local magic_crafters = {index = 1}
local magic_fluid_crafters = {index = 1}
local outposts = {}
local artillery_outposts = {index = 1}
local outpost_count = 0

Global.register(
    {
        refil_turrets = refill_turrets,
        power_sources = power_sources,
        turret_to_outpost = turret_to_outpost,
        magic_crafters = magic_crafters,
        magic_fluid_crafters = magic_fluid_crafters,
        outposts = outposts,
        artillery_outposts = artillery_outposts
    },
    function(tbl)
        refill_turrets = tbl.refil_turrets
        power_sources = tbl.power_sources
        turret_to_outpost = tbl.turret_to_outpost
        magic_crafters = tbl.magic_crafters
        magic_fluid_crafters = tbl.magic_fluid_crafters
        outposts = tbl.outposts
        artillery_outposts = tbl.artillery_outposts
    end
)

--[[ local function get_direction(part)
    local dir = bit32.band(part, direction_bit_mask)
    return bit32.rshift(dir, direction_bit_shift - 1)
end ]]
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

--[[ local function set_level(part, level)
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
end ]]
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
            anti_stack[#anti_stack + 1] = {x = x, y = 1}
        end

        if blocks[x + y_offset] == nil then
            anti_stack[#anti_stack + 1] = {x = x, y = size}
        end
    end

    for y = 2, size do
        y_offset = (y - 1) * size
        if blocks[y_offset + 1] == nil then
            anti_stack[#anti_stack + 1] = {x = 1, y = y}
        end

        if blocks[y_offset + size] == nil then
            anti_stack[#anti_stack + 1] = {x = size, y = y}
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
                anti_stack[#anti_stack + 1] = {x = x2, y = y}
            end
        end
        if x < size then
            local x2 = x + 1
            local offset2 = offset + 1

            if not anti_set[offset2] and not blocks[offset2] then
                anti_stack[#anti_stack + 1] = {x = x2, y = y}
            end
        end
        if y > 1 then
            local y2 = y - 1
            local offset2 = offset - size

            if not anti_set[offset2] and not blocks[offset2] then
                anti_stack[#anti_stack + 1] = {x = x, y = y2}
            end
        end
        if y < size then
            local y2 = y + 1
            local offset2 = offset + size

            if not anti_set[offset2] and not blocks[offset2] then
                anti_stack[#anti_stack + 1] = {x = x, y = y2}
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

                local lvl = levels[l]
                lvl[#lvl + 1] = i
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
            for index = 1, #level do
                local i = level[index]
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
            --magic_fluid_crafters = {},
            market = nil,
            turret_count = 0,
            top_left = {nil, nil},
            bottom_right = {nil, nil},
            level = 1,
            upgrade_rate = nil,
            upgrade_base_cost = nil,
            upgrade_cost_base = nil,
            artillery_area = nil,
            artillery_turrets = nil,
            last_fire_tick = nil
        }
    end

    local function shape(x, y, world)
        x, y = floor(x + half_t_size), floor(y + half_t_size)
        if x < 0 or y < 0 or x >= t_size or y >= t_size then
            return false
        end

        local x2, y2 = floor(x * inv_part_size), floor(y * inv_part_size)

        local template = blocks[y2 * size + x2 + 1]
        if not template then
            return false
        end

        local wx, wy = world.x, world.y

        local entities =
            world.surface.find_entities_filtered {
            area = {{wx, wy}, {wx + 1, wy + 1}},
            type = remove_entity_types
        }
        for i = 1, #entities do
            local e = entities[i]
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

local function update_market_upgrade_description(outpost_data)
    local outpost_id = outpost_data.outpost_id

    local upgrade_rate = outpost_data.upgrade_rate
    local upgrade_base_cost = outpost_data.upgrade_base_cost
    local upgrade_cost_base = outpost_data.upgrade_cost_base
    local level = outpost_data.level
    local base_outputs = outpost_data.base_outputs
    local outpost_magic_crafters = outpost_data.magic_crafters
    local prototype = Retailer.get_items(outpost_id)['upgrade']

    prototype.price = upgrade_base_cost * #outpost_magic_crafters * upgrade_cost_base ^ (level - 1)
    prototype.name_label = 'Upgrade Outpost to level ' .. tostring(level + 1)

    local tooltip_str = {''}
    local mapview_str = {''}
    local count = 2
    for k, v in pairs(base_outputs) do
        local base_rate = v * 60
        local upgrade_per_level = base_rate * upgrade_rate
        local current_rate = base_rate + (level - 1) * upgrade_per_level
        local next_rate = current_rate + upgrade_per_level

        local name = game.item_prototypes[k]
        if name then
            tooltip_str[count] = concat {'[item=', k, ']'}
            mapview_str[count] = name.localised_name
        else
            name = game.fluid_prototypes[k]
            if name then
                tooltip_str[count] = concat {'[fluid=', k, ']'}
                mapview_str[count] = name.localised_name
            else
                tooltip_str[count] = k
                mapview_str[count] = k
            end
        end
        count = count + 1

        local str = concat {': ', format('%.2f', current_rate), ' -> ', format('%.2f / sec', next_rate)}

        tooltip_str[count] = str
        tooltip_str[count + 1] = '\n'

        mapview_str[count] = str
        mapview_str[count + 1] = ', '

        count = count + 2
    end
    tooltip_str[count - 1] = nil
    mapview_str[count - 1] = nil

    prototype.description = tooltip_str
    prototype.disabled = false

    prototype.mapview_description = mapview_str

    Retailer.set_item(outpost_id, prototype)
end

local function do_outpost_upgrade(event)
    if event.item.type ~= 'upgrade' then
        return
    end

    local outpost_id = event.group_name
    local outpost_data = outposts[outpost_id]

    local outpost_magic_crafters = outpost_data.magic_crafters
    local upgrade_rate = outpost_data.upgrade_rate

    local level = outpost_data.level + 1
    outpost_data.level = level

    local outpost_name = Retailer.get_market_group_label(outpost_id)
    local message = concat {outpost_name, ' has been upgraded to level ', level}

    CrashSiteToast.do_outpost_toast(outpost_data.market, message)
    Server.to_discord_bold(concat {'*** ', message, ' ***'})

    for i = 1, #outpost_magic_crafters do
        local crafter = outpost_magic_crafters[i]

        local rate = crafter.rate
        local upgrade_amount = upgrade_rate * crafter.base_rate

        crafter.rate = rate + upgrade_amount
    end

    update_market_upgrade_description(outpost_data)
end

local function activate_market_upgrade(outpost_data)
    local outpost_magic_crafters = outpost_data.magic_crafters

    if #outpost_magic_crafters == 0 then
        local outpost_id = outpost_data.outpost_id

        local prototype = Retailer.get_items(outpost_id)['upgrade']
        prototype.disabled_reason = 'No machines to upgrade.'

        Retailer.set_item(outpost_id, prototype)

        return
    end

    local base_outputs = {}

    for i = 1, #outpost_magic_crafters do
        local crafter = outpost_magic_crafters[i]
        local item = crafter.item

        local count = base_outputs[item] or 0
        count = count + crafter.rate

        base_outputs[item] = count
    end

    outpost_data.base_outputs = base_outputs

    update_market_upgrade_description(outpost_data)
end

function Public.activate_market_upgrade(outpost_id)
    local outpost_data = outposts[outpost_id]
    activate_market_upgrade(outpost_data)
end

local function do_capture_outpost(outpost_data)
    local area = {top_left = outpost_data.top_left, bottom_right = outpost_data.bottom_right}
    local walls = RS.get_surface().find_entities_filtered {area = area, force = 'enemy', name = 'stone-wall'}

    for i = 1, #walls do
        walls[i].force = 'player'
    end

    local outpost_id = outpost_data.outpost_id

    local name = Retailer.get_market_group_label(outpost_id)
    if name == 'Market' then
        return
    end

    local donators = Donator.get_donators_table()
    if next(donators) then
        local donator = table.get_random_dictionary_entry(donators, true)
        if donator then
            name = concat({donator, "'s ", name})
            Retailer.set_market_group_label(outpost_id, name)
        end
    end

    local message = 'Outpost captured: ' .. name
    CrashSiteToast.do_outpost_toast(outpost_data.market, message)
    Server.to_discord_bold(concat {'*** ', message, ' ***'})

    activate_market_upgrade(outpost_data)
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

local artillery_target_entities = {
    'player',
    'tank',
    'car',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon'
}
local function do_artillery_turrets_targets()
    local index = artillery_outposts.index

    if index > #artillery_outposts then
        artillery_outposts.index = 1
        return
    end

    artillery_outposts.index = index + 1

    local outpost = artillery_outposts[index]

    local now = game.tick
    if now - outpost.last_fire_tick < 300 then
        return
    end

    local turrets = outpost.artillery_turrets
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if not turret.valid then
            fast_remove(turrets, i)
        end
    end

    local count = #turrets
    if count == 0 then
        fast_remove(artillery_outposts, index)
        return
    end

    outpost.last_fire_tick = now

    local turret = turrets[1]
    local area = outpost.artillery_area
    local surface = turret.surface

    local entities = surface.find_entities_filtered {area = area, name = artillery_target_entities}

    if #entities == 0 then
        return
    end

    local postion = turret.position
    local tx, ty = postion.x, postion.y

    for i = 1, count do
        local entity = entities[math.random(#entities)]
        if entity and entity.valid then
            local pos = entity.position
            local x, y = pos.x, pos.y
            local dx, dy = tx - x, ty - y
            local d = dx * dx + dy * dy
            if d >= 1024 then -- 32 ^ 2
                surface.create_entity {
                    name = 'artillery-projectile',
                    position = postion,
                    target = entity,
                    speed = 1.5
                }
            end
        end
    end
end

local function do_magic_crafters()
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for i = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                entity.get_output_inventory().insert {name = data.item, count = fcount}
                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for i = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index
                local fb = entity.fluidbox

                local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
                fb_data.amount = fb_data.amount + fcount
                fb[fluidbox_index] = fb_data

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end

local function tick()
    do_refill_turrets()
    do_artillery_turrets_targets()
    do_magic_crafters()
    do_magic_fluid_crafters()
end

Public.refill_turret_callback =
    Token.register(
    function(turret, data)
        local outpost_id = data.outpost_id

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = data.callback_data}
        turret_to_outpost[turret.unit_number] = outpost_id

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

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
        turret_to_outpost[turret.unit_number] = outpost_id

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

Public.refill_artillery_turret_callback =
    Token.register(
    function(turret, data)
        local outpost_id = data.outpost_id

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = data.callback_data}
        turret_to_outpost[turret.unit_number] = outpost_id

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1

        local artillery_turrets = outpost_data.artillery_turrets
        if not artillery_turrets then
            artillery_turrets = {}
            outpost_data.artillery_turrets = artillery_turrets

            local pos = turret.position
            local x, y = pos.x, pos.y
            outpost_data.artillery_area = {{x - 128, y - 128}, {x + 128, y + 128}}
            outpost_data.last_fire_tick = 0

            artillery_outposts[#artillery_outposts + 1] = outpost_data
        end

        artillery_turrets[#artillery_turrets + 1] = turret
    end
)

Public.power_source_callback =
    Token.register(
    function(turret, data)
        local outpost_id = data.outpost_id
        local callback_data = data.callback_data

        local power_source =
            turret.surface.create_entity {name = 'hidden-electric-energy-interface', position = turret.position}
        power_source.electric_buffer_size = callback_data.buffer_size
        power_source.power_production = callback_data.power_production
        power_source.destructible = false

        power_sources[turret.unit_number] = {entity = power_source}
        turret_to_outpost[turret.unit_number] = outpost_id

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

Public.worm_turret_callback =
    Token.register(
    function(turret, data)
        local outpost_id = data.outpost_id

        turret_to_outpost[turret.unit_number] = outpost_id

        local outpost_data = outposts[outpost_id]
        outpost_data.turret_count = outpost_data.turret_count + 1
    end
)

local function add_magic_crafter_output(entity, output, distance, outpost_id)
    local rate = output.min_rate + output.distance_factor * distance

    local fluidbox_index = output.fluidbox_index
    local data = {
        entity = entity,
        last_tick = game.tick,
        base_rate = rate,
        rate = rate,
        item = output.item,
        fluidbox_index = fluidbox_index
    }

    if fluidbox_index then
        magic_fluid_crafters[#magic_fluid_crafters + 1] = data
    else
        magic_crafters[#magic_crafters + 1] = data
    end

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
            for i = 1, #output do
                local o = output[i]
                add_magic_crafter_output(entity, o, distance, outpost_id)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, set_inactive_token, entity) -- causes problems with refineries.
        end
    end
)

Public.magic_item_crafting_callback_weighted =
    Token.register(
    function(entity, data)
        local outpost_id = data.outpost_id
        local callback_data = data.callback_data

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local weights = callback_data.weights
        local loot = callback_data.loot

        local i = math.random() * weights.total

        local index = table.binary_search(weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local stack = loot[index].stack
        if not stack then
            return
        end

        local recipe = stack.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = stack.furance_item
            if furance_item then
                local inv = entity.get_inventory(2) -- defines.inventory.furnace_source
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = math.sqrt(x * x + y * y)

        local output = stack.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance, outpost_id)
        else
            for o_i = 1, #output do
                local o = output[o_i]
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

local function turret_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local number = entity.unit_number
    if not number then
        return
    end

    local ps_data = power_sources[number]
    if ps_data then
        power_sources[number] = nil

        local ps_entity = ps_data.entity

        if ps_entity and ps_entity.valid then
            ps_entity.destroy()
        end
    end

    local outpost_id = turret_to_outpost[number]
    if outpost_id then
        local outpost_data = outposts[outpost_id]

        local turret_count = outpost_data.turret_count - 1
        outpost_data.turret_count = turret_count

        if turret_count == 0 then
            do_capture_outpost(outpost_data)
        end
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
        local outpost_data = outposts[market_id]
        local upgrade_base_cost = callback_data.upgrade_base_cost or 0

        outpost_data.market = entity
        outpost_data.upgrade_rate = callback_data.upgrade_rate
        outpost_data.upgrade_base_cost = upgrade_base_cost
        outpost_data.upgrade_cost_base = callback_data.upgrade_cost_base

        Retailer.add_market(market_id, entity)
        Retailer.set_market_group_label(market_id, callback_data.market_name)

        Retailer.set_item(
            market_id,
            {
                name = 'upgrade',
                type = 'upgrade',
                name_label = 'Upgrade Outpost',
                sprite = 'item-group/production',
                price = 0,
                stack_limit = 1,
                disabled = true,
                disabled_reason = 'Outpost must be captured first.',
                description = 'Increases output.'
            }
        )

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

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

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

local function market_selected(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.render_mode == render_mode_game then
        return
    end

    local selected = player.selected

    if not selected or not selected.valid or selected.name ~= 'market' then
        return
    end

    local group = Retailer.get_market_group_name(selected)
    local prototype = Retailer.get_items(group)['upgrade']

    if prototype.disabled then
        return
    end

    local args = {
        text = nil,
        target = selected,
        target_offset = nil,
        alignment = 'center',
        surface = selected.surface,
        color = {1, 1, 1},
        players = {player},
        scale = 1.5,
        scale_with_zoom = true,
        time_to_live = 180
    }

    args.text = prototype.name_label
    args.target_offset = {0, -6.5}
    draw_text(args)

    args.text = 'Price: ' .. prototype.price
    args.target_offset = {0, -5}
    draw_text(args)

    args.text = prototype.mapview_description
    args.target_offset = {0, -3.5}
    draw_text(args)
end

Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_entity_died, turret_died)

Event.on_init(
    function()
        game.forces.neutral.recipes['steel-plate'].enabled = true
    end
)

Event.add(defines.events.on_player_mined_item, coin_mined)

Event.add(Retailer.events.on_market_purchase, do_outpost_upgrade)

Event.add(defines.events.on_selected_entity_changed, market_selected)

return Public
