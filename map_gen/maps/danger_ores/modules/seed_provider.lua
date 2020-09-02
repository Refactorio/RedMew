local RS = require 'map_gen.shared.redmew_surface'

local seed = nil
local count = 0

return function()
    if seed == nil then
        seed = RS.get_surface().map_gen_settings.seed
    end

    count = count + 1
    return seed * count
end
