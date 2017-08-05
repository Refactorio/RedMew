global.ships = {}
Ship = {}
Ship.__index = Ship




function Ship.new(type)
  local self = setmetatable({}, Ship)
  self.Speed = 20 -- 20 is slowest 1 is fastest
  local type = type
  local direction = 0
  local position = {}
  local center = {} -- relative
  local captain = {} -- player
  local sailors = {} -- list of players
  local orientations = {}
  orientations[0] = {entities = {}, tiles = {}}
  orientations[2] = {entities = {}, tiles = {}}
  orientations[4] = {entities = {}, tiles = {}}
  orientations[6] = {entities = {}, tiles = {}}
  local removed_tiles_to_be_replaced = {} -- Maps of position --> entity

  self.place = function(position) -- add itself to global.ships and place entities
  end
  self.move = function()
    if captain ~= nil and captain.connected then
      --move
    else
      if captain.connected then
        captain = nil
      end
    end
  end
  self.board = function(player)
  end
  self.leave = function()
  end
  return self
end

function on_tick()
  for _,ship in pairs(global.ships)
    if game.tick % ship.Speed == 0 then
      ship.move()
    end
  end
end
