local Event = require 'utils.event'
local Global = require 'utils.global'
local Retailer = require 'features.retailer'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Daedalus\' Domain')
ScenarioInfo.set_map_description([[
  - You start with a Market, collect money from biter corpses to purchase useful equipments
  - Biters can freely path in undiscovered chunks of the map. However, biters cannot path through the maze's walls
]])
ScenarioInfo.set_map_extra_info([[
  [font=default-bold]Prepare to meet your fate in [color=purple]Daedalus' Domain[/color]![/font]

  In the shadow of a monumental disaster on Dedalus' Domain, your spacecraft has crash-landed deep within the remnants of a once-thriving outpost. The surface is a treacherous expanse of hostile environments, but beneath lies a twisting maze of ancient corridors and forgotten technologies waiting to be unearthed.

  Surrounded by malfunctioning defense drones and remnants of advanced machinery, your only hope for survival is to harness this labyrinthine landscape. Each turn reveals new challenges and threats, from enigmatic alien creatures lurking in the shadows to hazardous anomalies from the planet's turbulent past.

  To thrive in this unsettling world, you must navigate the intricacies of Daedalus' Domain while scavenging for resources and rebuilding your technology. Build a network of supply routes to efficiently transport materials through the maze and establish safe outposts to strengthen your foothold. Strategically deploy drones and turrets to fend off relentless foes and utilize ancient blueprints to unlock advanced crafting capabilities.

  Your ultimate goal is to reclaim the surface, a task that requires ingenuity, patience, and efficient problem-solving amid the chaos. Channel the planet's rich resources and harness the power of Krastorio2's innovative technologies to piece together your escape. Remember, every passage could lead to either salvation or doom.

  Prepare for an adventure like no other in the Labyrinthine Ruins of Dedalus' Domain. It's time to reclaim your destiny.

  Good luck, and may your wits guide you through the maze!
  The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_new_info([[
  2024-07-31:
    - Added Krastorio2 maze scenario: Daedalus' Domain
]])

local wall_thickness = 1
local cell_size = 3 -- must be an uneven number
local wall_delta = math.floor((cell_size - wall_thickness) / 2)

local pixels = {}
local cells = {}

local primitives = { max = 0, rnd_p = 1, walk_seed_w = 0, walk_seed_h = 0 }
local rects = {}
local shuffle_pool = {}

local k2_items = {
  {
    name = 'temporary-running-speed-bonus',
    name_label = { 'market_items.running_speed_bonus_name_label' },
    type = 'temporary-buff',
    description = { 'market_items.running_speed_bonus_description' },
    sprite = 'technology/exoskeleton-equipment',
    stack_limit = 1,
    price = 10,
  },
  {
    name = 'temporary-mining-speed-bonus',
    name_label = { 'market_items.mining_speed_bonus_name_label' },
    type = 'temporary-buff',
    description = { 'market_items.mining_speed_bonus_description' },
    sprite = 'technology/mining-productivity-1',
    stack_limit = 1,
    price = 10,
  },
  { price = 10,   name = 'burner-mining-drill' },
  { price = 5,    name = 'small-electric-pole' },
  { price = 15,   name = 'medium-electric-pole' },
  { price = 50,   name = 'big-electric-pole' },
  { price = 250,  name = 'substation' },
  { price = 20,   name = 'landfill' },
  { price = 2,    name = 'raw-fish' },
  { price = 3,    name = 'rail' },
  { price = 2,    name = 'rail-signal' },
  { price = 2,    name = 'rail-chain-signal' },
  { price = 15,   name = 'train-stop' },
  { price = 75,   name = 'locomotive' },
  { price = 30,   name = 'cargo-wagon' },
  { price = 2800, name = 'artillery-wagon' },

  { price = 15,   name = 'submachine-gun' },
  { price = 15,   name = 'shotgun' },
  { price = 250,  name = 'combat-shotgun' },
  { price = 250,  name = 'flamethrower' },
  { price = 175,  name = 'rocket-launcher' },
  { price = 375,  name = 'heavy-rocket-launcher' },

  { price = 2,    name = 'shotgun-shell' },
  { price = 10,   name = 'piercing-shotgun-shell' },

  { price = 2,    name = 'rifle-magazine' },
  { price = 8,    name = 'armor-piercing-rifle-magazine' },
  { price = 25,   name = 'uranium-rifle-magazine' },

  { price = 5,    name = 'anti-material-rifle-magazine' },
  { price = 12,   name = 'armor-piercing-anti-material-rifle-magazine' },
  { price = 35,   name = 'uranium-anti-material-rifle-magazine' },

  { price = 30,   name = 'flamethrower-ammo' },

  { price = 25,   name = 'cannon-shell' },
  { price = 35,   name = 'explosive-cannon-shell' },
  { price = 85,   name = 'explosive-uranium-cannon-shell' },

  { price = 120,  name = 'artillery-shell' },
  { price = 1200, name = 'nuclear-artillery-shell' },

  { price = 18,   name = 'rocket' },
  { price = 30,   name = 'explosive-rocket' },

  { price = 250,  name = 'heavy-rocket' },
  { price = 2500, name = 'atomic-bomb' },

  { price = 5,    name = 'land-mine' },
  { price = 10,   name = 'grenade' },
  { price = 45,   name = 'cluster-grenade' },

  { price = 15,   name = 'defender-capsule' },
  { price = 85,   name = 'destroyer-capsule' },
  { price = 45,   name = 'poison-capsule' },
  { price = 45,   name = 'slowdown-capsule' },

  { price = 2000, name = 'artillery-turret' },

  { price = 900,  name = 'modular-armor' },
  { price = 3000, name = 'power-armor' },

  { price = 80,   name = 'solar-panel-equipment' },
  { price = 1250, name = 'fission-reactor-equipment' },
  { price = 200,  name = 'battery-equipment' },
  { price = 950,  name = 'battery-mk2-equipment' },
  { price = 250,  name = 'belt-immunity-equipment' },
  { price = 200,  name = 'night-vision-equipment' },
  { price = 350,  name = 'exoskeleton-equipment' },
  { price = 500,  name = 'personal-roboport-equipment' },
  { price = 75,   name = 'construction-robot' },
  { price = 550,  name = 'energy-shield-equipment' },
  { price = 950,  name = 'personal-laser-defense-equipment' },

  { price = 800,  name = 'dt-fuel' },
}

Global.register(
  {
    primitives = primitives,
    rects = rects,
    shuffle_pool = shuffle_pool,
  },
  function(tbl)
    primitives = tbl.primitives
    rects = tbl.rects
  end
)

local function add_tile(x, y, width, height, add_cell)
  if add_cell then
    if cells[x] == nil then
      cells[x] = {}
    end
    cells[x][y] = 1
  end
  for xpos = x, x + width - 1 do
    for ypos = y, y + height - 1 do
      if pixels[xpos] == nil then
        pixels[xpos] = {}
      end
      pixels[xpos][ypos] = 1
    end
  end
end

primitives.max = 0
local function render()
  for x, _ in pairs(pixels) do
    for y, _ in pairs(pixels[x]) do
      if y * 32 > primitives.max and y % 2 == 0 then
        primitives.max = y * 32
      end
      rects[x * 32 .. '/' .. y * 32] = 1
    end
  end
end

primitives.rnd_p = 1
local function psd_rnd(l)
  while shuffle_pool[primitives.rnd_p] < l do
    primitives.rnd_p = primitives.rnd_p + 1
  end
  local res = shuffle_pool[primitives.rnd_p]
  primitives.rnd_p = primitives.rnd_p + 1
  return res
end

local function shuffle(t)
  for i = 1, #t - 1 do
    local r = psd_rnd(i, #t)
    t[i], t[r] = t[r], t[i]
  end
end

-- builds a width-by-height grid of trues
local function initialize_grid(w, h)
  local a = {}
  for i = 1, h do
    table.insert(a, {})
    for j = 1, w do
      table.insert(a[i], true)
    end
  end
  return a
end

-- average of a and b
local function avg(a, b)
  return (a + b) / 2
end

local dirs = {
  { x = 0, y = -2 }, -- north
  { x = 2, y = 0 }, -- east
  { x = -2, y = 0 }, -- west
  { x = 0, y = 2 }, -- south
}

local function make_maze(w, h)
  local map = initialize_grid(w * 2 + 1, h * 2 + 1)

  local walk
  walk = function(x, y)
    map[y][x] = false

    local d = { 1, 2, 3, 4 }
    shuffle(d)
    for i, dirnum in pairs(d) do
      local xx = x + dirs[dirnum].x
      local yy = y + dirs[dirnum].y
      if map[yy] and map[yy][xx] then
        map[avg(y, yy)][avg(x, xx)] = false
        walk(xx, yy)
      end
    end
  end
  walk(primitives.walk_seed_w, primitives.walk_seed_h)

  local s = {}
  for i = 1, h * 2 + 1 do
    for j = 1, w * 2 + 1 do
      if map[i][j] then
        add_tile(i * cell_size, j * cell_size, cell_size, cell_size, true)
      end
    end
  end
  return table.concat(s)
end

local function reduce_walls()
  for x, _ in pairs(cells) do
    for y, _ in pairs(cells[x]) do
      if cells[x - cell_size] ~= nil and cells[x - cell_size][y] ~= 1 then
        add_tile(x - wall_delta, y, wall_delta, cell_size, false)
      end
      if cells[x + cell_size] ~= nil and cells[x + cell_size][y] ~= 1 then
        add_tile(x + cell_size, y, wall_delta, cell_size, false)
      end
      if cells[x] ~= nil and cells[x][y - cell_size] ~= 1 then
        add_tile(x - wall_delta, y - wall_delta, cell_size + 2 * wall_delta, wall_delta, false)
      end
      if cells[x] ~= nil and cells[x][y + cell_size] ~= 1 then
        add_tile(x - wall_delta, y + cell_size, cell_size + 2 * wall_delta, wall_delta, false)
      end
    end
  end
end

local function remove_chunk(event)
  local surface = event.surface
  local tiles = {}
  for x = event.area.left_top.x, event.area.right_bottom.x do
    for y = event.area.left_top.y, event.area.right_bottom.y do
      table.insert(tiles, { name = 'out-of-map', position = { x, y } })
    end
  end
  surface.set_tiles(tiles)
end

Event.on_init(function()
  if Retailer.get_market_group_label('fish_market') ~= 'Market' then
    local fish_items = Retailer.get_items('fish_market')

    for _, prototype in pairs(fish_items) do
      Retailer.remove_item('fish_market', prototype.name)
    end

    for _, prototype in pairs(k2_items) do
      Retailer.set_item('fish_market', prototype)
    end
  end

  primitives.walk_seed_w = math.random(1, 50) * 2
  primitives.walk_seed_h = math.random(1, 50) * 2
  for i = 1, 20000 do
    shuffle_pool[i] = math.random(1, 4)
  end
  make_maze(50, 50)
  reduce_walls()
  render()
end)

Event.add(defines.events.on_chunk_generated, function(event)
  if event.surface == RS.get_surface() then
    local pos = event.area.left_top
    if math.abs(pos.x) > 10000 or math.abs(pos.y) > 10000 or
        (rects[pos.x + primitives.max / 2 .. '/' .. pos.y + primitives.max / 2] == nil) then
      remove_chunk(event)
    end
  end
end)
