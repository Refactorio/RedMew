-- A richness curve that grows or shrinks with the distance from spawn: a base curve times a
-- multiplier that is `inner` inside `from`, `outer` past `to`, and eases between them
-- (smoothstep), so there is no step in the ore. Pass the result to the main ores factory's
-- :richness(curve, ore_name).
--
-- params = {base = function(x, y), inner = number, outer = number, from = number, to = number}
-- base defaults to the canonical richness curve.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'
local sqrt = math.sqrt

local Public = {}

--- The multiplier at distance d.
function Public.multiplier(params, d)
    local t = (d - params.from) / (params.to - params.from)
    if t <= 0 then
        return params.inner
    elseif t >= 1 then
        return params.outer
    end
    t = t * t * (3 - 2 * t)
    return params.inner + (params.outer - params.inner) * t
end

--- The curve: base(x, y) times the multiplier at that distance.
function Public.curve(params)
    local base = params.base or Factory.default_value
    return function(x, y)
        return base(x, y) * Public.multiplier(params, sqrt(x * x + y * y))
    end
end

return Public
