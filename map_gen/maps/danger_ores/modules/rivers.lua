-- Rivers: rivers spring up at the edge of spawn and flow outward, in place of the usual
-- perlin lakes. They start as thin streams, meander more and widen as they go, so fords
-- that undergrounds and pipes can span are common near spawn and wide water that needs
-- landfill is common further out.
--
-- Layout: `rivers_count` rivers leave spawn at evenly spaced angles. Rivers fan apart with
-- distance, so whenever the gap between neighbours would pass twice `rivers_spacing`, every
-- river branches off a new one that drifts over to the middle of the gap (a delta). Level l
-- has count * 2^l rivers in angle order; river j of level l continues as river 2j of level
-- l + 1 and the new branch is river 2j + 1. All of it is derived from the seed per tile, so
-- nothing is stored and chunks generate the same in any order.
--
-- A river's centre line is its angle plus a lateral meander (two octaves of noise along
-- its length). A tile's distance to it is the arc distance at the tile's radius, corrected
-- by the river's slope so the width stays true where it runs across rather than outward.
local Perlin = require 'map_gen.shared.perlin_noise'
local seed_provider = require 'map_gen.maps.danger_ores.modules.seed_provider'

local perlin_noise = Perlin.noise
local abs = math.abs
local atan2 = math.atan2
local floor = math.floor
local log = math.log
local sqrt = math.sqrt
local pi = math.pi
local tau = 2 * pi

local MAX_LEVEL = 10
local PRIME = 2147483647

local function clamp01(v)
    if v < 0 then
        return 0
    elseif v > 1 then
        return 1
    end
    return v
end

local function wrap_angle(a)
    a = a % tau
    if a > pi then
        a = a - tau
    end
    return a
end

return function(config)
    local count = config.rivers_count or 6
    local start_radius = config.rivers_start_radius or 64
    local spacing = config.rivers_spacing or 400
    local min_width = config.rivers_min_width or 6
    local max_width = config.rivers_max_width or 20
    local width_ramp = config.rivers_width_ramp or 768
    local width_scale = config.rivers_width_scale or 1 / 160
    local source_length = config.rivers_source_length or 48
    local bank_width = config.rivers_bank_width or 3
    local bank_noise_scale = config.rivers_bank_noise_scale or 1 / 12
    local bank_noise_amplitude = config.rivers_bank_noise_amplitude or 1.5
    local meander_amplitude = config.rivers_meander_amplitude or 96
    local meander_scale = config.rivers_meander_scale or 1 / 256
    local wiggle_amplitude = config.rivers_wiggle_amplitude or 24
    local wiggle_scale = config.rivers_wiggle_scale or 1 / 64
    local meander_ramp = config.rivers_meander_ramp or 256
    local seed = config.rivers_seed or seed_provider()
    local width_seed = config.rivers_width_seed or seed_provider()

    local seed_hash = floor(seed) % PRIME
    local function hash01(a, c)
        local h = (seed_hash + a * 7919 + c * 104729) % PRIME
        h = (h * 48271) % PRIME
        h = (h * 48271) % PRIME
        return h / PRIME
    end

    local offset = hash01(0, 0) * tau
    -- gap between neighbours is 2 * pi * r / (count * 2^l); level l starts where it would
    -- reach twice the spacing at level l - 1
    local first_branch_radius = spacing * count / pi
    local inv_log2 = 1 / log(2)
    local width_range = max_width - min_width
    local meander_bound = meander_amplitude + wiggle_amplitude
    local reach = 3 * (max_width / 2) + bank_noise_amplitude

    -- Follows a river back to the level it branched off at: (level, index) of its birth.
    local function origin(level, j)
        while level > 0 and j % 2 == 0 do
            level = level - 1
            j = j / 2
        end
        return level, j
    end

    -- Meander of the river born as (bl, bj), in tiles across its course.
    local function lateral(bl, bj, r, amplitude)
        local id = bl * 4099 + bj + 0.31
        return amplitude * (meander_amplitude * perlin_noise(r * meander_scale, id * 3.7, seed) + wiggle_amplitude * perlin_noise(r * wiggle_scale, id * 3.7 + 0.5, seed))
    end

    -- A branch born as (bl, bj), bl >= 1, forks off its parent (the river in the previous
    -- lane) at 1.0 to 1.4 times its level's radius, then drifts into its own lane over 1.5
    -- times that radius. The fork angle is then the same at every level.
    local function birth_of(bl, bj)
        local level_radius = first_branch_radius * 2 ^ (bl - 1)
        return level_radius * (1 + 0.4 * hash01(bl, bj)), 1.5 * level_radius
    end

    -- Ease out: the branch leaves at an angle, then curves to run alongside.
    local function drift(bl, bj, r)
        local birth, diverge = birth_of(bl, bj)
        if r < birth then
            return nil
        end
        local u = 1 - clamp01((r - birth) / diverge)
        return 1 - u * u
    end

    -- Course (angle) of the river born as (bl, bj) at radius r and its drift progress s,
    -- nil before it forks off. A drifting branch follows its parent's actual course, which
    -- may still be drifting itself, blended into its own lane. With meander false this is
    -- the course without meanders, used to cheaply rule rivers out.
    local function course(bl, bj, r, amplitude, meander)
        local own = offset + bj * tau / (count * 2 ^ bl)
        if meander then
            own = own + lateral(bl, bj, r, amplitude) / r
        end
        if bl == 0 then
            return own, 1
        end

        local s = drift(bl, bj, r)
        if not s then
            return nil
        elseif s >= 1 then
            return own, 1
        end

        local pl, pj = origin(bl, bj - 1)
        local parent = course(pl, pj, r, amplitude, meander)
        return parent + s * wrap_angle(own - parent), s
    end

    return function(x, y)
        local r_sq = x * x + y * y
        local r = sqrt(r_sq)
        if r < start_radius then
            return false
        end

        local level = 0
        if r >= first_branch_radius then
            level = floor(log(r / first_branch_radius) * inv_log2) + 1
            if level > MAX_LEVEL then
                level = MAX_LEVEL
            end
        end

        local rivers = count * 2 ^ level
        local spacing_angle = tau / rivers
        local theta = atan2(y, x)
        local amplitude = clamp01((r - start_radius) / meander_ramp)
        local bound = (amplitude * meander_bound + reach) / r
        local j0 = floor(((theta - offset) % tau) / spacing_angle)

        -- a river at most a few lanes from its own: a branch drifts from its parent's lane,
        -- which can itself still be drifting from the lane before
        local best, best_s = nil, 1
        for dj = -3, 3 do
            local bl, bj = origin(level, (j0 + dj) % rivers)
            local base = course(bl, bj, r, amplitude, false)
            if base and abs(wrap_angle(theta - base)) <= bound then
                local c, s = course(bl, bj, r, amplitude, true)
                local d = abs(wrap_angle(theta - c)) * r
                if d <= reach then
                    local c1 = course(bl, bj, r + 1, clamp01((r + 1 - start_radius) / meander_ramp), true)
                    local slope = wrap_angle(c1 - c) * r
                    d = d / sqrt(1 + slope * slope)
                    if not best or d < best then
                        best, best_s = d, s
                    end
                end
            end
        end

        if not best then
            return false
        end

        local distance = best + bank_noise_amplitude * perlin_noise(x * bank_noise_scale, y * bank_noise_scale, width_seed)

        -- width grows downstream; the noise is roughly normal with quartiles at -0.2/+0.2, so
        -- fords still turn up far out and wide stretches near spawn, just less often
        local t = clamp01(0.1 + 0.8 * clamp01((r - start_radius) / width_ramp) + 2.5 * perlin_noise(x * width_scale, y * width_scale, width_seed))
        local half_width = (min_width + width_range * t) / 2
        -- springs at spawn, and branches start narrow and grow to full size
        half_width = half_width * clamp01((r - start_radius) / source_length) * (0.5 + 0.5 * best_s)

        if distance > half_width then
            return false
        end

        if distance <= half_width - bank_width then
            return 'deepwater'
        end

        return 'water'
    end
end
