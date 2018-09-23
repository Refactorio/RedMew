local Event = require "utils.event"
local Game = require 'utils.game'

Event.on_init(function()
  
  global.players = {}
  
  game.forces.enemy.set_cease_fire(game.forces.player ,true);
  game.forces.player.disable_research();
  game.forces.player.disable_all_prototypes();
  game.forces.player.set_ammo_damage_modifier("rocket", -3);

end)

Event.add(defines.events.on_player_created, function(event)
  local player = Game.get_player_by_index(event.player_index)
  --player.print("Info: PVP server mod 'Bearded Snails' (c) byte");
  guiNewPlayer(player.gui.left);
  printNewPlayer(player);
  
  player.insert{name="heavy-armor", count=1}
  player.insert{name="iron-plate", count=8}
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="burner-mining-drill", count = 1}
  player.insert{name="stone-furnace", count = 1}
  player.insert{name="shotgun", count = 1}
  player.insert{name="shotgun-shell", count = 10}
  player.character.character_running_speed_modifier = 0.5
  player.force.chart(player.surface, {{player.position.x - 200, player.position.y - 200}, {player.position.x + 200, player.position.y + 200}})
end)

Event.add(defines.events.on_player_respawned, function(event)
  local player = Game.get_player_by_index(event.player_index)
  
  player.insert{name="heavy-armor", count=1}
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="shotgun", count = 1}
  player.insert{name="shotgun-shell", count = 10}
  player.character.character_running_speed_modifier = 0.5
end)

Event.add(defines.events.on_rocket_launched, function(event)
  local force = event.rocket.force
  if event.rocket.get_item_count("satellite") > 0 then
    if global.satellite_sent == nil then
      global.satellite_sent = {}
    end
    if global.satellite_sent[force.name] == nil then
      game.set_game_state{game_finished=true, player_won=true, can_continue=true}
      global.satellite_sent[force.name] = 1
    else
      global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1
    end
    for index, player in pairs(force.players) do
      if player.gui.left.rocket_score == nil then
        local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption={"gui.score"}}
        frame.add{name="rocket_count_label", type = "label", caption={"", {"gui.rockets-sent"}, ":"}}
        frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
      else
        player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
      end
    end
  else
    for index, player in pairs(force.players) do
      player.print({"msg.gui-rocket-silo.rocket-launched-without-satellite"})
    end
  end
end)

Event.add(defines.events.on_gui_click, function(event)
  local player = Game.get_player_by_index(event.player_index)
  local gui = player.gui.left;

  if player.force == game.forces.player and event.element.name == "new_button" then
    if neForceNear(player.position) then
      local force = game.create_force(player.name);
      force.set_spawn_position(player.position, game.surfaces[1]);
      player.force = force;
      killBitters(player.position);
      player.force.chart(player.surface, {{player.position.x - 200, player.position.y - 200}, {player.position.x + 200, player.position.y + 200}})
	  player.force.set_ammo_damage_modifier("rocket", -3);
	  player.force.research_all_technologies();
      gui.new_force.destroy();
      guiForcePlayer(gui);
      player.print{"msg.force-created"}
      printForcePlayer(player)
    else
      player.print{"msg.close-position"}
    end
  elseif event.element.name == "inv_button" then
    local name = gui.own_force.inv_name.text;
    if name ~= nil and validPlayer(name) then
      local iplayer = Game.get_player_by_index(name);
      local igui = iplayer.gui.left;
      
      iplayer.force = player.force;
      iplayer.teleport(player.force.get_spawn_position(game.surfaces[1]));
      
      igui.new_force.destroy();
      guiForcePlayer(igui);
      player.print{"msg.player-invated", name}
      iplayer.print{"msg.you-invated", player.name}
    else
      player.print{"msg.invalid-name"}
    end
  elseif event.element.name == "leave_button" and gui.own_force.inv_name.text == "leave" then
    if #player.force.players == 1 then 
      game.merge_forces(player.force.name, game.forces.player.name);
      gui.own_force.destroy();
      guiNewPlayer(gui);
      player.print{"msg.force-destroyed"}
    elseif #player.force.players > 1 then
      player.force = game.forces.player;
      player.character.die();
      gui.own_force.destroy();
      guiNewPlayer(gui);
      player.print{"msg.force-leave"}
    end 
  elseif event.element.name == "leave_button" and gui.own_force.inv_name.text ~= "leave" then
    player.print{"msg.force-leave-confim"}
  end
end)

function neForceNear(pos)
  for k, v in pairs(game.forces) do
    if dist(pos, v.get_spawn_position(game.surfaces[1]))  <= 50 then
      return false;
    end
  end
  return true;
end

function killBitters(pos)
   for k, v in pairs(game.surfaces[1].find_entities_filtered({area={{pos.x - 250, pos.y - 250}, {pos.x + 250, pos.y + 250}}, force= "enemy"})) do
       v.destroy();
   end
end

function dist(position1, position2)
  return ((position1.x - position2.x)^2 + (position1.y - position2.y)^2)^0.5
end

function validPlayer(name)
  if name ~= nil and Game.get_player_by_index(name) ~= nil and Game.get_player_by_index(name).force == game.forces.player then
    return true;
  end
  return false;
end

function guiNewPlayer(gui)
  local frame = gui.add{type="frame", name="new_force", caption={"gui.create-force"}, direction="vertical"}
  frame.add{type="button", name="new_button", caption={"gui.new-force"}}
end

function guiForcePlayer(gui)
  local frame = gui.add{type="frame", name="own_force", caption={"gui.force"}, direction="vertical"}
  frame.add{type="textfield", name="inv_name"}
  frame.add{type="button", name="inv_button", caption={"gui.invite"}}
  frame.add{type="button", name="leave_button", caption={"gui.leave"}}
end

function printNewPlayer(player)
  --player.print{"msg.info13"}
  --player.print{"msg.info14"}
  player.print{"msg.info1"}
  player.print{"msg.info2"}
  player.print{"msg.info3"}
  player.print{"msg.info4"}
  player.print{"msg.info5"}
  --player.print{"msg.info6"}
  --player.print{"msg.info7"}
  --player.print{"msg.info8"}
end

function printForcePlayer(player)
  player.print{"msg.info11"}
  player.print{"msg.info12"}
end
