-- this
local Mask = {}

--[[--
    Masks in the shape of a circle.

    @param x_start number, center point
    @param y_start number, center point
    @param diameter number size of the circle
    @param callback function to execute on each tile within the circle callback(x, y, tile_distance_to_center, diameter)
]]
function Mask.circle(x_start, y_start, diameter, callback)
    for x = (diameter * -1), diameter, 1 do
        for y = (diameter * -1), diameter, 1 do
            local tile_distance_to_center = math.floor(math.sqrt(x^2 + y^2))

            if (tile_distance_to_center < diameter) then
                callback(x + x_start, y + y_start, tile_distance_to_center, diameter)
            end
        end
    end
end

return Mask
