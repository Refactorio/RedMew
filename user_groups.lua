function update_group(position)
	local file = position .. ".lua"
	game.write_file(file, "{", false, 0)
	local group = global[position]
	local line = ""
	for player_name,_ in pairs(group) do
		line = string.format('["%s"] = "",\n', player_name)
		game.write_file(file, line, true)
	end
	game.write_file(file, "}", true)
end

function get_actor()
	if game.player then return game.player.name end
	return "<server>"
end

function is_mod(player_name)
	return global.mods[player_name:lower()]
end

function is_regular(player_name)
	return global.regulars[player_name:lower()]
end

function add_regular(player_name)
		local actor = get_actor()
    if is_regular(player_name) then player_print(player_name .. " is already a regular.")
    else
        if game.players[player_name] then
            game.print(actor .. " promoted " .. player_name .. " to regular.")
            global.regulars[player_name:lower()] = ""
            update_group("regulars")
        else
            player_print(player_name .. " does not exist.")
        end
    end
end

function add_mod(player_name)
		local actor = get_actor()
    if is_mod(player_name) then player_print(player_name .. " is already a moderator.")
    else
        if game.players[player_name] then
            game.print(actor .. " promoted " .. player_name .. " to moderator.")
            global.mods[player_name:lower()] = ""
            update_group("mods")
        else
            player_print(player_name .. " does not exist.")
        end
    end
end

function remove_regular(player_name)
	local actor = get_actor()
	if is_regular(player_name) then game.print(player_name .. " was demoted from regular by " .. actor .. ".") end
	global.regulars[player_name] = nil
	update_group("regulars")
end

function remove_mod(player_name)
	local actor = get_actor()
	if is_mod(player_name) then game.print(player_name .. " was demoted from mod by " .. actor .. ".") end
	global.mods[player_name] = nil
	update_group("mods")
end

function print_regulars()
	for k,_ in pairs(global.regulars) do
		player_print(k)
	end
end

function print_mods()
	for k,_ in pairs(global.mods) do
		player_print(k)
	end
end
