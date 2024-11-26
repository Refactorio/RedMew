--Author: Valansch

local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'

local drill_radius_map = {}
local max_radius = 0
local require_fluid_ores = {}
local pumpjack_resources_map = {}
local drill_names = {}

local function setup(tbl)
    local map = tbl.drill_radius_map
    local max = 0
    local fluid_ores = tbl.require_fluid_ores
    local pumpjack_map = tbl.pumpjack_resources_map
    local names = tbl.drill_names

    for name, entity in pairs(prototypes.entity) do
        if entity.type == 'mining-drill' and entity.resource_categories['basic-solid'] then
            local radius = entity.mining_drill_radius

            map[name] = radius

            if radius > max then
                max = radius
            end
        elseif entity.type == 'resource' then
            local props = entity.mineable_properties

            if props.required_fluid then
                fluid_ores[name] = true
            end

            local products = props.products or {}
            for i = 1, #products do
                local product = products[i]
                if product.type == 'fluid' then
                    pumpjack_map[name] = true
                    break
                end
            end
        end
    end

    tbl.max_radius = max
    for k, _ in pairs(names) do
        names[k] = nil
    end
    for k, _ in pairs(map) do
        names[#names + 1] = k
    end
end

Global.register_init(
    {
        drill_radius_map = drill_radius_map,
        require_fluid_ores = require_fluid_ores,
        pumpjack_resources_map = pumpjack_resources_map,
        drill_names = drill_names
    },
    setup,
    function(tbl)
        drill_radius_map = tbl.drill_radius_map
        max_radius = tbl.max_radius
        require_fluid_ores = tbl.require_fluid_ores
        pumpjack_resources_map = tbl.pumpjack_resources_map
        drill_names = tbl.drill_names
    end
)

Event.on_configuration_changed(function()
    setup({
        drill_radius_map = drill_radius_map,
        require_fluid_ores = require_fluid_ores,
        pumpjack_resources_map = pumpjack_resources_map,
        drill_names = drill_names
    })
end)

local function is_depleted(drill, entity)
    local radius = drill_radius_map[drill.name]

    if radius == nil then
        return false
    end

    local pos = drill.position
    local x, y = pos.x, pos.y

    local area = {
        {x - radius, y - radius},
        {x + radius, y + radius}
    }

    local resources = drill.surface.find_entities_filtered {type = 'resource', area = area}
    for i = 1, #resources do
        local resource = resources[i]
        if resource ~= entity and not pumpjack_resources_map[resource.name] then
            return false
        end
    end
    return true
end

local callback =
    Token.register(
    function(drill)
        if drill.valid then
            drill.order_deconstruction(drill.force)
        end
    end
)

local function on_resource_depleted(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if require_fluid_ores[entity.name] then
        return
    end

    local pos = entity.position
    local x, y = pos.x, pos.y
    local radius = max_radius

    local area = {
        {x - radius, y - radius},
        {x + radius, y + radius}
    }

    local drills = event.entity.surface.find_entities_filtered {area = area, name = drill_names}
    for i = 1, #drills do
        local drill = drills[i]
        if is_depleted(drill, entity) then
            Task.set_timeout_in_ticks(5, callback, drill)
        end
    end
end

Event.add(defines.events.on_resource_depleted, on_resource_depleted)
