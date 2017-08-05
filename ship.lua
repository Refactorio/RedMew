global.ships = {}
Ship = {}
Ship.__index = Ship
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Ship.new(ship_type)
  if  not global.scenario.variables.ship_type[ship_type] then error("Type does not exist", 2) end

  local self = setmetatable({}, Ship)
  self.Speed = global.scenario.variables.ship_type[ship_type] -- 20 is slowest 1 is fastest
  local type = type
  local direction = 2
  local position = {}
  local captain = {} -- player
  local sailors = {} -- list of players
  local orientations = {}
  orientations[0] = deepcopy(global.scenario.variables.ship_type[ship_type])
  orientations[2] = {entities = {}, tiles = {}}
  orientations[4] = {entities = {}, tiles = {}}
  orientations[6] = {entities = {}, tiles = {}}
  local removed_tiles_to_be_replaced = {} -- Maps of position --> entity

  self.place = function(pos) -- add itself to global.ships and place entities
    position = pos
    local tiles = {}
    for _,tile in pairs(orientations[direction].tiles) do
      table.insert(tiles, {name = tile.name, position = {x=tile.position.x + pos.x,y=tile.position.y + pos.y}})
    end
    game.surfaces[1].set_tiles(tiles)

    for _,entity in pairs(orientations[direction].entities) do
      game.surfaces[1].create_entity({name = entity.name, direction = entity.direction, position = {x=entity.position.x + pos.x,y=entity.position.y + pos.y}})
    end

     game.player.teleport({x=position.x + 0.5,y=position.y + 0.5})

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

  for _,entity in pairs(orientations[0].entities) do
    entity.entity_number = nil
    for _,i in pairs({2,4,6}) do
      local entity_rot = {position = translate(entity.position.x, entity.position.y), name = entity.name}
      if entity.direction then entity_rot.direction = (i + 4) % 8 end
      table.insert(orientations[i].entities, entity_rot)
    end
  end
  for _,tile in pairs(orientations[0].tiles) do
    for _,i in pairs({2,4,6}) do
      table.insert(orientations[i].tiles, {position = translate(tile.position.x, tile.position.y), name = tile.name})
    end
  end
  game.print(dump(orientations[0].entities))
  return self
end



function ship_on_tick()
  for _,ship in pairs(global.ships) do
    if game.tick % ship.Speed == 0 then
      ship.move()
    end
  end
end


function translate(x, y)
  return {x = -y, y = x}
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
