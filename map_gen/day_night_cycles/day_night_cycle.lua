local Event = require 'utils.event'
local day_night_cycle = require ('map_gen.day_night_cycles.' .. global.config.map.day_night_cycle)
--local day_night_cycle = require ('map_gen.day_night_cycles.bright')

local function init()
    local surface = game.surfaces[1]
    for k, v in pairs(day_night_cycle) do
        surface[k] = v
    end
end

Event.on_init(init)
