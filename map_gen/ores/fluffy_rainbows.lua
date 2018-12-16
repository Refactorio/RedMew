--Author: MewMew / (Threaded by Valansch)

local perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

--SETTINGS:
local width_modifier = 0.8
local ore_base_amounts = {
    ['iron-ore'] = 700,
    ['coal'] = 400,
    ['copper-ore'] = 400,
    ['stone'] = 400,
    ['uranium-ore'] = 400
}

local function init()
    global.perlin_noise_seed = RS.get_surface().map_gen_settings.seed
    -- math.random(1000, 1000000)
end

Event.on_init(init)

local function do_resource(name, x, y, world, noise_terrain, noise_band_high, noise_band_low, seed)
    if noise_terrain > -noise_band_high * width_modifier and noise_terrain <= -noise_band_low * width_modifier then
        local noise_resource_amount_modifier = perlin.noise(((x + seed) / 200), ((y + seed) / 200), 0)
        local resource_amount =
            1 +
            ((ore_base_amounts[name] + (ore_base_amounts[name] * noise_resource_amount_modifier * 0.2)) *
                world.amount_distance_multiplicator)

        return {name = name, amount = resource_amount}
    end
end

return function(x, y, world)
    if not world.amount_distance_multiplicator then
        local distance = math.sqrt(world.x * world.x + world.y * world.y)
        local amount_distance_multiplicator = (((distance + 1) / 75) / 75) + 1
        world.amount_distance_multiplicator = amount_distance_multiplicator
    end

    --[[ local entities = world.surface.find_entities_filtered {position = {world.x + 0.5, world.y + 0.5}, type = 'resource'}
    for _, e in ipairs(entities) do
        if e.name ~= 'crude-oil' then
            e.destroy()
        end
    end ]]

    local seed = global.perlin_noise_seed

    local noise_terrain_1 = perlin.noise(((x + seed) / 350), ((y + seed) / 350), 0)
    local noise_terrain_2 = perlin.noise(((x + seed) / 50), ((y + seed) / 50), 0)
    local noise_terrain = noise_terrain_1 + (noise_terrain_2 * 0.01)

    return do_resource('iron-ore', x, y, world, noise_terrain, 0.11, 0.085, seed) or
        do_resource('copper-ore', x, y, world, noise_terrain, 0.085, 0.06, seed) or
        do_resource('stone', x, y, world, noise_terrain, 0.06, 0.05, seed) or
        do_resource('coal', x, y, world, noise_terrain, 0.05, 0.03, seed) or
        do_resource('uranium-ore', x, y, world, noise_terrain, 0.02, 0.01, seed)
end
