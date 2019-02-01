--- Bans the placement of entities and ghosts
-- This module should be used when it's not suitable to disable a technology or recipe.
-- eg. disabling entities required for research
-- code adapted from danger_ore_banned_entities
-- @module banned_entities
--

local Global = require 'utils.global'
local Event = require 'utils.event'
local Game = require 'utils.game'

local banned_entities = {
    ['inserter'] = true,
    ['long-handed-inserter'] = true,
    ['fast-inserter'] = true,
    ['filter-inserter'] = true,
    ['stack-inserter'] = true,
    ['stack-filter-inserter'] = true,
    ['electric-mining-drill'] = true,
}

Global.register({
    banned_entities = banned_entities
}, function(tbl)
    banned_entities = tbl.banned_entities
end)

Event.add(
    defines.events.on_built_entity,
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

        --local count = entity.surface.count_entities_filtered {area = area, type = 'resource', limit = 1}

        --if count == 0 then
        --    return
        --end

        local p = Game.get_player_by_index(event.player_index)
        if not p or not p.valid then
            return
        end

        entity.destroy()
        if not ghost then
            p.insert(event.stack)
            require 'features.gui.popup'.player(
                    p,[[
You don't know how to operate this item!

Advice: Only burner inserters and burner mining drills works in prehistoric land
]])
        end



    end
)
