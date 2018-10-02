
local Debug = require'map_gen.Diggy.Debug'

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
    local n = 9;
    local radius =  math.floor(n / 2)
    local radius_sq = (radius + 0.2) * (radius + 0.2)
    local center_radius_sq = radius_sq / 9
    local disc_radius_sq = radius_sq * 4 / 9

    local middle = radius + 1
    local disc_blur_sum = 0
    local points_in_circle = 0

    local center_value
    local disc_value
    local ring_value


    function init()
        for x = -radius, radius do
            for y = -radius, radius do
                local distance_sq = x * x + y * y
                if distance_sq <= center_radius_sq then
                    disc_blur_sum = disc_blur_sum + 1
                elseif distance_sq <= disc_radius_sq then
                    disc_blur_sum = disc_blur_sum + 2 /3
                elseif distance_sq <= radius_sq then
                    disc_blur_sum = disc_blur_sum + 1/3
                end
            end
        end
        center_value = 1 / disc_blur_sum
        ring_value = center_value / 3
        disc_value = ring_value * 2
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
    Applies a blur
    Applies the disc in 3 discs: center, (middle) disc and (outer) ring.
    The relative weights for tiles in a disc are:
    center: 3/3
    disc: 2/3
    ring: 1/3
    The sum of all values is 1

    @param x_start number center point
    @param y_start number center point
    @param factor the factor to multiply the cell value with (value = cell_value * factor)
    @param callback function to execute on each tile within the mask callback(x, y, value)
]]
    function Mask.disc_blur(x_start, y_start, factor, callback)
        x_start = math.floor(x_start)
        y_start = math.floor(y_start)
          for x = -radius, radius do
              for y = -radius, radius do
                  local value = 0
                  local distance_sq = x * x + y * y
                  if distance_sq <= center_radius_sq then

                    value = center_value
                  elseif distance_sq <= disc_radius_sq then
                    value = disc_value
                  elseif distance_sq <= radius_sq then
                    value = ring_value
                  end
                  if math.abs(value) > 0.001 then
                      callback(x_start + x, y_start + y, value * factor)
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
            local tile_distance_to_center = math.floor(math.sqrt(x^2 + y^2)) --needed in callback

            if (tile_distance_to_center < diameter) then
                callback(x + x_start, y + y_start, tile_distance_to_center, diameter)
            end
        end
    end
end

return Mask
