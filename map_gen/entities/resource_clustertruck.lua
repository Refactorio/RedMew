--Author: MewMew. Liberally reinterpreted by grilledham

local Event = require "utils.event"

local function init()
    global.resource_cluster_truck = 0
end

Event.on_init(init)

local radius = 10
local radius_sq = radius * radius

return function(_, _, world)
    local entities = world.surface.find_entities_filtered {position = {world.x + 0.5, world.y + 0.5}, type = "resource"}
    for _, e in ipairs(entities) do
        e.destroy()
    end

    if not world.chunk then
        world.chunk = true

        global.resource_cluster_truck = global.resource_cluster_truck + 1

        world.ore_spawn = math.random(1, 6)

        if math.random(1, 12) == 1 then
            world.resource_amount = math.random(7000, 150000)
        else
            world.resource_amount = math.random(400, 7000)
        end

        world.oil_amount = math.random(10000, 150000)
    end

    if global.resource_cluster_truck % 2 == 0 then
        return nil
    end

    local x = world.x - world.top_x - 16
    local y = world.y - world.top_y - 16
    local d_sq = x * x + y * y

    if d_sq < radius_sq then
        local ore_spawn = world.ore_spawn
        local resource_amount = world.resource_amount

        local amount
        if ore_spawn == 6 then
            amount = world.oil_amount
        else
            amount = resource_amount
            if d_sq < radius_sq / 4 then
                amount = resource_amount * 1.5
            elseif d_sq < radius_sq / 9 then
                amount = resource_amount * 2
            end
        end

        if ore_spawn == 1 then
            return {name = "stone", amount = amount}
        end
        if ore_spawn == 2 then
            return {name = "iron-ore", amount = amount}
        end
        if ore_spawn == 3 then
            return {name = "coal", amount = amount}
        end
        if ore_spawn == 4 then
            return {name = "copper-ore", amount = amount}
        end
        if ore_spawn == 5 then
            return {name = "uranium-ore", amount = amount}
        end
        if ore_spawn == 6 then
            return {name = "crude-oil", amount = amount}
        end
    end
end
