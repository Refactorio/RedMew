    -- Copyright (c) 2016-2017 SL

    -- This file is part of SL-extended.

    -- SL-extended is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU Affero General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.

    -- SL-extended is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU Affero General Public License for more details.

    -- You should have received a copy of the GNU Affero General Public License
    -- along with SL-extended.  If not, see <http://www.gnu.org/licenses/>.


-- sl_autodeconstruct.lua
-- 20170118
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  mindmix

require "util"

local function find_resources(surface, position, range, resource_category)
    local resource_category = resource_category or 'basic-solid'
    local top_left = {x = position.x - range, y = position.y - range}
    local bottom_right = {x = position.x + range, y = position.y + range}

    local resources = surface.find_entities_filtered{area={top_left, bottom_right}, type='resource'}
    categorized = {}
    for _, resource in pairs(resources) do
        if resource.prototype.resource_category == resource_category then
            table.insert(categorized, resource)
        end
    end
    return categorized
end

local function find_all_entities(entity_type)
    local surface = game.surfaces['nauvis']
    local entities = {}
    for chunk in surface.get_chunks() do
        local chunk_area = {lefttop = {x = chunk.x*32, y = chunk.y*32}, rightbottom = {x = chunk.x*32+32, y = chunk.y*32+32}}
        local chunk_entities = surface.find_entities_filtered({area = chunk_area, type = entity_type})
        for i = 1, #chunk_entities do
            entities[#entities + 1] = chunk_entities[i]
        end
    end
    return entities
end

local function find_target(entity)
    if entity.drop_target then
        return entity.drop_target
    else
        local entities = entity.surface.find_entities_filtered{position=entity.drop_position}
        return entities[1]
    end
end

local function find_targeting(entity)
    local range = global.max_radius
    local position = entity.position

    local top_left = {x = position.x - range, y = position.y - range}
    local bottom_right = {x = position.x + range, y = position.y + range}

    local surface = entity.surface
    local entities = {}
    local targeting = {}

    local entities = surface.find_entities_filtered{area={top_left, bottom_right}, type='mining-drill'}
    for i = 1, #entities do
        if find_target(entities[i]) == entity then 
            targeting[#targeting + 1] = entities[i]
        end
    end

    entities = surface.find_entities_filtered{area={top_left, bottom_right}, type='inserter'}
    for i = 1, #entities do
        if find_target(entities[i]) == entity then 
            targeting[#targeting + 1] = entities[i]
        end
    end
    return targeting
end

local function find_drills(entity)
    local position = entity.position
    local surface = entity.surface

    local top_left = {x = position.x - global.max_radius, y = position.y - global.max_radius}
    local bottom_right = {x = position.x + global.max_radius, y = position.y + global.max_radius}

    local entities = {}
    local targeting = {}

    local entities = surface.find_entities_filtered{area={top_left, bottom_right}, type='mining-drill'}
    for i = 1, #entities do
        if math.abs(entities[i].position.x - position.x) < entities[i].prototype.mining_drill_radius and math.abs(entities[i].position.y - position.y) < entities[i].prototype.mining_drill_radius then
            autodeconstruct_check_drill(entities[i])
        end
    end
end

function autodeconstruct_init()
	if not global.max_radius then
	    global.max_radius = 0.99
	    drill_entities = find_all_entities('mining-drill')
	    for _, drill_entity in pairs(drill_entities) do
	        autodeconstruct_check_drill(drill_entity)
	    end
	end
end

function autodeconstruct_on_resource_depleted(event)
    if event.entity.prototype.resource_category ~= 'basic-solid' or event.entity.prototype.infinite_resource ~= false then
        return
    end
    drill = find_drills(event.entity)
end

function autodeconstruct_check_drill(drill)
    if drill.mining_target and drill.mining_target.valid then
        if drill.mining_target.amount > 0 then return end -- this should also filter out pumpjacks and infinite resources
    end
    
    local mining_drill_radius = drill.prototype.mining_drill_radius
    if mining_drill_radius > global.max_radius then
        global.max_radius = mining_drill_radius
    end

    if not mining_drill_radius then return end 
    
    resources = find_resources(drill.surface, drill.position, mining_drill_radius)
    for i = 1, #resources do
        if resources[i].amount > 0 then return end
    end
    autodeconstruct_order_deconstruction(drill)
end

function autodeconstruct_on_canceled_deconstruction(event)
    if event.player_index or event.entity.type ~= 'mining-drill' then return end
    autodeconstruct_check_drill(event.entity)
end

function autodeconstruct_on_built_entity(event)
    if event.created_entity.type ~= 'mining-drill' then return end
    if event.created_entity.prototype.mining_drill_radius > global.max_radius then
        global.max_radius = event.created_entity.prototype.mining_drill_radius
    end
end
    
function autodeconstruct_order_deconstruction(drill)
    if drill.to_be_deconstructed(drill.force) then
        return
    end
    
    local deconstruct = false
--[[ #TODO
config.lua: autodeconstruct_wait_for_robots = false
    if autodeconstruct_wait_for_robots then
        logistic_network = drill.surface.find_logistic_network_by_position(drill.position, drill.force.name)
        if logistic_network ~= niremovel then
            if logistic_network.available_construction_robots > 0 then
                deconstruct = true
            end
        end
    else
        deconstruct = true
    end
--]]
    deconstruct = true
--[[ END TODO

--]]
    if deconstruct == true and drill.minable then
        if drill.order_deconstruction(drill.force.name) then
        else
            -- msg_all({"autodeconstruct-err-specific", "drill.order_deconstruction", util.positiontostr(drill.position) .. "failed to order deconstruction on " .. drill.name })
        end
        target = find_target(drill)
        if target and target.minable then
            if target.type == "logistic-container" or target.type == "container" then
                targeting = find_targeting(target)
                if targeting then
                    for i = 1, #targeting do
                        if not targeting[i].to_be_deconstructed(targeting[i].force) then return end
                    end
                    -- we are the only one targeting
                    if target.to_be_deconstructed(target.force) then
                        target.cancel_deconstruction(target.force)
                    end
                    if target.order_deconstruction(target.force) then
                    else
                        -- msg_all({"autodeconstruct-err-specific", "target.order_deconstruction", util.positiontostr(target.position) .. "failed to order deconstruction on " .. target.name})
                    end
                end
            end
        end
    end
end
