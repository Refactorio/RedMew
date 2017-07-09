local mods = {
	sanctorio = "",
}

local regulars = {
	helpower2 = "",
}


function is_mod(player_name)
	return not (mods[player_name] == nil)
end

function is_regular(player_name)
	return not (regulars[player_name] == nil)
end

function add_regular(player_name)
	if is_regular(player_name) then game.player.print(player_name .. " was already a regular.")
	else
		game.print(game.player.name .. " promoted " .. player_name .. " to regular.")
	end
	regulars[player_name] = ""
end

function add_mod(player_name)
	if is_mod(player_name) then game.player.print(player_name .. " was already a moderator.")
	else
		game.print(game.player.name .. " promoted " .. player_name .. " to moderator.")
	end
	mods[player_name] = ""
end

function remove_regular(player_name)
	if is_regular(player_name) then game.print(player_name .. " was demoted from regular by " .. game.player.name .. ".") end
	regulars[player_name] = nil
end

function remove_mod(player_name)
	if is_mod(player_name) then game.print(player_name .. " was demoted from mod by " .. game.player.name .. ".") end
	mods[player_name] = nil
end

function print_regulars()
	for k,_ in pairs(regulars) do
		game.player.print(k)
	end
end

function print_mods()
	for k,_ in pairs(mods) do
		game.player.print(k)
	end
end
