require("config")
require("prototypes.prototype_utils")

for _, resource in pairs(data.raw.resource) do
	resetRichness(resource)
end

if not settings.startup["rso-vanilla-biter-generation"].value then
		
	for _, spawner in pairs(data.raw["unit-spawner"]) do
		removePeaks(spawner)
	end

	for _, turret in pairs(data.raw.turret) do
		if turret.subgroup == "enemies" then
			removePeaks(turret)
		end
	end
end

if debug_items_enabled then
	data.raw["car"]["car"].max_health = 0x8000000
	data.raw["ammo"]["basic-bullet-magazine"].magazine_size = 1000
	data.raw["ammo"]["basic-bullet-magazine"].ammo_type.action[1].action_delivery[1].target_effects[2].damage.amount = 5000
end