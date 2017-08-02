ship = {
  dimentions = {x=3,y=5},
  center = {x=1, y = 2},
  direction = 0,
  last_direction = 0,
  position = {},
  ground = {

  },
  entities = {
    {name = "pipe", position = {x = 0, y = 0}},
    {name = "pipe", position = {x = 1, y = 0}},
    {name = "pipe", position = {x = 2, y = 0}},
    {name = "pipe", position = {x = 0, y = 1}},
    {name = "pipe", position = {x = 2, y = 1}},
    {name = "pipe", position = {x = 0, y = 2}},
    {name = "pipe", position = {x = 2, y = 2}},
    {name = "pipe", position = {x = 0, y = 3}},
    {name = "pipe", position = {x = 2, y = 3}},
    {name = "pipe", position = {x = 0, y = 4}},
    {name = "pipe", position = {x = 2, y = 4}},
    {name = "steel-chest", position = {x = 1, y = 3}},
    {name = "offshore-pump", position = { x = 1, y = 4}}
  },
  tiles = {
      {name = "concrete", position = {x = 0, y = 0}},
      {name = "concrete", position = {x = 1, y = 0}},
      {name = "concrete", position = {x = 2, y = 0}},
      {name = "concrete", position = {x = 0, y = 1}},
      {name = "concrete", position = {x = 1, y = 1}},
      {name = "concrete", position = {x = 2, y = 1}},
      {name = "concrete", position = {x = 0, y = 2}},
      {name = "concrete", position = {x = 1, y = 2}},
      {name = "concrete", position = {x = 2, y = 2}},
      {name = "concrete", position = {x = 0, y = 3}},
      {name = "concrete", position = {x = 1, y = 3}},
      {name = "concrete", position = {x = 2, y = 3}},
      {name = "concrete", position = {x = 0, y = 4}},
      {name = "concrete", position = {x = 1, y = 4}},
      {name = "concrete", position = {x = 2, y = 4}}
  }
}


function place_ship(pos)

  ship.position = pos or ship.position

  local tiles = {}
  for _,v in pairs(ship.tiles) do
    local tile = {name = v.name, position = {}}
    local pos = translate(ship, {x = v.position.x, y = v.position.y})
    tile.position.x = pos.x
    tile.position.y = pos.y
    table.insert(tiles, tile)
  end
  game.surfaces[1].set_tiles(tiles)

  local entities = {}
  for k,v in pairs(ship.entities) do
    local entity = {name = v.name, position = {}, direction = (ship.direction + 4) % 8}
    local pos = translate(ship, {x = v.position.x, y = v.position.y})
    entity.position.x = pos.x
    entity.position.y = pos.y
    game.surfaces[1].create_entity(entity)
  end

  game.players[1].teleport({ship.position.x + 1.5, ship.position.y + 2.5})
end

function remove_ship()
  local tiles = {}
  for _,v in pairs(ship.tiles) do
    local pos = translate(ship, v.position, ship.last_direction)
    local tile = {position = {x = pos.x, y = pos.y}}
    tile.name = "water"
    table.insert(tiles, tile)
  end
  game.surfaces[1].set_tiles(tiles, false)
end

move = false
local offset = {x = 0, y = 0}
function move_ship()
  if move then
    if offset.x ~= 0 or offset.y ~= 0 then
      game.players[1].teleport({0, 0})
      remove_ship()
      ship.position.x = ship.position.x + offset.x
      ship.position.y = ship.position.y + offset.y
      place_ship(ship.position)
      local player_pos = translate(ship, {x = ship.center.x, y = ship.center.y})
      game.players[1].teleport({x = player_pos.x + 0.5, y = player_pos.y + 0.5})
      ship.last_direction = ship.direction
    end
  end
end

function translate(ship, pos, last_direction)
  local direction = last_direction or ship.direction
  local center_rel = {x = ship.center.x, y = ship.center.y}
  pos_rel = {}
  pos_rel.x = pos.x
  pos_rel.y = pos.y
  if direction == 2 then
    pos_rel.x = center_rel.y - pos.y + center_rel.x
    pos_rel.y = - (center_rel.x - pos.x) + center_rel.y
  elseif direction == 4 then
    pos_rel.y = ship.dimentions.y - pos.y
  elseif direction == 6 then
    pos_rel.x = ship.dimentions.x - (center_rel.y - pos.y + center_rel.x)
    pos_rel.y = ship.dimentions.x + (center_rel.x - pos.x) - center_rel.y
  end
  return {x = pos_rel.x + ship.position.x, y = pos_rel.y + ship.position.y}
end

function check_movement()
  local dir = game.players[1].walking_state.direction
  ship.direction = dir
  if game.players[1].walking_state.walking then
    if dir == 0 then
      offset.x = 0
      offset.y = -1
    elseif dir == 4 then
      offset.x = 0
      offset.y = 1
    elseif dir == 2 then
      offset.x = 1
      offset.y = 0
    elseif dir == 6 then
      offset.x = -1
      offset.y = 0
    end
  end
end
