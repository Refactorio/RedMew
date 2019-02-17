local Event = require 'utils.event'
local Game = require 'utils.game'
local abs = math.abs

local allowed_entities = {
    ['transport-belt'] = true,
    ['fast-transport-belt'] = true,
    ['express-transport-belt'] = true,
    ['underground-belt'] = true,
    ['fast-underground-belt'] = true,
    ['express-underground-belt'] = true,
    ['splitter'] = true,
    ['fast-splitter'] = true,
    ['express-splitter'] = true,
}

local function on_built_entity(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

    local s_box = entity.selection_box

    local size_x = abs(s_box.left_top.x - s_box.right_bottom.x)
    local size_y = abs(s_box.left_top.y - s_box.right_bottom.y)
    local pos = {x = abs(entity.position.x) - (size_x/2), y = abs(entity.position.y) - (size_y/2)}

    if not(pos.x <= 23 or pos.y <= 23) then
        return
    end

    local name = entity.name

    local ghost = false
    if name == 'entity-ghost' then
        name = entity.ghost_name
        ghost = true
    end


    if name == 'tile-ghost' then
        return
    end


    if allowed_entities[name] and not (pos.x < 2 or pos.y < 2) then
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

Event.add(defines.events.on_built_entity, on_built_entity)