-- this
local Mask = {}

   local gaussBlurKernel = {}
   gaussBlurKernel[5] = {
        {0.003765,    0.015019,    0.023792,    0.015019,    0.003765},
        {0.015019,    0.059912,    0.094907,    0.059912,    0.015019},
        {0.023792,    0.094907,    0.150342,    0.094907,    0.023792},
        {0.015019,    0.059912,    0.094907,    0.059912,    0.015019},
        {0.003765,    0.015019,    0.023792,    0.015019,    0.003765}
    }
    gaussBlurKernel[7] = {
      {0.0015, 0.00438, 0.008328, 0.010317, 0.008328, 0.00438, 0.0015},
      {0.00438, 0.012788, 0.024314, 0.03012, 0.024314, 0.012788, 0.00438},
      {0.008328, 0.024314, 0.046228, 0.057266, 0.046228, 0.024314, 0.008328},
      {0.010317, 0.03012, 0.057266, 0.07094, 0.057266, 0.03012, 0.010317},
      {0.008328, 0.024314, 0.046228, 0.057266, 0.046228, 0.024314, 0.008328},
      {0.00438, 0.012788, 0.024314, 0.03012, 0.024314, 0.012788, 0.00438},
      {0.0015, 0.00438, 0.008328, 0.010317, 0.008328, 0.00438, 0.0015}
    }
    gaussBlurKernel[9] = {
      {0.000814, 0.001918, 0.003538, 0.005108, 0.005774, 0.005108, 0.003538, 0.001918, 0.000814},
      {0.001918, 0.00452, 0.008338, 0.012038, 0.013605, 0.012038, 0.008338, 0.00452, 0.001918},
      {0.003538, 0.008338, 0.015378, 0.022203, 0.025094, 0.022203, 0.015378, 0.008338, 0.003538},
      {0.005774, 0.013605, 0.025094, 0.036231, 0.04095, 0.036231, 0.025094, 0.013605, 0.005774},
      {0.005108, 0.012038, 0.022203, 0.032057, 0.036231, 0.032057, 0.022203, 0.012038, 0.005108},
      {0.005108, 0.012038, 0.022203, 0.032057, 0.036231, 0.032057, 0.022203, 0.012038, 0.005108},
      {0.003538, 0.008338, 0.015378, 0.022203, 0.025094, 0.022203, 0.015378, 0.008338, 0.003538},
      {0.001918, 0.00452, 0.008338, 0.012038, 0.013605, 0.012038, 0.008338, 0.00452, 0.001918},
      {0.000814, 0.001918, 0.003538, 0.005108, 0.005774, 0.005108, 0.003538, 0.001918, 0.000814}
    }
    gaussBlurKernel[11] = {
      {0.000395, 0.000853, 0.001552, 0.002381, 0.003078, 0.003353, 0.003078, 0.002381, 0.001552, 0.000853, 0.000395},
      {0.000853, 0.001842, 0.003353, 0.005143, 0.006648, 0.007242, 0.006648, 0.005143, 0.003353, 0.001842, 0.000853},
      {0.001552, 0.003353, 0.006103, 0.009361, 0.012101, 0.013182, 0.012101, 0.009361, 0.006103, 0.003353, 0.001552},
      {0.002381, 0.005143, 0.009361, 0.014359, 0.018561, 0.020219, 0.018561, 0.014359, 0.009361, 0.005143, 0.002381},
      {0.003078, 0.006648, 0.012101, 0.018561, 0.023992, 0.026136, 0.023992, 0.018561, 0.012101, 0.006648, 0.003078},
      {0.003353, 0.007242, 0.013182, 0.020219, 0.026136, 0.02847, 0.026136, 0.020219, 0.013182, 0.007242, 0.003353},
      {0.003078, 0.006648, 0.012101, 0.018561, 0.023992, 0.026136, 0.023992, 0.018561, 0.012101, 0.006648, 0.003078},
      {0.002381, 0.005143, 0.009361, 0.014359, 0.018561, 0.020219, 0.018561, 0.014359, 0.009361, 0.005143, 0.002381},
      {0.001552, 0.003353, 0.006103, 0.009361, 0.012101, 0.013182, 0.012101, 0.009361, 0.006103, 0.003353, 0.001552},
      {0.000853, 0.001842, 0.003353, 0.005143, 0.006648, 0.007242, 0.006648, 0.005143, 0.003353, 0.001842, 0.000853},
      {0.000395, 0.000853, 0.001552, 0.002381, 0.003078, 0.003353, 0.003078, 0.002381, 0.001552, 0.000853, 0.000395}
  }
    local n = 11;
    local radius =  math.floor(n / 2)
    local middle = radius + 1
    local circle_blur_sum = 0

    local circleBlurKernel = {}


    function init()
        local sum = 0
        local edge_middle_distance = math.sqrt(2)  * (n - middle)
        for x = 1, n do
          circleBlurKernel[x] = {}
            for y = 1, n do
              local distance = math.sqrt((x - middle) * (x - middle) + (y - middle) * (y - middle))
              if distance <= radius then
                sum = sum + 1
                circleBlurKernel[x][y] = 1
              else
                  local edge_distance = edge_middle_distance - distance
                  local normalized_value = edge_distance / (edge_middle_distance - radius)
                  sum = sum + normalized_value
                  circleBlurKernel[x][y] = normalized_value
              end
            end
        end

        for x = 1, n do
            for y = 1, n do
                circleBlurKernel[x][y] = circleBlurKernel[x][y] / sum
            end
        end

        sum = 0
        for x = 1,n do
            for y = 1, n do
              local distance = math.sqrt((x - middle) * (x - middle) + (y - middle) * (y - middle))
              if distance <= radius then
                sum = sum + (radius - distance) / radius + 0.1
              end
            end
        end
        circle_blur_sum = sum

    end


    init()


--[[--
    Applies a blur filter.

    @param x_start number center point
    @param y_start number center point
    @param factor number relative strength of the entity to withstand the stress
        factor < 0 if entity is placed
        factor > 0 if entity is removed
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
function Mask.blur(x_start, y_start, factor, callback)
    x_start = math.floor(x_start)
    y_start = math.floor(y_start)
    local filter = gaussBlurKernel[n]
    local offset = - math.floor(n / 2) - 1 --move matrix over x_start|y_start and adjust for 1 index
    for x = 1, n do
        for y = 1, n do
            cell = filter[x][y]
            value = factor * cell
            if math.abs(value) > 0.001 then
                callback(x_start + x + offset, y_start + y + offset, value)
            end
        end
    end
end

--[[--
    Applies a circular blur
    All values outside the circle are proportional to the distance to the center.
    The circle radius is math.floor(n / 2)
    The sum of all values is 1

    @param x_start number center point
    @param y_start number center point
    @param factor the factor to multiply the cell value with (value = cell_value * factor)
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
function Mask.circle_blur(x_start, y_start, factor, callback)
    x_start = math.floor(x_start)
    y_start = math.floor(y_start)
    local offset = - math.floor(n / 2) - 1 --move matrix over x_start|y_start and adjust for 1 index
    for x = 1,n do
        for y = 1, n do
            local distance = math.sqrt((x - middle) * (x - middle) + (y - middle) * (y - middle))
            if distance <= radius then
              local value = (radius - distance) / radius / circle_blur_sum * factor
              callback(x_start + x + offset, y_start + y + offset, value)
            end
        end
    end
end



--[[--
    Applies a circular box blur
    All values withing the radius of the filters are equal. All values outside the circle are proportional to the distance to the circle.
    The circle radius is math.floor(n / 2)
    The sum of all values is 1

    @param x_start number center point
    @param y_start number center point
    @param factor the factor to multiply the cell value with (value = cell_value * factor)
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
function Mask.box_blur(x_start, y_start, factor, callback)
    x_start = math.floor(x_start)
    y_start = math.floor(y_start)
    local filter = circleBlurKernel
    local offset = - math.floor(n / 2) - 1 --move matrix over x_start|y_start and adjust for 1 index
    for x = 1, n do
        for y = 1, n do
            cell = filter[x][y]
            value = factor * cell
            if math.abs(value) > 0.001 then
                callback(x_start + x + offset, y_start + y + offset, value)
            end
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
