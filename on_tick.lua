local function on_tick()
	if game.tick % 60 == 0 then
    poll_on_second()
		walk_distance_on_second()
    if game.tick % 120 == 0 then
      pet_on_120_ticks()
			if game.tick % 1200 == 0 then
				player_list_on_12_seconds()
			end
    elseif  game.tick % 180 == 0 then
      fish_market_on_180_ticks()
    end
  end
end

Event.register(defines.events.on_tick, on_tick)
