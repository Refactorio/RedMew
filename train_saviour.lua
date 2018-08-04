local Event = require 'utils.event'

search_range = 1 -- distance to search for the killer train
saviour_token_name = "coin" -- item name for what saves players
saviour_timeout = 60 -- number of ticks players are train immune after getting hit (roughly)
saviour_token_cost = 1 -- number of tokens required to save a life

function on_pre_death(evt, cause)
  player = game.players[evt.player_index]
  local saviour_tokens = player.get_item_count(saviour_token_name)
  local trains = player.surface.find_entities_filtered
  {
    area =
    {{player.position.x - search_range, player.position.y - search_range},
    {player.position.x + search_range, player.position.y + search_range}},
    type= {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}
  }
   -- create the table of records
  if global.player_train_saviour_records == nil then
    global.player_train_saviour_records = {}
  end
  -- check that there's a train within 1 tile, that the player has a token
  if #trains > 0 and saviour_tokens >= saviour_token_cost then
	player.character.health = 1
  -- check that they're not already being saved (to prevent spam and invincibility)
    if global.player_train_saviour_records[player.index] == nil then
      -- print a little message and format it depending if it costs 1 or multiple of an the token
      if saviour_token_cost == 1 then
        message = '%s was saved from a train death. Their %s will soon crumble into dust.'
        game.print(string.format(message, player.name, saviour_token_name))
      else
        message = '%s was saved from a train death. Their %i %ss will soon crumble into dust.'
        game.print(string.format(message, player.name, saviour_token_cost, saviour_token_name))
      end
      -- record their time of saving as well as the fact they're saved
      global.player_train_saviour_records[player.index] = {
        start_tick = game.tick,
        player_saved = 1
      }
	  end
  end
end

script.on_event(defines.events.on_pre_player_died, on_pre_death)

-- every 3 seconds check if players' train immunity has expired, if it has remove a coin and remove their record
local function on_180_ticks()
    if game.tick % 900 == 0 then
        if global.player_train_saviour_records then
            for k, v in pairs(global.player_train_saviour_records) do
                if game.tick - v.start_tick > saviour_timeout then
                    player.remove_item{name = saviour_token_name, count = saviour_token_cost}
                    global.player_train_saviour_records[player.index] = nil
                end
            end
        end
    end
end

Event.on_nth_tick(180, on_180_ticks)
