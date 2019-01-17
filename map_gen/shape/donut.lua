--Donut script by Neko_Baron - tested on RedMew

--change these to mess with ring/shape
local donut_radius = 1600
local donut_width = 128

--dont touch these
local donut_half = donut_width * 0.5
local x_offset = donut_radius - donut_half
local donut_low = x_offset ^ 2
local donut_high = (x_offset + donut_width) ^ 2

return function(x, y)
    local x_off = x - donut_radius
    local distance = x_off ^ 2 + y ^ 2 -- we dont bother to get sqr of it, because we just want the cubed answer to compare to donut_low/high

    return not (distance > donut_high or distance < donut_low)
end
