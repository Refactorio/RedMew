require "util"
require "locale/utils/event"
require "config"
require "locale/utils/utils"
require "locale/utils/list_utils"
require "base_data"
require "user_groups"
require "info"
require "player_list"
require "poll"
require "band"
require "fish_market"
require "train_station_names"
require "score"
require "map_layout"
require "nuke_control"
require "walk_distance"
require "on_tick"
require "follow"
require "wells"
require "custom_commands"
require "tasklist"
require "autodeconstruct"
require "corpse_util"
require "reactor_meltdown"




require("sl_utils")
require("sl_config")

-- Include Mods
require("sl_autodeconstruct")
require("sl_autohideminimap")
require("sl_commands")
require("sl_upgradeplanner")
require("sl_itemcount")
require("sl_traincolor")

require("silo-script")
local version = 1


silo_script.add_remote_interface()


script.on_init(function()
  	global.version = version
  	silo_script.init()
end)

script.on_configuration_changed(function(event)
  	if global.version ~= version then
    	global.version = version
  	end
  	silo_script.on_configuration_changed(event)
end)

----------------------------------------
-- Events
----------------------------------------
script.on_event(defines.events.on_rocket_launched, function(event)
  	global["lastTick"] = global["lastTick"] or 0
  	slSaysAll("[" .. math.floor((event.tick-global["lastTick"])/60) .. " s]  A rocket silo launched satellite " .. game.forces["player"].get_item_launched("satellite"))
  	global["lastTick"]  = event.tick
  	silo_script.on_rocket_launched(event)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
 
  	if ENABLE_UNDECORATOR then
    	undecorateOnChunkGenerate(event)
  	end

end)

script.on_event(defines.events.on_gui_click, function(event)
  
    sl_on_gui_click(event)

    if ENABLE_UPGRADE_PLANNER then
      upgradeplanner_on_gui_click(event)
    end

    silo_script.on_gui_click(event)

end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
  
    sl_on_gui_selection_state_changed(event)

end)

script.on_event(defines.events.on_entity_renamed, function(event)
  
    sl_on_on_entity_renamed(event)

end)

script.on_event(defines.events.on_player_created, function(event)
  
  	playerSpawnItems(event)

  	silo_script.gui_init(game.players[event.player_index])

end)

script.on_event(defines.events.on_player_respawned, function(event)
  
    sl_init(event)

  	playerRespawnItems(event)

  	if ENABLE_LONGREACH then
    	givePlayerLongReach(game.players[event.player_index])
  	end

  	if ENABLE_CHARACTERPLUSPLUS then
    	givePlayerCharacterPlusPlus(game.players[event.player_index])
  	end

end)

script.on_event(defines.events.on_player_joined_game, function(event)
  
  	if HACK_GAME_IS_MULTIPLAYER_FREEPLAY_NOT_SCENARIO then
  		if event.player_index == 1 then
  			playerSpawnItems(event)
  		end
  		game.forces["player"].chart("nauvis", {{x = -500, y = -500}, {x = 500, y = 500}})
  	end

  	playerJoinedMessages(event)

  	sl_init(event)
  
  	if ENABLE_AUTODECONSTRUCT then
    	autodeconstruct_init()
  	end

  	if ENABLE_AUTO_HIDE_MINI_MAP then
    	autohideminimap_init()
  	end

  	if ENABLE_CHARACTERPLUSPLUS then
    	givePlayerCharacterPlusPlus(game.players[event.player_index])
  	end

  	if ENABLE_LONGREACH then
    	givePlayerLongReach(game.players[event.player_index])
  	end

  	if ENABLE_UPGRADE_PLANNER then
    	upgradeplanner_player_joined(event)
  	end

end)

script.on_event(defines.events.on_built_entity, function(event)

  	if ENABLE_AUTOFILL then
    	autofill(event)
  	end

  	if ENABLE_AUTODECONSTRUCT then
    	autodeconstruct_on_built_entity(event)
  	end

end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  
  	if ENABLE_AUTODECONSTRUCT then
    	autodeconstruct_on_built_entity(event)
  	end

end)

script.on_event(defines.events.on_marked_for_deconstruction, function(event)

  	if ENABLE_UPGRADE_PLANNER then
    	upgradeplanner_on_marked_for_deconstruction(event)
  	end

end)

script.on_event(defines.events.on_player_built_tile, function(event)

  	if ENABLE_UPGRADE_PLANNER then
    	upgradeplanner_on_player_built_tile(event)
  	end

end)

----------------------------------------
-- 'Hack' to cheat the game in keeping blueprint knowledge after manually placing an item
----------------------------------------
script.on_event(defines.events.on_put_item, function(event)
  
    local player = game.players[event.player_index]
    if not player.cursor_stack or not player.cursor_stack.valid or not player.cursor_stack.valid_for_read then
    	return
    end
  	local entity = player.cursor_stack.prototype.place_result
  	if entity then
  	  local placed = player.surface.find_entities_filtered{position = event.position}[1]
  	  if placed and placed.name == "entity-ghost" and placed.ghost_name == entity.name then
  	    player.remove_item({name = player.cursor_stack.name})
  	    placed.revive()
  	  end
  	end
    
end)


script.on_event(defines.events.on_canceled_deconstruction, function(event)

 	  if ENABLE_AUTODECONSTRUCT then
      autodeconstruct_on_canceled_deconstruction(event)
    end

end)


script.on_event(defines.events.on_resource_depleted, function(event)

  	if ENABLE_AUTODECONSTRUCT then
    	autodeconstruct_on_resource_depleted(event)
  	end

end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    
    local player = game.players[event.player_index]
    if isHolding("deconstruction-planner", player) or isHolding("hazard-concrete", player) or isHolding("concrete", player) or isHolding("stone-brick", player) then
      guiToggleUp(player)
    else
      if player.gui.top["sl-extended-frame"]["upgrade-planner-status-frame"] then
        player.gui.top["sl-extended-frame"]["upgrade-planner-status-frame"].destroy()
      end
    end

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_player_ammo_inventory_changed, function(event)

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_player_quickbar_inventory_changed, function(event)

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_player_crafted_item, function(event)

  	if ENABLE_ITEMCOUNT then
      itemcount_checkstack(event)
  	end

end)

script.on_event(defines.events.on_tick, function(event)
    
  -- You could spread out the players over multiple ticks. But I don't intend to have too many players
  	if event.tick % TICKS_BETWEEN_SLAPS == 0 then
    	for index, player in pairs(game.players) do
      		if player.valid and player.connected and slapsLeft(player) > 0 then
        		slap(player)
      		end
    	end
  	end

  	if event.tick % TICKS_BETWEEN_CHECKS_AUTOHIDEMINIMAP == 0 then
    	if ENABLE_AUTO_HIDE_MINI_MAP then
      		autohideminimap_update(event)
    	end
  	end

  	if event.tick % TICKS_BETWEEN_CHECKS_PLAYERGUIOPENED == 0 then
		for i, player in pairs(game.players) do
			sl_gui_update_frame(player)
    	end
  	end

end)

script.on_event(defines.events.on_train_changed_state, function(event)

  	if ENABLE_TRAIN_COLOR then
    	traincolor_on_train_changed_state(event)
  	end

end)


local function player_joined(event)
	local player = game.players[event.player_index]
	player.insert { name = "raw-fish", count = 4 }
	player.insert { name = "iron-gear-wheel", count = 8 }
	player.insert { name = "iron-plate", count = 16 }
	player.print("Welcome to our Server. You can join our Discord at: redmew.com/discord")
	player.print("And remember.. Keep Calm And Spaghetti!")
end

function walkabout(player_name, distance)
	game.player.print("This command moved to /walkabout.")
end

local hodor_messages = {{"Hodor.", 16}, {"Hodor?", 16},{"Hodor!", 16}, {"Hodor! Hodor! Hodor! Hodor!", 4}, {"Hodor :(",4}, {"Hodor :)",4}, {"HOOOODOOOR!", 4}, {"( ͡° ͜ʖ ͡°)",1}, {"☉ ‿ ⚆",1}}
local message_weight_sum = 0
for _,w in pairs(hodor_messages) do
message_weight_sum = message_weight_sum + w[2]
end

function hodor(event)
	local message = event.message:lower()
	if message:match("hodor") then
		local index = math.random(1, message_weight_sum)
		local message_weight_sum = 0
		for _,m in pairs(hodor_messages) do
			message_weight_sum = message_weight_sum + m[2]
			if message_weight_sum >= index then
				game.print("Hodor: " .. m[1])
				return
			end
		end
	end
	if message:match("discord") then
		if game.player then
			game.player.print("Did you ask about our discord server?")
			game.player.print("You can find it here: redmew/discord")
		end
	end
end

Event.register(defines.events.on_player_created, player_joined)
Event.register(defines.events.on_console_chat, hodor)
