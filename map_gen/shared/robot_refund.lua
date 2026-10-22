-- Hands an item back through the construction robot that built something a rule then removed.
-- robot.insert does nothing for a construction robot (it returns 0, even with its cargo empty),
-- but its cargo inventory takes the item, during on_robot_built_entity too, and the robot then
-- carries it to storage like anything else it picks up.
local Public = {}

--- Puts `stack` in `robot`'s cargo. What doesn't fit is spilled at `position`, marked for
-- deconstruction by `force` so the robots pick it up.
function Public.refund(robot, stack, surface, position, force)
    local cargo = robot.get_inventory(defines.inventory.robot_cargo)
    local count = stack.count or 1
    local inserted = cargo and cargo.insert(stack) or 0
    if inserted < count then
        surface.spill_item_stack {
            position = position,
            stack = {name = stack.name, count = count - inserted, quality = stack.quality},
            enable_looted = true,
            force = force
        }
    end
end

return Public
