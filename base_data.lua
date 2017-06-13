if not global.score_biter_total_kills then global.score_biter_total_kills = 0 end

local function biter_kill_counter(event)	
	if event.entity.force.name == "enemy" then
		global.score_biter_total_kills = global.score_biter_total_kills + 1
	end		
end

Event.register(defines.events.on_entity_died, biter_kill_counter)