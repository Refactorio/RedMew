-- The 3-way sector ores are exactly the first three entries (copper, coal, iron) of the
-- X-Cross config, which also carries the stone sector -- one source of truth for the numbers.
local x_cross_ores = require 'map_gen.maps.danger_ores.config.x_cross_ores'

return { x_cross_ores[1], x_cross_ores[2], x_cross_ores[3] }
