-- What Petals, Riches and Bloom share. They fit the ore around spawn to what 1000 satellites on
-- coal power use: research and building (about 11M ore) use mostly iron and come out of the
-- ground within ~200 tiles of spawn; rockets on a half-moduled, coal-powered factory use mostly
-- copper and coal, out to ~410 tiles.
local RadialRichness = require 'map_gen.maps.danger_ores.modules.radial_richness'

local Public = {}

Public.FROM, Public.TO = 200, 350

--- A richness multiplier going from `inner` around spawn to `outer` further out.
function Public.richness(inner, outer)
    return RadialRichness.curve {inner = inner, outer = outer, from = Public.FROM, to = Public.TO}
end

return Public
