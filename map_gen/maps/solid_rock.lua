--[[
    The theme of the map is no underground belts or pipes.
    For balance, logistics systems research is disabled.
]]
local b = require 'map_gen.shared.builders'
local RecipeLocker = require 'utils.recipe_locker'
local table = require 'utils.table'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local ScenarioInfo = require 'features.gui.info'
local MGSP = require 'resources.map_gen_settings'
local market_items = require 'resources.market_items'

local insert = table.insert
local config = global.config

ScenarioInfo.set_map_name('Solid Rock')
ScenarioInfo.set_map_description("The entire planet is so solid that we can't seem to dig into it.")
ScenarioInfo.add_map_extra_info([[
- This planet's ground is completely impenetrable.
- This planet has a magnetic field that will make logistics systems impossible.
- We brought wood and rail on our journey and it is available in the market.
- The beasts on this planet are savage and unrelenting.
]])

RS.set_map_gen_settings({MGSP.enemy_very_high, MGSP.tree_none, MGSP.cliff_high})

config.hail_hydra.enabled = true

-- Setup market inventory
config.market.enabled = true
local items_to_modify = {
    {name = 'rail', price = 0.25},
    {name = 'rail-signal', price = 1},
    {name = 'rail-chain-signal', price = 1},
    {name = 'train-stop', price = 7.5},
    {name = 'locomotive', price = 35},
    {name = 'cargo-wagon', price = 15},
    {name = 'raw-wood', price = 0.25}
}

-- Modify market items
for i = 1, #items_to_modify do
    insert(market_items, items_to_modify[i])
end

RecipeLocker.lock_recipes(
    {
        'underground-belt',
        'fast-underground-belt',
        'express-underground-belt',
        'pipe-to-ground',
        'logistic-chest-requester',
        'logistic-chest-buffer',
        'logistic-chest-active-provider'
    }
)

Event.on_init(
    function()
        game.forces.player.technologies['logistic-system'].enabled = false
    end
)

-- Map

local function no_rocks(_, _, world, tile)
    local x, y = world.x, world.y
    local ents = world.surface.find_entities_filtered {area = {{x, y}, {x + 1, y + 1}}, type = 'simple-entity'}
    for i = 1, #ents do
        ents[i].destroy()
    end

    return tile
end

local start = b.full_shape
start = b.change_map_gen_collision_tile(start, 'ground-tile', 'refined-concrete')
start = b.change_map_gen_collision_hidden_tile(start, 'ground-tile', 'lab-dark-2')
local map = b.if_else(start, b.full_shape)

map = b.apply_effect(map, no_rocks)

return map
