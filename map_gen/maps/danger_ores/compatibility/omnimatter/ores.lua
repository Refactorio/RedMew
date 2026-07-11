-- The Omnimatter configs (Omnimatter, Cages, Maze): one omnite sector wearing every
-- terrain skin, so the world keeps its natural look.
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

return Factory.blank()
    :add_ore('omnite', {
        mix = {{'omnite', 100}},
        tiles = {
            'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3',
            'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7',
            'grass-1', 'grass-2', 'grass-3', 'grass-4',
            'sand-1', 'sand-2', 'sand-3'
        }
    })
    :richness{mult = 0.06, pow = 1.55}
