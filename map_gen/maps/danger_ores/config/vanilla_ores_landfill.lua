-- vanilla_ores skinned entirely in landfill tiles. Used by maps where the whole ore
-- field doubles as buildable ground.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.default():change_tiles('landfill')
