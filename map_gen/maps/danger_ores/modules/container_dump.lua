local Event = require 'utils.event'
local Global = require 'utils.global'
local math = require 'utils.math'

local floor = math.floor
local max = math.max

local chest = defines.inventory.chest

local died_entities = {}

Global.register(
    died_entities,
    function(tbl)
        died_entities = tbl
    end
)

return function(config)
    local entity_name = config.entity_name
    Event.add(
        defines.events.on_entity_died,
        function(event)
            local entity = event.entity

            if not entity.valid then
                return
            end

            local type = entity.type
            if type ~= 'container' and type ~= 'logistic-container' then
                return
            end

            local inventory = entity.get_inventory(chest)
            if not inventory or not inventory.valid then
                return
            end

            local count = inventory.get_item_count()
            if count == 0 then
                return
            end

            local area = entity.bounding_box
            local left_top, right_bottom = area.left_top, area.right_bottom
            local x1, y1 = floor(left_top.x), floor(left_top.y)
            local x2, y2 = floor(right_bottom.x), floor(right_bottom.y)

            local size_x = x2 - x1 + 1
            local size_y = y2 - y1 + 1
            local amount = floor(count / (size_x * size_y))
            amount = max(amount, 1)

            local create_entity = entity.surface.create_entity

            for x = x1, x2 do
                for y = y1, y2 do
                    create_entity({name = entity_name, position = {x, y}, amount = amount})
                end
            end

            died_entities[entity.unit_number] = true
        end
    )

    Event.add(
        defines.events.on_post_entity_died,
        function(event)
            local unit_number = event.unit_number
            if not unit_number then
                return
            end

            if not died_entities[unit_number] then
                return
            end

            died_entities[unit_number] = nil

            local ghost = event.ghost
            if not ghost or not ghost.valid then
                return
            end

            ghost.destroy()
        end
    )
end
