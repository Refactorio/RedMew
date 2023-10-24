-- dependencies
local Event = require 'utils.event'
local random = math.random
local ceil = math.ceil
local RS = require 'map_gen.shared.redmew_surface'
--local LS = game.surface[1]
local pairs = pairs
--local surface = RS.get_surface()
local Grow = {}
local this = {}

local Global = require 'utils.global'
Global.register(this, function (tbl)
	this = tbl
end)

local TreeKillTypes = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}
--[[
local DontTiles = {
	['out-of-map'] = true,
	['concrete'] = true,
	['hazard-concrete-left'] = true,
	['hazard-concrete-right'] = true,
	['refined-hazard-concrete-right'] = true,
	['refined-hazard-concrete-left'] = true,
	['refined-concrete'] = true,
	['stone-path'] = true,
	['water'] = true,
	['water-green'] = true,
	['water-mud'] = true,
	['water-shallow'] = true,
	['deepwater-green'] = true,
	['deepwater'] = true,
}
--]]

--- Event handler for on_built_entity
-- checks if player placed a solar-panel and displays a popup
-- @param event table containing the on_built_entity event specific attributes
--
local function on_tick(event)
	local this = this
    this.ticks = this.ticks + 1
    if (this.ticks < this.period) then
        return
    end
    this.ticks = 0

    local surface = RS.get_surface()
	local trees = this.trees
    if (this.tree_count < 1) then
		if surface.count_entities_filtered{type = "tree", limit = 1} == 0 then
			this.tree_count = 0
			this.period = 30 * 60 --wait 30 seconds if there weren't any trees
			return
		end

        trees = surface.find_entities_filtered{type = "tree"}
        this.trees = trees
		this.tree_count = #trees
		--ten minutes = 36000 ticks, 8.33mins = 30000
		this.period = ceil(30000/this.tree_count)
    end

    local tree
	local tries = 1
	while (tries < 10) do
		local i = random(1, this.tree_count)
		tree = trees[i]

		trees[i] = trees[this.tree_count]
		trees[this.tree_count] = nil
		this.tree_count = this.tree_count - 1

		if tree.valid then
			break
		end
		if this.tree_count < 1 then
			return
		end
		tries = tries + 1
	end

	if not tree.valid then return end

	local position = tree.position
	local X = position.x
	local Y = position.y
	if (surface.count_entities_filtered{type = "tree", position = position} == 1) then
		local get_tile = surface.get_tile
		local positions_around = {
			{X + 1, Y},
			{X - 1, Y},
			{X, Y + 1},
			{X, Y - 1},
			{X + 1, Y + 1},
			{X - 1, Y - 1},
			{X - 1, Y + 1},
			{X + 1, Y - 1},
		}
		for _, position in pairs(positions_around) do
			local tile = get_tile(position)
			--if (not DontTiles[tile.name]) then
			if not (tile.hidden_tile or tile.collides_with("water-tile")) then
				if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = position} == 0) then
					for i, entityd in pairs(surface.find_entities_filtered{position = position, type = TreeKillTypes}) do
						if entityd.valid then
							entityd.die()
						else
							--game.print("entity invalid")
						end
					end
					surface.create_entity{name = "tree-0" .. random(1, 3), position = position}
				end
			end
		end
    --if (entity.name == 'solar-panel') then
      --  require 'features.gui.popup'.player(
        --    player, {'diggy.night_time_warning'}
        --)
    end
end

--- Event handler for on_research_finished
-- sets the force, which the research belongs to, recipe for solar-panel-equipment
-- to false, to prevent wastefully crafting. The technology is needed for further progression
-- @param event table containing the on_research_finished event specific attributes
--
local function on_player_joined_game(event)
    --surface = RS.get_surface()

end

--- Setup of on_built_entity and on_research_finished events
-- assigns the two events to the corresponding local event handlers
-- @param config table containing the configurations for Grow.lua
--
function Grow.register()
    Event.add(defines.events.on_tick, on_tick)
    Event.add(defines.events.on_player_joined_game, on_player_joined_game)
end

--- Sets the daytime to 0.5 and freezes the day/night circle.
-- a daytime of 0.5 is the value where every light and ambient lights are turned on.
--
function Grow.on_init()
    this.trees = {}
	this.tree_count = 0
	this.period = 2*60*60 -- start trying after 2 minutes
	this.ticks = 0
    --surface = RS.get_surface()
end

return Grow
