--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 23.11.2018 20:47 via IntelliJ IDEA
-- Many thanks to Linaori and the Diggy scenario for inspiring me coding like this
-- Also many thanks to Valansch and grilledham showing me how to use RedMew framework
-- And, of course, greetings to the whole RedMew community. It´s a pleasure <3
--

local Event = require 'utils.event'
local Game = require 'utils.game'
local insert = table.insert

--local GameStart = require 'map_gen.combined.racetrack.GameStart'
local Player = require 'map_gen.combined.racetrack.Player'
local GameData = require 'map_gen.combined.racetrack.GameData'

local Item = {}


-- new EVENTs by this module
Item.events = {
    on_coin_mined = script.generate_event_name()
}


-- ITEMs used ingame by mining coins.
local itemstack = {
    {health = 100, type = 'chest', size = '1x1', name = 'wooden-chest'},
    {health = 200, type = 'chest', size = '1x1', name = 'iron-chest'},
    {health = 350, type = 'chest', size = '1x1', name = 'steel-chest'},
    {health = 350, type = 'chest', size = '1x1', name = 'logistic-chest-active-provider'},
    {health = 350, type = 'chest', size = '1x1', name = 'logistic-chest-passive-provider'},
    {health = 350, type = 'chest', size = '1x1', name = 'logistic-chest-storage'},
    {health = 350, type = 'chest', size = '1x1', name = 'logistic-chest-buffer'},
    {health = 350, type = 'chest', size = '1x1', name = 'logistic-chest-requester'},

    {health = 150, type = 'belt', size = '1x1', name = 'transport-belt'},
    {health = 150, type = 'belt', size = '1x1', name = 'underground-belt'},
    {health = 170, type = 'belt', size = '1x2', name = 'splitter'},
    {health = 160, type = 'belt', size = '1x1', name = 'fast-transport-belt'},
    {health = 160, type = 'belt', size = '1x1', name = 'fast-underground-belt'},
    {health = 180, type = 'belt', size = '1x2', name = 'fast-splitter'},
    {health = 170, type = 'belt', size = '1x1', name = 'express-transport-belt'},
    {health = 170, type = 'belt', size = '1x1', name = 'express-underground-belt'},
    {health = 190, type = 'belt', size = '1x2', name = 'express-splitter'},

    {health = 100, type = 'inserter', size = '1x1', name = 'burner-inserter'},
    {health = 150, type = 'inserter', size = '1x1', name = 'inserter'},
    {health = 160, type = 'inserter', size = '1x1', name = 'long-handed-inserter'},
    {health = 150, type = 'inserter', size = '1x1', name = 'fast-inserter'},
    {health = 150, type = 'inserter', size = '1x1', name = 'filter-inserter'},
    {health = 160, type = 'inserter', size = '1x1', name = 'stack-inserter'},
    {health = 160, type = 'inserter', size = '1x1', name = 'stack-filter-inserter'},

    {health = 100, type = 'pole', size = '1x1', name = 'small-electric-pole'},
    {health = 100, type = 'pole', size = '1x1', name = 'medium-electric-pole'},
    {health = 150, type = 'pole', size = '2x2', name = 'big-electric-pole'},
    {health = 200, type = 'pole', size = '2x2', name = 'substation'},

    {health = 100, type = 'pipe', size = '1x1', name = 'pipe'},
    {health = 150, type = 'pipe', size = '1x1', name = 'pipe-to-ground'},
    {health = 180, type = 'pipe', size = '1x2', name = 'pump'},
    {health = 180, type = 'pipe', size = '3x3', name = 'storage-tank'},

    {health = 120, type = 'combinator', size = '1x1', name = 'constant-combinator'},
    {health = 150, type = 'combinator', size = '1x2', name = 'decider-combinator'},
    {health = 150, type = 'combinator', size = '1x2', name = 'arithmetic-combinator'},

    {health = 300, type = 'machine', size = '3x3', name = 'assembling-machine-1'},
    {health = 350, type = 'machine', size = '3x3', name = 'assembling-machine-2'},
    {health = 400, type = 'machine', size = '3x3', name = 'assembling-machine-3'},
    {health = 300, type = 'machine', size = '3x3', name = 'chemical-plant'},
    {health = 350, type = 'machine', size = '3x3', name = 'centrifuge'},
    {health = 350, type = 'machine', size = '3x3', name = 'electric-furnace'},
    {health = 150, type = 'machine', size = '3x3', name = 'lab'},
    {health = 200, type = 'machine', size = '2x2', name = 'stone-furnace'},
    {health = 300, type = 'machine', size = '2x2', name = 'steel-furnace'},
    {health = 200, type = 'machine', size = '3x3', name = 'beacon'},

    {health = 100, type = 'other', size = '1x1', name = 'small-lamp'},
    {health = 150, type = 'other', size = '1x1', name = 'programmable-speaker'},
    {health = 150, type = 'other', size = '2x2', name = 'accumulator'},
    {health = 500, type = 'other', size = '5x5', name = 'nuclear-reactor'},
    {health = 200, type = 'other', size = '2x3', name = 'heat-exchanger'},
    {health = 200, type = 'other', size = '2x3', name = 'boiler'},
    {health = 200, type = 'other', size = '3x3', name = 'solar-panel'},
    {health = 300, type = 'other', size = '3x5', name = 'steam-turbine'},
    {health = 400, type = 'other', size = '3x5', name = 'steam-engine'},
    {health = 500, type = 'other', size = '4x4', name = 'roboport'},

    {health = 200, type = 'useless', size = '1x1', count = '10', name = 'heat-pipe'},             -- useless items because you can
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'stone-brick'},             -- drive over them or they do nothing usefull
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'concrete'},
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'hazard-concrete'},
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'refined-concrete'},
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'refined-hazard-concrete'},
    {health = 1, type = 'useless', size = '1x1', count = '10', name = 'concrete'},
    {health = 100, type = 'useless', size = '1x1', count = '7', name = 'logistic-robot'},
    {health = 100, type = 'useless', size = '1x1', count = '7', name = 'construction-robot'},
}

local item_types = {'other', 'chest', 'belt', 'inserter', 'pole', 'pipe', 'combinator', 'machine', 'useless'}


-- local functions
local function parse_itemstack(itemstack, type, health, size)
    local result = {}

    for _, data in pairs(itemstack) do
        if data.type == type then
            insert(result, data)
        end
    end

    return result
end
-- ---------------------------------------------------------------------------------------------------------------------


-- EVENTS
local function on_player_mined_item(event)
    local player = Game.get_player_by_index(event.player_index)
    local item = event.item_stack

    if item.name == 'coin' then
        script.raise_event(
            Item.events.on_coin_mined, { item = item, player = player }
        )
    end
end

local function on_coin_mined(event)
    local player = event.player
    --local game_data = GameStart.get_game_data()

    -- only count up collected coins when game was started
    if GameData.get_value('started') == true then
        local coins = Player.get_value(player, 'collected_coins')
        Player.set_value(player, 'collected_coins', coins + 1)
    end

    -- get a random item type
    local count_item_types = #item_types
    local random_item_type = math.random(1, count_item_types)
    local random_type = item_types[random_item_type]

    -- get a random item out of the type
    local items_of_type = parse_itemstack(itemstack, random_type)
    local count_items_of_type = #items_of_type
    local random_item_of_type = math.random(1, count_items_of_type)
    local random_item = items_of_type[random_item_of_type]

    random_item.force = player.name         -- set the force for the item, nobody else can decontruct the item. Force name is players name

    -- place the random item in the inventory of the player
    if random_item.count ~= nil then
        player.insert{name = random_item.name, count = math.random(1, random_item.count)}
    else
        player.insert{name = random_item.name, count = 1}
    end
    -- remove the mined item (the coin)
    player.remove_item{name = 'coin', count = 1}
end
-- ---------------------------------------------------------------------------------------------------------------------


function Item.register(config)
    Event.add(defines.events.on_player_mined_item, on_player_mined_item)
    Event.add(Item.events.on_coin_mined, on_coin_mined)
end

return Item
