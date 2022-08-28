-- dependencies
local Event = require 'utils.event'
local random = math.random
local RS = require 'map_gen.shared.redmew_surface'
--local LS = game.surface[1]
local pairs = pairs
global.gtcount = {1}
global.gtran = {50}
global.gtbase = 1
global.gtcccount = 5000
global.gttrees = {}
--local surface = RS.get_surface()
-- this
local Grow = {}

--- Event handler for on_built_entity
-- checks if player placed a solar-panel and displays a popup
-- @param event table containing the on_built_entity event specific attributes
--
local function on_tick(event)
    global.gtcount = global.gtcount+1
    if (global.gtcount < 30000/global.gtran) then --50000/global.gtran
        return
    end
    --RS.get_surface().print(global.gtcount .. "/" .. global.gtran)
    global.gtcount = 1
    local surface = RS.get_surface()
    if (global.gtcccount > global.gtbase) then
        global.gtcccount = 1
        global.gttrees = surface.find_entities_filtered{type = "tree"}
        global.gtbase = surface.count_entities_filtered{type = "tree"}-1
    end
    global.gtcccount = global.gtcccount + 1
    --local allent = surface.find_entities_filtered{type = "tree"}
    global.gtran = random(1,global.gtbase)
    --local entity = global.gttrees[global.gtran]
    --for i, entity in pairs(surface.find_entities_filtered{type = "tree"}) do
        local eposition = (global.gttrees[global.gtran]).position
        local x = eposition.x
        local y = eposition.y
        --local all = surface.count_entities_filtered{position = entity.position, radius = 2, type = "tree"}
        --require 'features.gui.popup'.player(
          --          player, {'True'}
            --    )
        --game.player.print('found: ' .. all)
        if (surface.count_entities_filtered{type = "tree", position = {x,y}} == 1) then
            local get_tile = surface.get_tile
            local t = get_tile(x, y + 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x,y+1}} == 0) then

                    for i, entityd in pairs(surface.find_entities_filtered{position = {x,y+1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    --stone-wall market
                    --concrete hazard-concrete-left hazard-concrete-right refined-hazard-concrete-right refined-hazard-concrete-left refined-concrete stone-path water water-green water-mud water-shallow deepwater-green deepwater
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x,y+1}, force = game.forces.player}
                end
            end
            t = get_tile(x+1, y + 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x+1,y+1}}== 0) then

                    for i, entityd in pairs(surface.find_entities_filtered{position = {x+1,y+1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x+1,y+1}, force = game.forces.player}
                end
            end
            t = get_tile(x-1, y - 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x-1,y-1}}== 0) then

                    for i, entityd in pairs(surface.find_entities_filtered{position = {x-1,y-1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x-1,y-1}, force = game.forces.player}
                end
            end
            t = get_tile(x, y - 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x,y-1}}== 0) then
                   
                    for i, entityd in pairs(surface.find_entities_filtered{position = {x,y-1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x,y-1}, force = game.forces.player}
                end
            end
            t = get_tile(x+1, y ).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x+1,y}}== 0) then

                    for i, entityd in pairs(surface.find_entities_filtered{position = {x+1,y}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x+1,y}, force = game.forces.player}
                end
            end
            t = get_tile(x-1, y).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x-1,y}}== 0) then
                    for i, entityd in pairs(surface.find_entities_filtered{position = {x-1,y}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x-1,y}, force = game.forces.player}
                end
            end
            t = get_tile(x-1, y + 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x-1,y+1}}== 0) then
                    for i, entityd in pairs(surface.find_entities_filtered{position = {x-1,y+1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x-1,y+1}, force = game.forces.player}
                end
            end
            t = get_tile(x+1, y - 1).name
            if (t ~= 'out-of-map' and t ~= 'concrete' and t ~= 'hazard-concrete-left' and t ~= 'hazard-concrete-right' and t ~= 'refined-hazard-concrete-right' and t ~= 'refined-hazard-concrete-left' and t ~= 'refined-concrete' and t ~= 'stone-path' and t ~= 'water' and t ~= 'water-green' and t ~= 'water-mud' and t ~= 'water-shallow' and t ~= 'deepwater-green' and t ~= 'deepwater') then
                if (surface.count_entities_filtered{type = {"tree","wall","market"}, position = {x+1,y-1}}== 0) then
                    for i, entityd in pairs(surface.find_entities_filtered{position = {x+1,y-1}, type = {"items","accumulator","ammo-category","ammo-turret","arithmetic-combinator","artillery-turret","artillery-wagon","assembling-machine","beacon","boiler","car","cargo-wagon","constant-combinator","container","curved-rail","decider-combinator","electric-pole","electric-turret","fluid-turret","fluid-wagon","furnace","gate","generator","generator-equipment","heat-pipe","infinity-container","infinity-pipe","inserter","lab","lamp","land-mine","loader","locomotive","logistic-container","mining-drill","offshore-pump","pipe","pipe-to-ground","programmable-speaker","pump","radar","rail-chain-signal","rail-remnants","rail-signal","roboport","solar-panel","splitter","straight-rail","train-stop","transport-belt","underground-belt"}}) do
                        entityd.die()
                    end
                    surface.create_entity{name = "tree-0" .. random(1, 3), position = {x+1,y-1}, force = game.forces.player}
                end
            end

        --end
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
    global.gtcount = 1
    global.gtran = 50
    global.gtbase = 1
    global.gtcccount = 5000
    global.gttrees = {}
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
    global.gtcount = 1
    global.gtran = 50
    global.gtbase = 1
    global.gtcccount = 5000
    global.gttrees = {}
    --surface = RS.get_surface()
end

return Grow
