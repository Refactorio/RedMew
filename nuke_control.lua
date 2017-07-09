


local function allowed_to_nuke(player)
  return player.admin or is_mod(player.name) or is_regular(player.name) or ((player.online_time / 216000) > global.scenario.config.nuke_min_time_hours)
end


local function ammo_changed(event)
  local player = game.players[event.player_index]
    if allowed_to_nuke(player) then return end
  local nukes = player.remove_item({name="atomic-bomb", count=1000})--.remove_item("atomic-bomb")
  if nukes > 0 then
    game.print(player.name .. " tried to use a nuke, but instead dropped it on his foot.")
    player.character.health = 0
  end
end
Event.register(defines.events.on_player_ammo_inventory_changed, ammo_changed)
