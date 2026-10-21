-- Hands an item back to the logistic network of the construction robot that built something a
-- rule then removed. The robot itself takes nothing during on_robot_built_entity: it still holds
-- the item it built from (event.stack), which the game uses up after the event, so
-- robot.can_insert is false and robot.insert does nothing.
local Public = {}

--- Inserts `stack` into `robot`'s logistic network. What doesn't fit is spilled at `position`,
-- marked for deconstruction by `force` so the robots pick it up.
function Public.refund(robot, stack, surface, position, force)
    local network = robot.logistic_network
    local count = stack.count or 1
    local inserted = network and network.insert(stack) or 0
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
