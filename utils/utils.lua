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
  if var then return true else return false
end

return Module
