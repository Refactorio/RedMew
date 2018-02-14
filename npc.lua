global.npcs = {}

local npc_default_items = {
{name = "submachine-gun"},
{name = "uranium-rounds-magazine", count = 200}
}

local Npc = {}

Npc.new = function(surface, position, force, items)
	local force = force or "enemy"
	local items = items or npc_default_items
	local pos = surface.find_non_colliding_position("player", position, 5, 1)
	
	if not pos then return nil end

	local chr = surface.create_entity{name="player", position=pos, force = force}
	chr.shooting_state = {state = 1, position = {0,0}}
	for _,item in pairs(items) do
		chr.insert(item)
	end

	local npc = {character = chr}

	npc.explore = function(self, position)
		if self.character.valid then
			npc.dest = position
			npc.character.shooting_state = {state = 1, position = position}
		end
	end

	npc.attack = function(self, entity, beserk)
		local beserk = beserk or false
		if self.character.valid then
			npc.target = entity
			if entity.valid then
				npc.character.shooting_state = {state = 1, position = entity.position, beserk = beserk}
			end
		end
	end

	npc.stop = function(self)
		if self.character.valid then
			npc.target = nil
			npc.dest = nil
			npc.character.shooting_state = {state = 1, position = self.character.position}
			npc.character.walking_state = {walking = false, direction = 0}
		end
	end

	
	npc.defend = function(self, player, hero)
		self:attack(player, hero) --lol, actually works like that
	end
	return npc
end

function spawn_npc(surface, position, force, items)
	local npc = Npc.new(surface, position, force, items)
	table.insert(global.npcs, npc)
	return npc
end



local function distance(player_1, player_2)
  local d_x = player_1.position.x - player_2.position.x
  local d_y = player_1.position.y - player_2.position.y
  return math.sqrt(d_x*d_x + d_y * d_y)
end

local function on_tick()
	for i, n in pairs(global.npcs) do
		if n.character.valid then
			if n.target then
				if n.target.valid then
					local dis = distance(n.character, n.target)
					if n.beserk then
						n.character.shooting_state = {state = 1, position = n.target.position}
					else
						n.character.shooting_state = {state = 1, position = n.character.position}
					end
					if dis > 5 then
						direction = get_direction(n.character, n.target) --follow.lua
						n.character.walking_state = {walking = true, direction = direction}
					else
						n.character.walking_state = {walking = false, direction = 0}
					end
				else
					n:stop()
				end
			elseif n.dest then
				local dis = distance(n.character, {position = n.dest})
				if dis > 5 then
					direction = get_direction(n.character, {position = n.dest}) --follow.lua
					n.character.walking_state = {walking = true, direction = direction}
					n.character.shooting_state = {state = 1, n.character.position}
				else
					n.character.walking_state = {walking = false, direction = 0}
					n:stop()
				end
			end
		else
			table.remove(global.npcs, i)
		end
	end
end


function test_npcs()
	local f = spawn_npc(game.surfaces[1], {math.random(-30,30),math.random(-30,30)}, "player")
	local s = spawn_npc(game.surfaces[1], {math.random(-30,30),math.random(-30,30)})
	s:attack(f.character)
	f:attack(s.character)
end

Event.register(defines.events.on_tick, on_tick)

