-- this
local Mask = {}

  local sigma_modifier = 1
   local blurFilters = {}
   blurFilters[3] = {{0,0,0},{0,1,0},{0,0,0}}
   blurFilters[5] = {
        {0.003765,    0.015019,    0.023792,    0.015019,    0.003765},
        {0.015019,    0.059912,    0.094907,    0.059912,    0.015019},
        {0.023792,    0.094907,    0.150342,    0.094907,    0.023792},
        {0.015019,    0.059912,    0.094907,    0.059912,    0.015019},
        {0.003765,    0.015019,    0.023792,    0.015019,    0.003765}
    }
    blurFilters[7] = {
      {0.000036,	0.000363,	0.001446,	0.002291,	0.001446,	0.000363,	0.000036},
      {0.000363,	0.003676,	0.014662,	0.023226,	0.014662,	0.003676,	0.000363},
      {0.001446,	0.014662,	0.058488,	0.092651,	0.058488,	0.014662,	0.001446},
      {0.002291,	0.023226,	0.092651,	0.146768,	0.092651,	0.023226,	0.002291},
      {0.001446,	0.014662,	0.058488,	0.092651,	0.058488,	0.014662,	0.001446},
      {0.000363,	0.003676,	0.014662,	0.023226,	0.014662,	0.003676,	0.000363},
      {0.000036,	0.000363,	0.001446,	0.002291,	0.001446,	0.000363,	0.000036}
    }
    local n = 7;

--[[--
    Applies a blur filter.

    @param x_start number center point
    @param y_start number center point
    @param factor number relative strength of the entity to withstand the pressure
        factor < 0 if entity is placed
        factor > 0 if entity is removed
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
function Mask.blur(x_start, y_start, factor, callback)
    x_start = math.floor(x_start)
    y_start = math.floor(y_start)
    local filter = blurFilters[n]
    local offset = - math.floor(n / 2) - 1 --move matrix over x_start|y_start and adjust for 1 index
    for x = 1, n do
        for y = 1, n do
            cell = filter[x][y]
            value = factor * cell
            callback(x_start + x + offset, y_start + y + offset, value)
        end
    end
end



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
