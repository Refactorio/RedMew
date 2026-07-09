-- Vanilla ores plus stone as a fourth main sector. Used by maps whose layouts need
-- four main ores, e.g. the clean-border partition maps (Tetrominoes, Voronoi), whose
-- region colouring requires at least 4 colours.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.default():add_ore('stone')
