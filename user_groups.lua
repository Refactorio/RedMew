global.mods = {}
global.regualrs = {}
local Event = require "utils.event"

local Module = {}

local function update_group(position)
	local file = position .. ".lua"
	game.write_file(file, "{", false, 0)
	local group = global[position]
	local line = ""
	for player_name,_ in pairs(group) do
		line = string.format('["%s"] = "",\n', player_name)
		game.write_file(file, line, true, 0)
	end
	game.write_file(file, "}", true, 0)
end

Module.get_actor = function()
	if game.player then return game.player.name end
	return "<server>"
end

local function cast_bool(value)
	if value then
		return true
	else
		return false
	end
end

Module.is_mod = function(player_name)
	if global.mods[player_name] then
		return cast_bool(global.mods[player_name:lower()]) --to make it backwards compatible
	end
	return true
end

local is_regular = function(player_name)
	if not global.regulars[player_name] then
		return cast_bool(global.regulars[player_name:lower()]) --to make it backwards compatible
	end
	return true
end

Module.add_regular = function(player_name)
		local actor = get_actor()
    if is_regular(player_name) then player_print(player_name .. " is already a regular.")
    else
        if game.players[player_name] then
            game.print(actor .. " promoted " .. player_name .. " to regular.")
            global.regulars[player_name] = true
            update_group("regulars")
        else
            player_print(player_name .. " does not exist.")
        end
    end
end

Module.add_mod = function(player_name)
		local actor = get_actor()
    if is_mod(player_name) then player_print(player_name .. " is already a moderator.")
    else
        if game.players[player_name] then
            game.print(actor .. " promoted " .. player_name .. " to moderator.")
            global.mods[player_name] = true
            update_group("mods")
        else
            player_print(player_name .. " does not exist.")
        end
    end
end

Module.remove_regular = function(player_name)
	local actor = get_actor()
	if is_regular(player_name) then game.print(player_name .. " was demoted from regular by " .. actor .. ".") end
	global.regulars[player_name] = nil
	update_group("regulars")
end

Module.remove_mod = function(player_name)
	local actor = get_actor()
	if is_mod(player_name) then game.print(player_name .. " was demoted from mod by " .. actor .. ".") end
	global.mods[player_name] = nil
	update_group("mods")
end

Module.print_regulars = function()
	for k,_ in pairs(global.regulars) do
		player_print(k)
	end
end

Module.print_mods = function()
	for k,_ in pairs(global.mods) do
		player_print(k)
	end
end


Event.add(defines.events.on_player_joined_game, function(event)
  local correctCaseName = game.players[event.player_index].name
	if global.mods[correctCaseName:lower()] and not global.mods[correctCaseName] then
		global.mods[correctCaseName:lower()] = nil
		global.mods[correctCaseName] = true
		update_group("mods")
	end
	if global.regulars[correctCaseName:lower()] and not global.regulars[correctCaseName] then
		global.regulars[correctCaseName:lower()] = nil
		global.regulars[correctCaseName] = true
		update_group("regulars")
	end
end)

Event.add(-1, function()
	if not global.regulars then global.regulars = {} end
	if not global.mods then global.mods = {} end
end)

return Module
