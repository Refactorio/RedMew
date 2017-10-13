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


-- sl_autohideminimap.lua
-- 20170507
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  daniel34 (minimap-autohide)


function autohideminimap_init()
  if not global.mapview then 
    global.mapview = {}
  end
  for i, player in pairs(game.players) do
    if global.mapview[i] == nil then
      global.mapview[i] = player.game_view_settings.show_minimap
    end
  end
end

function toggle_view(player_index, view)
  local settings = game.players[player_index].game_view_settings
  if settings[view] then
    settings[view] = false
  else
    settings[view] = true
  end
end

function toggle_view_map(event)
  toggle_view(event.player_index, "show_minimap")
  global.mapview[event.player_index] = game.players[event.player_index].game_view_settings.show_minimap
end

function set_map_view(player, state)
  if player.game_view_settings.show_minimap ~= state then
    toggle_view(player.index, "show_minimap")
  end
end

function to_toggle(selected)
  if selected.type == "logistic-container" then
    return true
  end
  if selected.type == "roboport" then
    return true
  end
  if selected.type == "locomotive" then
    return true
  end
  if selected.type == "cargo-wagon" then
    return true
  end
  return false
end

function autohideminimap_update(event)
  for i, player in pairs(game.players) do
    if player.connected then
      if global.mapview[i] then
        if player.selected and to_toggle(player.selected) then
          set_map_view(player, false)
        else
          set_map_view(player, true)
        end
      end
    end
  end
end
