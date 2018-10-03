global.follows = {}
global.follows.n_entries = 0
local Utils = require "utils.utils"
local Game = require 'utils.game'

function get_direction(follower, target)
  local delta_x = target.position.x - follower.position.x
  local delta_y = follower.position.y - target.position.y --reversed x axis
  local a = delta_y/delta_x
  if a >= -1.5 and a < -0.5 then
    --SE OR NW
    if delta_x > 0 then
      return defines.direction.southeast
    else
      return defines.direction.northwest
    end
  elseif a >= -0.5 and a < 0.5  then
    --E OR W
    if delta_x > 0 then
      return defines.direction.east
    else
      return defines.direction.west
    end
  elseif a >= 0.5 and a < 1.5 then
    --NE OR SW
    if delta_x > 0 then
      return defines.direction.northeast
    else
      return defines.direction.southwest
    end
  else
    -- N or S
    if a < 0 then delta_x = - delta_x end -- mirrow x axis if  player is NNW or SSE
    if  delta_x > 0 then
      return defines.direction.north
    else
      return defines.direction.south
    end
  end
end

function walk_on_tick()
  if global.follows.n_entries > 0 then
    for k,v in pairs(global.follows) do
      local follower = game.playesr[k]
      local target = game.players[v]
      if follower ~= nil and target ~= nil then
        local d = Utils.distance(follower, target)
        if follower.connected and target.connected and d < 32 then
          if d > 5 then
            direction = get_direction(follower, target)
            follower.walking_state = {walking = true, direction = direction}
          end
        else
          global.follows[follower.name] = nil
          global.follows.n_entries = global.follows.n_entries - 1
        end
      end
    end
  end
end
