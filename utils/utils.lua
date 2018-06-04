local Module = {}

Module.distance = function(pos1, pos2)
	local dx = pos2.x - pos1.x
	local dy = pos2.y - pos1.y
	return math.sqrt(dx * dx + dy * dy)
end

-- rounds number (num) to certain number of decimal places (idp)
math.round = function(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

Module.print_except = function(msg, player)
	for _,p in pairs(game.players) do
		if p.connected and p ~= player then
			p.print(msg)
		end
	end
end

Module.print_admins = function(msg)
	for _,p in pairs(game.players) do
		if p.connected and p.admin then
			p.print(msg)
		end
	end
end

Module.get_actor = function()
	if game.player then return game.player.name end
	return "<server>"
end

Module.cast_bool = function(var)
  if var then return true else return false end
end

Module.find_entities_by_last_user = function(player, surface, filters)
	if type(player) == "string" or not player then
		error("bad argument #1 to '" .. debug.getinfo(1, "n").name .. "' (number or LuaPlayer expected, got ".. type(player) .. ")", 1)
		return
	end
	if type(surface) ~= "table" and type(surface) ~= "number" then
		error("bad argument #2 to '" .. debug.getinfo(1, "n").name .. "' (number or LuaSurface expected, got ".. type(surface) .. ")", 1)
		return
	end
	local entities = {}
	local surface = surface
	local player = player
	local filters = filters or {}
	if type(surface) == "number" then surface = game.surfaces[surface] end
	if type(player) == "number" then player = game.players[player] end
	filters.force = player.force.name
	for _,e in pairs(surface.find_entities_filtered(filters)) do
		if e.last_user == player then
			table.insert(entities, e)
		end
	end
	return entities
 end
return Module
