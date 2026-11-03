-- The ore layouts a Danger Ores map can have live in layouts/, one file each, as the map_config
-- settings that make them. The presets of these maps apply them, and the Randomizer picks one by
-- the map seed, so a layout is only written down once.
--
-- A layout is {name = shown to players, settings = {map_config key = value}}. A value of
-- Layouts.NONE takes the key out of the config, rather than leaving the default.
local Public = {}

local NONE = {}
Public.NONE = NONE

--- Writes `layout`'s settings into `map_config`.
function Public.apply(map_config, layout)
    for key, value in pairs(layout.settings) do
        if value == NONE then
            map_config[key] = nil
        else
            map_config[key] = value
        end
    end
end

return Public
