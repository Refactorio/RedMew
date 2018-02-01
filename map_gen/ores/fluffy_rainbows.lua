--Author: MewMew / (Threaded by Valansch)

require "map_gen.shared.perlin_noise"
local Task = require "utils.Task"

--SETTINGS:
local width_modifier = 0.8
ore_base_amounts = {
   ["iron-ore"] = 700,
   ["coal"] = 400,
   ["copper-ore"] = 400,
   ["stone"] = 400,
   ["uranium-ore"] = 400
}

local function do_resource(name, x, y, noise_terrain, args, noise_band_high, noise_band_low, seed)

  if noise_terrain > -noise_band_high * width_modifier and noise_terrain <= -noise_band_low * width_modifier then
    local noise_resource_amount_modifier = perlin:noise(((x+seed)/200),((y+seed)/200),0)
    local resource_amount = 1 + ((ore_base_amounts[name] + (ore_base_amounts[name] * noise_resource_amount_modifier * 0.2)) * args.amount_distance_multiplicator)
  	if args.surface.can_place_entity {name=name, position={x,y}} then
  		args.surface.create_entity {name=name, position={x,y}, amount=resource_amount}
  	end
  end
end

local function do_row(y, args)
  local y = y + args.area.left_top.y
  local seed = args.seed
  for x= args.area.left_top.x, args.area.left_top.x + 31 do
    local noise_terrain_1 = perlin:noise(((x+seed)/350),((y+seed)/350),0)
    local noise_terrain_2 = perlin:noise(((x+seed)/50),((y+seed)/50),0)
    local noise_terrain = noise_terrain_1 + (noise_terrain_2 * 0.01)

    do_resource("iron-ore", x, y, noise_terrain, args, 0.1, 0.075, seed)
    do_resource("copper-ore", x, y, noise_terrain, args, 0.075, 0.05, seed)
    do_resource("stone", x, y, noise_terrain, args, 0.05, 0.04, seed)
    do_resource("coal", x, y, noise_terrain, args, 0.04, 0.03, seed)
    do_resource("uranium-ore", x, y, noise_terrain, args, 0.03, 0.02, seed)

  end
end

function fluffy_rainbows_task(args)
  do_row(args.y, args)
  args.y = args.y + 1
  return (args.y < 32)
end

function run_combined_module(event)
    if not global.perlin_noise_seed then global.perlin_noise_seed = math.random(1000,1000000) end
		local seed = global.perlin_noise_seed
		local entities = event.surface.find_entities(event.area)
		for _, entity in pairs(entities) do
			if entity.type == "resource" and entity.name ~= "crude-oil" then
				entity.destroy()
			end
		end

    local distance = math.sqrt(event.area.left_top.x * event.area.left_top.x + event.area.left_top.y * event.area.left_top.y)
    local amount_distance_multiplicator = (((distance + 1) / 75) / 75) + 1

    Task.queue_task("fluffy_rainbows_task", {surface = event.surface, y = 0, area = event.area, amount_distance_multiplicator = amount_distance_multiplicator, seed = seed})
end
