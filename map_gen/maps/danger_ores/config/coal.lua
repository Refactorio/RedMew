-- The all-coal world (Coal Maze, Collapse, Patches): the four standard sectors so the
-- layout matches the vanilla maps', but every sector yields pure coal on dirt, with a
-- flat guaranteed spawn and a gentle richness curve.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.default()
    :add_ore('stone')
    :change_mix{{'coal', 1}}
    :change_tiles{'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7'}
    :start_value{base = 50, mult = 0}
    :richness{mult = 0.035, pow = 1.45}
