-- Poor Man's Coal Fields: canonical mixes, but the
-- minor ores only show near spawn -- above the richness threshold a patch yields the
-- sector's dominant ore instead of the mixed-in one.
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local value = b.exponential_value(0, 0.06, 1.55)

local function degrading_resource(primary_ore)
    return function(secondary_ore)
        return function(_, _, world)
            local v = value(world.x, world.y)
            local ore
            if v > 1500 then
                ore = primary_ore
            else
                ore = secondary_ore
            end

            return {
                name = ore,
                amount = v
            }
        end
    end
end

return Factory.main_ores {
    ores = {
        {name = 'copper-ore', make_resource = degrading_resource('copper-ore')},
        {name = 'coal', make_resource = degrading_resource('coal')},
        {name = 'iron-ore', make_resource = degrading_resource('iron-ore')},
        {name = 'stone', make_resource = degrading_resource('stone')}
    },
    start = b.euclidean_value(0, 0.35)
}
