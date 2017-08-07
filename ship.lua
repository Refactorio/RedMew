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

function debugw(s)
  if s == nil then s = "nil" end
  game.write_file("debug.txt", game.tick .. " " .. s .. "\n", true)
end

function Ship.new(ship_type)
  if  not global.scenario.variables.ship_type[ship_type] then error("Type does not exist", 2) end

  local self = setmetatable({}, Ship)
  self.Speed = 1 --global.scenario.variables.ship_type[ship_type] -- 20 is slowest 1 is fastest
  local type = type
  local direction = 0
  local position = {}
  local captain = {} -- player
  local sailors = {} -- list of players
  local orientations = {}
  local abs_center_tile = {}
  orientations[0] = deepcopy(global.scenario.variables.ship_type[ship_type])
  orientations[2] = {entities = {}, tiles = {}}
  orientations[4] = {entities = {}, tiles = {}}
  orientations[6] = {entities = {}, tiles = {}}
  local removed_tiles_to_be_replaced = {} -- Maps of position --> entity

  local remove_ship = function()
    game.surfaces[1].set_tiles(removed_tiles_to_be_replaced)
    removed_tiles_to_be_replaced = {}
  end

  local step = function()
      direction = captain.walking_state.direction
      if direction == 0 then
        position = {x = position.x, y = position.y - 1}
      elseif direction == 2 then
        position = {x = position.x + 1, y = position.y}
      elseif direction == 4 then
        position = {x = position.x, y = position.y + 1}
      elseif direction == 6 then
        position = {x = position.x - 1, y = position.y}
      end
  end

  self.place = function(pos) -- add itself to global.ships and place entities
    position = pos
    local tiles = {}
    for _,tile in pairs(orientations[direction].tiles) do
      local old_tile = game.surfaces[1].get_tile({x=tile.position.x + pos.x,y=tile.position.y + pos.y})
      table.insert(removed_tiles_to_be_replaced, {name = old_tile.name, position = old_tile.position})
      table.insert(tiles, {name = tile.name, position = {x=tile.position.x + pos.x,y=tile.position.y + pos.y}})
    end
    game.surfaces[1].set_tiles(tiles)

    for _,entity in pairs(orientations[direction].entities) do
      game.surfaces[1].create_entity({name = entity.name, direction = entity.direction, position = {x=entity.position.x + pos.x,y=entity.position.y + pos.y}})
    end
  end

  self.move = function()
    if captain ~= nil and captain.connected and captain.walking_state.walking then
      remove_ship()
      step()
      self.place(position)
      --captain.teleport({position.x + 0.5, position.y + 0.5})
    else
      if captain ~= nil and not captain.connected then
        captain = nil
        if table.size(sailors) > 0 then
          captain = table.get(sailors, 1)
        end
      end
    end
  end
  self.board = function(player)
    captain = player
    --captain.teleport({position.x + 0.5, position.y + 0.5})
  end
  self.leave = function()
  end

  for _,entity in pairs(orientations[0].entities) do
    entity.entity_number = nil
    local entity_rot = entity
    for _,i in pairs({2,4,6}) do
      entity_rot = {position = translate(entity_rot.position.x, entity_rot.position.y), name = entity.name}
      if entity.direction then entity_rot.direction = (i + 4) % 8 end
      table.insert(orientations[i].entities, entity_rot)
    end
  end
  for _,tile in pairs(orientations[0].tiles) do
    local tile_rot = tile
    for _,i in pairs({2,4,6}) do
      tile_rot = {position = translate(tile_rot.position.x, tile_rot.position.y), name = tile.name}
      table.insert(orientations[i].tiles, tile_rot)
    end
  end

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
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
