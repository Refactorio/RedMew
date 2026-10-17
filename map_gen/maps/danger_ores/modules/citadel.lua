-- Citadel: concentric walls of out-of-map around spawn, each with a few gates.
-- Ring 1 sits at first_ring from spawn and ring 2 ring_spacing further out; from there each
-- gap is ring_growth times the one before, so rings thin out with distance. Walls are a
-- little wobbly so they read as ridges rather than drawn circles. Walls are thicker than undergrounds and
-- pipes can span, so everything crosses at the gates. Gate count grows with the ring's
-- circumference, so gates stay roughly gate_spacing apart on every ring; their angles are
-- seeded per ring. Everything is derived from the seed per tile: nothing is stored.
local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local abs = math.abs
local atan2 = math.atan2
local floor = math.floor
local log = math.log
local max = math.max
local sqrt = math.sqrt
local pi = math.pi
local tau = 2 * pi

local PRIME = 2147483647

return function(config)
    local first_ring = config.citadel_first_ring or 144
    local ring_spacing = config.citadel_ring_spacing or 96
    local ring_growth = config.citadel_ring_growth or 1.1
    local thickness = config.citadel_wall_thickness or 16
    local gate_width = config.citadel_gate_width or 32
    local gate_spacing = config.citadel_gate_spacing or 900
    local wobble_amplitude = config.citadel_wobble_amplitude or 12
    local wobble_scale = config.citadel_wobble_scale or 1 / 96
    local seed = config.citadel_seed or seed_provider()

    local seed_hash = floor(seed) % PRIME
    local function hash01(a, c)
        local h = (seed_hash + a * 7919 + c * 104729) % PRIME
        h = (h * 48271) % PRIME
        h = (h * 48271) % PRIME
        return h / PRIME
    end

    -- radius of ring k: first_ring + ring_spacing * (1 + g + ... + g^(k - 2))
    local function ring_radius(k)
        if ring_growth == 1 then
            return first_ring + (k - 1) * ring_spacing
        end
        return first_ring + ring_spacing * (ring_growth ^ (k - 1) - 1) / (ring_growth - 1)
    end

    -- the ring whose radius is nearest to r: invert ring_radius, then pick the closer of the
    -- two rings either side
    local inv_log_growth = ring_growth ~= 1 and 1 / log(ring_growth)
    local function nearest_ring(r)
        if r <= first_ring then
            return 1
        end
        local below
        if ring_growth == 1 then
            below = floor((r - first_ring) / ring_spacing) + 1
        else
            below = floor(log(1 + (r - first_ring) * (ring_growth - 1) / ring_spacing) * inv_log_growth) + 1
        end
        if r - ring_radius(below) > ring_radius(below + 1) - r then
            return below + 1
        end
        return below
    end

    local half_thickness = thickness / 2
    local outer_reach = half_thickness + wobble_amplitude

    -- Gates of ring k: count, rotation and per-gate jitter, cached since every tile of the
    -- ring asks. Pure function of the seed, so the cache is safe to rebuild after load.
    local gates = {}
    local function gates_of(k)
        local g = gates[k]
        if g then
            return g
        end

        local radius = ring_radius(k)
        local count = max(2, floor(tau * radius / gate_spacing + 0.5))
        local step = tau / count
        local rotation = hash01(k, 0) * tau
        local angles = {}
        for i = 1, count do
            -- jitter up to a quarter step either way keeps gates spread around the ring
            angles[i] = rotation + (i - 1 + (hash01(k, i) - 0.5) * 0.5) * step
        end
        g = {angles = angles, half_angle = gate_width / 2 / radius}
        gates[k] = g
        return g
    end

    return function(x, y)
        local r = sqrt(x * x + y * y)
        if r < first_ring - outer_reach then
            return false
        end

        local k = nearest_ring(r)
        local radius = ring_radius(k)
        if abs(r - radius) > outer_reach then
            return false
        end

        local wobble = wobble_amplitude * perlin_noise(x * wobble_scale, y * wobble_scale, seed)
        if abs(r - radius - wobble) > half_thickness then
            return false
        end

        local theta = atan2(y, x)
        local g = gates_of(k)
        local half_angle = g.half_angle
        for _, angle in pairs(g.angles) do
            local d = (theta - angle) % tau
            if d > pi then
                d = d - tau
            end
            if abs(d) <= half_angle then
                return false
            end
        end

        return 'out-of-map'
    end
end
