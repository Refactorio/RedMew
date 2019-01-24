local Game = require 'utils.game'
local Retailer = require 'features.retailer'
local Command = require 'utils.command'
--local RS = require 'map_gen.shared.redmew_surface'

--The following entities cannot be built by the player or by bots
global.banned_entites = {
    ['transport-belt'] = true,
    ['fast-transport-belt'] = true,
    ['express-transport-belt'] = true,
    ['underground-belt'] = true,
    ['fast-underground-belt'] = true,
    ['express-underground-belt'] = true,
    ['splitter'] = true,
    ['fast-splitter'] = true,
    ['express-splitter'] = true,
    ['roboport'] = true,
}

-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Ultra Rail World')
ScenarioInfo.set_map_description('A regular rail world map with a catch. Can you launch a rocket without using belts or roboports?')
ScenarioInfo.set_map_extra_info('Use rail networks to do everything!\n- All rail materials are on sale in the market\n- Earn gold from killing worms and nests and mining trees and rocks')

--Modify the plater starting items to kickstart large complicated blueprint building
local player_create = global.config.player_create
player_create.starting_items = {
    {name = 'modular-armor', count = 1},
    {name = 'solar-panel-equipment', count = 7},
    {name = 'battery-equipment', count = 2},
    {name = 'personal-roboport-equipment', count = 2},
    {name = 'construction-robot', count = 25},
    {name = 'iron-gear-wheel', count = 8},
    {name = 'iron-plate', count = 16},
	{name = 'coin', count = 50}
}

--custom market function to spawn a rail-centric market
local function spawn_rail_market(_, player)
	local surface = player.surface
	local pos = player.position	
	pos.y = pos.y - 4
	local market_item = 'coin'
--market will contain only rail stuff, and equipment for later game
	local market_items ={
		--{price = .1, name = 'raw-fish'},
		{price = .1, name ='rail'},
		{price = 1, name ='rail-signal'},
		{price = 1, name ='rail-chain-signal'},
		{price = 5, name ='train-stop'},
		{price = 25, name ='locomotive'},
		{price = 10, name ='cargo-wagon'},
		{price = 20, name ='fluid-wagon'},
		{price = 350, name ='modular-armor'},
		{price = 875, name ='power-armor'},
		{price = 40, name ='solar-panel-equipment'},
		{price = 875, name ='fusion-reactor-equipment'},
		{price = 100, name ='battery-equipment'},
		{price = 625, name ='battery-mk2-equipment'},
		{price = 100, name ='night-vision-equipment'},
		{price = 150, name ='exoskeleton-equipment'},
		{price = 250, name ='personal-roboport-equipment'},
		{price = 750, name ='personal-roboport-mk2-equipment'},
		{price = 25, name ='construction-robot'},
		{price = 350, name ='energy-shield-equipment'},
		{price = 1050, name ='energy-shield-mk2-equipment'},
		{price = 750, name ='personal-laser-defense-equipment'},
		{price = 2625, name ='power-armor-mk2'},
	}
	local market = surface.create_entity({name = 'market', position = pos})
	
    market.destructible = false
    player.print("Rail market added. To remove it, highlight it with your cursor and run the command /sc game.player.selected.destroy()")
    Retailer.add_market('fish_market', market)

    for _, prototype in pairs(market_items) do
        Retailer.set_item('fish_market', prototype)
    end
end
--spawns rail market into the game
Command.add(
    'rail_market',
    {
        description = 'Places a rail market near you.',
        admin_only = true,
    },
    spawn_rail_market
)
--checks on entity built to remove disabled entities and return them to the player
script.on_event(defines.events.on_built_entity,
    function(event)
        local entity = event.created_entity
        if not entity or not entity.valid then
            return
        end

        local name = entity.name

        if name == 'tile-ghost' then
            return
        end

        local ghost = false
        if name == 'entity-ghost' then
            name = entity.ghost_name
            ghost = true
        end

        if not global.banned_entites[name] then
            return
        end

        -- Some entities have a bounding_box area of zero, eg robots.
        local area = entity.bounding_box
        local left_top, right_bottom = area.left_top, area.right_bottom
        if left_top.x == right_bottom.x and left_top.y == right_bottom.y then
            return
        end

        local p = Game.get_player_by_index(event.player_index)
        if not p or not p.valid then
            return
        end

        entity.destroy()
        if not ghost then
            p.insert(event.stack)
        end
    end
)
