-- The Gridlocked config: canonical sectors on landfill tiles, with a rich guaranteed
-- floor (both curves offset by 50) and weighted sectors (iron-heavy, stone-light) --
-- expansion is very limited there, so richness is buffed to prevent softlocks.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.default()
    :add_ore('stone')
    :change_tiles('landfill')
    :start_value{base = 50, mult = 0.75}
    :richness{base = 50, mult = 0.003, pow = 2.25}
    :sector_weights{['iron-ore'] = 10, coal = 8, ['copper-ore'] = 7, stone = 2}
