--Donut script by Neko_Baron - tested on RedMew
if shape_module then return end
shape_module = true

--change these to mess with ring/shape
local donut_radius = 1600
local donut_width = 128

--dont touch these
local donut_half = donut_width * 0.5
local x_offset = donut_radius - donut_half
local donut_low = x_offset^2
local donut_high = (x_offset+donut_width)^2


function run_shape_module(event)
	local area = event.area 
	local surface = event.surface
	local tiles = {}
	
	local top_left = area.left_top	--make a more direct reference
	

	for x = top_left.x-1, top_left.x + 32 do
		for y = top_left.y-1, top_left.y + 32 do       

			local x_off = x - donut_radius
			local distance = x_off^2 + y^2  -- we dont bother to get sqr of it, because we just want the cubed answer to compare to donut_low/high
			if distance > donut_high or distance < donut_low then
				table.insert(tiles, {name = "out-of-map", position = {x,y}}) 
			end
		end
	end
	surface.set_tiles(tiles)
	
	return true
end