--RedMew's 2019 turkey/thanksgiving map! Thanks to all the contributors from world_map_thanksgiving.lua and to TheKidOZ.
local b = require "map_gen.shared.builders"
local Random = require 'map_gen.shared.random'
local table = require 'utils.table'
local pic = require "map_gen.data.presets.turkey"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local turkey_message_random = require 'resources.turkey_messages'

RS.set_map_gen_settings(
    {
        MGSP.cliff_none
    }
)


--everything from here to line 145 is all to generate the fancy ore; it should prob be cleaned up at some point.
local ore_seed = 3000

local turkey_pic = require 'map_gen.data.presets.turkey_bw'
local turkey = b.picture(turkey_pic)
turkey = b.invert(turkey)
local bounds = b.rectangle(turkey_pic.width, turkey_pic.height)
turkey = b.all {bounds, turkey}

local ham = b.picture(require 'map_gen.data.presets.ham')

ham = b.scale(ham, 64 / 127) --0.5
turkey = b.scale(turkey, 0.2)

local function value(base, mult, pow)
    return function(x, y)
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local function non_transform(shape)
    return shape
end

local function uranium_transform(shape)
    return b.scale(shape, 0.5)
end

local function oil_transform(shape)
    shape = b.scale(shape, 0.3)
    shape = b.throttle_world_xy(shape, 1, 5, 1, 5)
    return shape
end

local ores = {
    {weight = 150},
    {transform = non_transform, resource = 'iron-ore', value = value(250, 0.75, 1.2), weight = 16},
    {transform = non_transform, resource = 'copper-ore', value = value(200, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(125, 0.3, 1.05), weight = 7},
    {transform = non_transform, resource = 'coal', value = value(200, 0.8, 1.075), weight = 8},
    {transform = uranium_transform, resource = 'uranium-ore', value = value(100, 0.3, 1.025), weight = 3},
    {transform = oil_transform, resource = 'crude-oil', value = value(100000, 50, 1.1), weight = 6}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(ore_seed, ore_seed * 2)
local ore_pattern = {}

for r = 1, 50 do
    local row = {}
    ore_pattern[r] = row
    local even_r = r % 2 == 0
    for c = 1, 50 do
        local even_c = c % 2 == 0
        local shape
        if even_r == even_c then
            shape = turkey
        else
            shape = ham
        end

        local i = random_ore:next_int(1, ore_t)
        local index = table.binary_search(total_ore_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        local ore_data = ores[index]

        local transform = ore_data.transform
        if not transform then
            row[c] = b.no_entity
        else
            local ore_shape = transform(shape)
            --local ore_shape = shape

            local x = random_ore:next_int(-24, 24)
            local y = random_ore:next_int(-24, 24)
            ore_shape = b.translate(ore_shape, x, y)

            local ore = b.resource(ore_shape, ore_data.resource, ore_data.value)
            row[c] = ore
        end
    end
end

local start_turkey =
    b.segment_pattern {
    b.resource(
        turkey,
        'iron-ore',
        function()
            return 1000
        end
    ),
    b.resource(
        turkey,
        'copper-ore',
        function()
            return 500
        end
    ),
    b.resource(
        turkey,
        'coal',
        function()
            return 750
        end
    ),
    b.resource(
        turkey,
        'stone',
        function()
            return 300
        end
    )
}

ore_pattern[1][1] = start_turkey

local ore_grid = b.grid_pattern_full_overlap(ore_pattern, 50, 50, 96, 96)

ore_grid = b.translate(ore_grid, -60, -20)

--spews a random turkey fact in chat every 10 minutes.
Event.add(
    defines.events.on_tick,
    function(event)
	    if event.tick % 36000 == 0 then
            local message = turkey_message_random[math.random(#turkey_message_random)]
            game.print('[color=yellow][font=compi]' .. message .. '[/font][/color]')
	    end
    end
)


pic = b.decompress(pic)

--idk why this works but it does, played whack a mole/whack a variable to get it to clear all errors
local shape = b.picture(pic)
shape = b.scale(shape, 4, 4)
shape = b.translate(shape, -300, 500)
shape = b.apply_entity(shape, ore_grid)
return shape
