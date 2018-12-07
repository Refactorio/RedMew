-- For more info on the day/night cycle see: https://github.com/Refactorio/RedMew/wiki/Day-Night-cycle
local Event = require 'utils.event'
local day_night_cycle = require ('map_gen.day_night_cycles.' .. global.map.day_night_cycle)

local function init()
    local surface = game.surfaces[1]
    for k, v in pairs(day_night_cycle) do
        surface[k] = v
    end
end

Event.on_init(init)
