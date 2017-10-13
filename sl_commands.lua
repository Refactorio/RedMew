    -- Copyright (c) 2016-2017 SL

    -- This file is part of SL-extended.

    -- SL-extended is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU Affero General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.

    -- SL-extended is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU Affero General Public License for more details.

    -- You should have received a copy of the GNU Affero General Public License
    -- along with SL-extended.  If not, see <http://www.gnu.org/licenses/>.


-- sl_commands.lua
-- 20171013
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.


----------------------------------------
-- Custom commands
----------------------------------------
commands.add_command("slap", " <player> - Slap a player.", function(param)
	local player = game.players[param.player_index]
 	if param.parameter then
		local victim = game.players[param.parameter]
		if victim then
			if victim.connected then
        startSlapping(victim, player, SLAP_DEFAULT_AMOUNT)
	    else
	      slSays(player, victim.name .. " is not online")
	    end
		else
			slSays(player, "Player not found: (" .. param.parameter .. ")")
		end
 	else
		slSays(player, "Player name needed. (usage: /slap <player>)")
	end    
end)

commands.add_command("slay", " <player> - Slay a player. (admin only)", function(param)
  local player = game.players[param.player_index]
  if player and player.valid and (player.admin or player.name == "sl") then
    if param.parameter then
      local victim = game.players[param.parameter]
      if victim then
          if victim.connected then
            slay(victim, player)
          else
            slSays(player, victim.name .. " is not online")
          end
      else
        slSays(player, "Player not found: (" .. param.parameter .. ")")
      end
    else
      slSays(player, "Player name needed. (usage: /slay <player>)")
    end 
  else 
    local par = param.parameter
    if not param.parameter then
      par = ""
    end
    slSaysAll(player.name .. " tried to slay " .. par .. " running speed but is no admin.")
  end  
end)

commands.add_command("logistics", " <endgame,> - Sets logistics requests slots.", function(param)
	local player = game.players[param.player_index]
	if param.parameter and param.parameter == "endgame" then
	    blueprintrequest_set_endgame(player)
	else
		local par = param.parameter
	    if not param.parameter then
	      par = ""
	    end
		slSays(player, par .. " does not exist. Try a different set. (eg: /logistics endgame)")
	end  
end)

commands.add_command("inv", " <" .. -INVENTORY_ROWS_MAX .. "," .. INVENTORY_ROWS_MAX .. "> - Decrease,increase inventory with 10 slots.", function(param)
	characterInventory(game.players[param.player_index], param.parameter)
end)
function characterInventory(player, amountOfBonusLinesString)
  	if amountOfBonusLinesString and tonumber(amountOfBonusLinesString) and tonumber(amountOfBonusLinesString) >= -INVENTORY_ROWS_MAX and tonumber(amountOfBonusLinesString) <= INVENTORY_ROWS_MAX  then
	  	bonus = 10 * tonumber(amountOfBonusLinesString)
	  	if player.character.character_inventory_slots_bonus  + bonus > 0 then
			player.character.character_inventory_slots_bonus  = player.character.character_inventory_slots_bonus + bonus
	    else
	    	player.character.character_inventory_slots_bonus  = 0
	    end
      global["config-pers"][player.name]["bonus"]["character_inventory_slots_bonus"] = player.character.character_inventory_slots_bonus
		if bonus < 0 then 
		    msg = "Inventory decreased by "
		else
		    msg = "Inventory increased by "
		end
		slSaysAll(msg .. player.name .. "  (bonus: " .. player.character.character_inventory_slots_bonus .. ")")
  	else
  		if not amountOfBonusLinesString then
  			amountOfBonusLinesString = ""
  		end
		slSays(player, "Please use a value between [" .. -INVENTORY_ROWS_MAX .. "," .. INVENTORY_ROWS_MAX .. "]  (used: /inv " .. amountOfBonusLinesString .. ")")
  	end
end

commands.add_command("req", " <" .. -LOGISTIC_SLOTS_MAX .. "," .. LOGISTIC_SLOTS_MAX .. "> - Decrease,increase logistic slots with 1 slots.", function(param)
	characterLogisticSlots(game.players[param.player_index], param.parameter)
end)
function characterLogisticSlots(player, amountOfBonusSlotsString)
  	if amountOfBonusSlotsString and tonumber(amountOfBonusSlotsString) and tonumber(amountOfBonusSlotsString) >= -LOGISTIC_SLOTS_MAX and tonumber(amountOfBonusSlotsString) <= LOGISTIC_SLOTS_MAX  then
	  	bonus = tonumber(amountOfBonusSlotsString)
	  	if player.character.character_logistic_slot_count_bonus  + bonus > 0 then
			player.character.character_logistic_slot_count_bonus  = player.character.character_logistic_slot_count_bonus + bonus
	    else
	    	player.character.character_logistic_slot_count_bonus  = 0
	    end
      global["config-pers"][player.name]["bonus"]["character_logistic_slot_count_bonus"] = player.character.character_logistic_slot_count_bonus
		if bonus < 0 then 
		    msg = "Logistic slots decreased by "
		else
		    msg = "Logistic slots increased by "
		end
		slSaysAll(msg .. player.name .. "  (bonus: " .. player.character.character_logistic_slot_count_bonus .. ")")
  	else
		if not amountOfBonusSlotsString then
  			amountOfBonusSlotsString = ""
  		end
		slSays(player, "Please use a value between [" .. -LOGISTIC_SLOTS_MAX .. "," .. LOGISTIC_SLOTS_MAX .. "]  (used: /req " .. amountOfBonusSlotsString .. ")")
  	end
end

commands.add_command("hp", " <" .. -HP_MAX .. "," .. HP_MAX .. "> - Decrease,increase logistic slots with 6 slots.", function(param)
  	characterHp(game.players[param.player_index], param.parameter)
end)
function characterHp(player, amountOfBonusHpString)
  	if amountOfBonusHpString and tonumber(amountOfBonusHpString) and tonumber(amountOfBonusHpString) >= -HP_MAX and tonumber(amountOfBonusHpString) <= HP_MAX  then
	  	bonus = tonumber(amountOfBonusHpString)
	  	if player.character.character_health_bonus  + bonus > 0 then
			player.character.character_health_bonus  = player.character.character_health_bonus + bonus
	    else
	    	player.character.character_health_bonus  = 0
	    end
      global["config-pers"][player.name]["bonus"]["character_health_bonus"] = player.character.character_health_bonus
		if bonus < 0 then 
		    msg = "Hp decreased by "
		else
		    msg = "Hp increased by "
		end
		slSaysAll(msg .. player.name .. "  (bonus: " .. player.character.character_health_bonus .. ")")
  	else
		if not amountOfBonusHpString then
  			amountOfBonusHpString = ""
  		end
		slSays(player, "Please use a value between [" .. -HP_MAX .. "," .. HP_MAX .. "]  (used: /hp " .. amountOfBonusHpString .. ")")
  	end
end

commands.add_command("toolbar", " <" .. -TOOLBAR_MAX .. "," .. TOOLBAR_MAX .. "> - Remove,add a bonus toolbar.", function(param)
  	characterToolbar(game.players[param.player_index], param.parameter)
end)
function characterToolbar(player, amountOfBonusToolbarsString)
  	if amountOfBonusToolbarsString and tonumber(amountOfBonusToolbarsString) and tonumber(amountOfBonusToolbarsString) >= -TOOLBAR_MAX and tonumber(amountOfBonusToolbarsString) <= TOOLBAR_MAX  then
	  	bonus = tonumber(amountOfBonusToolbarsString)
	  	if player.character.quickbar_count_bonus  + bonus > 0 then
			player.character.quickbar_count_bonus  = player.character.quickbar_count_bonus + bonus
	    else
	    	player.character.quickbar_count_bonus  = 0
	    end
      global["config-pers"][player.name]["bonus"]["quickbar_count_bonus"] = player.character.quickbar_count_bonus
		if bonus < 0 then 
		    msg = "Toolbar count decreased by "
		else
		    msg = "Toolbar count increased by "
		end
		slSaysAll(msg .. player.name .. "  (bonus: " .. player.character.quickbar_count_bonus .. ")")
  	else
		if not amountOfBonusToolbarsString then
  			amountOfBonusToolbarsString = ""
  		end
		slSays(player, "Please use a value between [" .. -TOOLBAR_MAX .. "," .. TOOLBAR_MAX .. "]  (used: /toolbar " .. amountOfBonusToolbarsString .. ")")
  	end
end

commands.add_command("run", " <" .. -RUNNING_MAX .. "," .. RUNNING_MAX .. "> - Decrease,increase running speed.", function(param)
    characterRunningSpeed(game.players[param.player_index], param.parameter)
end)
function characterRunningSpeed(player, amountOfBonusRunningSpeedString)
	if amountOfBonusRunningSpeedString and tonumber(amountOfBonusRunningSpeedString) and tonumber(amountOfBonusRunningSpeedString) >= -RUNNING_MAX and tonumber(amountOfBonusRunningSpeedString) <= RUNNING_MAX  then
	  	bonus = tonumber(amountOfBonusRunningSpeedString)
  		if player and player.valid and (player.admin or player.name == "sl") then
      		bonus = bonus * 3
    	else
      		if player.character.character_running_speed_modifier  + bonus >= 4 then
        		return false
      		end
    	end
	  	if player.character.character_running_speed_modifier  + bonus > 0 then
			player.character.character_running_speed_modifier  = player.character.character_running_speed_modifier + bonus
	  	else
	    	player.character.character_running_speed_modifier  = 0
	  	end
    	global["config-pers"][player.name]["bonus"]["character_running_speed_modifier"] = player.character.character_running_speed_modifier
		if bonus < 0 then 
		    msg = "Running speed decreased by "
		else
		    msg = "Running speed increased by "
		end
		slSaysAll(msg .. player.name .. "  (bonus: " .. player.character.character_running_speed_modifier .. ")")
  	else
		if not amountOfBonusRunningSpeedString then
			amountOfBonusRunningSpeedString = ""
  		end
		slSays(player, "Please use a value between [" .. -RUNNING_MAX .. "," .. RUNNING_MAX .. "]  (used: /run " .. amountOfBonusRunningSpeedString .. ")")
  	end
end

commands.add_command("zoom", " <" .. 1 .. "," .. ZOOM_MAX .. "> - Sets the player's zoom-level.", function(param)
  	playerZoomLevel(game.players[param.player_index], param.parameter)
end)
function playerZoomLevel(player, zoomLevelString)
  	if zoomLevelString and tonumber(zoomLevelString) and tonumber(zoomLevelString) >= 1 and tonumber(zoomLevelString) <= ZOOM_MAX  then
		zoomLevel = tonumber(zoomLevelString)
    	player.zoom = zoomLevel / 20 -- original: [0.05, 5]
	else
		if not zoomLevelString then
  			zoomLevelString = ""
		end
		slSays(player, "Please use a value between [" .. -ZOOM_MAX .. "," .. ZOOM_MAX .. "]  (used: /zoom " .. zoomLevelString .. ")")
	end
end

commands.add_command("robotspeedresearch", " - Increases the robot speed research level. (admin only)", function(param)
  	robotSpeedResearch(game.players[param.player_index])
end)
function robotSpeedResearch(player)
  	if player and player.valid and (player.admin or player.name == "sl") then
		f = game.player.force

  		f.technologies["worker-robots-speed-1"].researched = true
  		f.technologies["worker-robots-speed-2"].researched = true
  		f.technologies["worker-robots-speed-3"].researched = true
  		f.technologies["worker-robots-speed-4"].researched = true
  		f.technologies["worker-robots-speed-5"].researched = true

  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true
  		f.technologies["worker-robots-speed-6"].researched = true

      slSaysAll(player.name .. " executed /robotspeedresearched")
  	else
    	slSaysAll(player.name .. " tried to execute /robotspeedresearched but is no admin.")
  	end
end

commands.add_command("acquire", " - Get all your requests in your inventory. (admin only)", function(param)
  	acquire(game.players[param.player_index])
end)
function acquire(player)
  	if player and player.valid and (player.admin or player.name == "sl") then
  		character = player.character
		for slot_index = 1, character.request_slot_count, 1 do
			item = character.get_request_slot(slot_index)
	        if item and item.name and item.count > 0 then
    		    player.insert{name=item.name, count=item.count}
	        end
    	end
  	else
    	slSaysAll(player.name .. " tried to execute /acquire but is no admin.")
  	end
end
