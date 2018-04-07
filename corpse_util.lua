local Event = require "utils.event"

local ttl = 15*60*60
local function on_init()
	global.corpse_util = {}
	global.corpse_util.tags = {}
end

local function mark_corpse(event)
	local player = game.players[event.player_index]
	local name = player.name .. "'s corpse"
	local position = player.position
	local tag = player.force.add_chart_tag(player.surface, {icon={type="item", name="power-armor-mk2"}, position=position, text=name})
	if tag ~= nil then
		table.insert(global.corpse_util.tags, {tag, game.tick + ttl})
	end
end

local function remove_corpse_marks()
	if game.tick % 60 ~= 0 then return end
	local tags = global.corpse_util.tags
	local size = #tags
	for i = size, 1, -1 do
		if game.tick >= tags[i][2] then
			if tags[i][1].valid then
				tags[i][1].destroy()
			end
			table.remove(tags, i)
		end
	end
end

Event.on_init(on_init)
Event.add(defines.events.on_player_died, mark_corpse)
Event.add(defines.events.on_tick, remove_corpse_marks)
