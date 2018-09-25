--[[-- info
    Provides the ability to make a simple room with contents
]]

-- dependencies
local Template = require 'map_gen.Diggy.Template'
local Perlin = require 'map_gen.shared.perlin_noise'
local Event = require 'utils.event'
local Debug = require'map_gen.Diggy.Debug'

-- this
local SimpleRoomGenerator = {}

--[[--
    Registers all event handlers.
]]
function SimpleRoomGenerator.register(cfg)
    local config = cfg.features.SimpleRoomGenerator

    local function get_noise(surface, x, y)
        local seed = surface.map_gen_settings.seed + surface.index
        return Perlin.noise(x * config.noise_variance, y * config.noise_variance, seed)
    end

    Event.add(Template.events.on_void_removed, function (event)
        local noise = get_noise(event.surface, event.old_tile.position.x, event.old_tile.position.y)
    end)

    if (config.enable_noise_grid) then
        Event.add(defines.events.on_chunk_generated, function (event)
            for x = event.area.left_top.x, event.area.left_top.x + 31 do
                for y = event.area.left_top.y, event.area.left_top.y + 31 do
                    Debug.print_grid_value(get_noise(event.surface, x, y), event.surface, {x = x, y = y})
                end
            end
        end)
    end
end

--[[--
    Initializes the Feature.

    @param config Table {@see Diggy.Config}.
]]
function SimpleRoomGenerator.initialize(config)

end

return SimpleRoomGenerator
