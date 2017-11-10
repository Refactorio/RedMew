require "locale.gen_shared.perlin_noise"

-- list of {x, y, ore_type, size, richness, rng_seed}
local ctrs = {
	{1, -15, "iron-ore", 0.3, 400, 113},
	{15, 15, "copper-ore", 0.3, 400, 80},
	{4, 21, "coal", 0.25, 640, 31},
	{10, 0, "stone", 0.5, 100, 17},
	{-17, 7, "uranium-ore", 0.6, 100, 203}
}

local function harmonic(x, y)
	local max_idx = 0
	local max = -1
	local richness = 0
	for i, e in ipairs(ctrs) do
		local noise = perlin:noise(x/32, y/32, ctrs[i][6])
		local h_coeff = 1/(1 + .05*math.sqrt((x/32 - ctrs[i][1])*(x/32 - ctrs[i][1]) + (y/32 - ctrs[i][2])*(y/32 - ctrs[i][2])))
		if noise > max and noise > h_coeff*ctrs[i][4] + (1-h_coeff) then
			max = noise
			max_idx = i
			richness = (40*(1-h_coeff) + 0.5*h_coeff) * ctrs[i][5]
		end
	end
	return max, max_idx, richness
end

--generate ores for entire chunk
function run_ores_module(event)
 	local area = event.area
 	local surface = event.surface
	if math.abs(area.left_top.x / 32) < 3 and math.abs(area.left_top.y / 32) < 3 then
		return
	end
 	local entities = surface.find_entities_filtered{type="resource", area=area}
	for _, entity in ipairs(entities) do
 		entity.destroy()
 	end
	local eties = {}
 	for i = 0,31 do
 		for j = 0,31 do
			local pos = {area.left_top.x + i, area.left_top.y + j}
 			local max, max_idx, richness = harmonic(pos[1], pos[2])
 			if -1 ~= max then
				local ety = {name = ctrs[max_idx][3], position = pos, force="neutral", amount=richness}
				if surface.can_place_entity(ety) then
					surface.create_entity(ety)
				end
 			end
 		end
 	end
end
