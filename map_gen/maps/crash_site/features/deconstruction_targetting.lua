local Event = require 'utils.event'
local Commands = require 'map_gen.maps.crash_site.commands'

local function is_targetting_deconstruction_planner(cursor_stack)
    if not cursor_stack or not cursor_stack.valid or not cursor_stack.valid_for_read then
        return false
    end

    if cursor_stack.name ~= "deconstruction-planner" then
        return false
    end

    if cursor_stack.tile_selection_mode ~= defines.deconstruction_item.tile_selection_mode.never then
        return false
    end

    local filters = cursor_stack.entity_filters
    if #filters ~= 1 or filters[1] ~= 'sand-rock-big' then
        return false
    end

    return true
end

Event.add(defines.events. on_player_deconstructed_area , function(event)
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    if not player or not player.valid then
        return
    end

    -- check they actually have a decon planner in their cursor that is setup to be a targetting deconstruction planner.
    if not is_targetting_deconstruction_planner(cursor_stack) then
        return
    end

    -- check if the player has given the decon planner an icon. This is how  we will determine  their intention
    if not cursor_stack.preview_icons or not cursor_stack.preview_icons[1] or not cursor_stack.preview_icons[1].signal.name then
        return
    end

    local icon_name = player.cursor_stack.preview_icons[1].signal.name
    local left_top = event.area.left_top
    local right_bottom = event.area.right_bottom

    -- only continue if they do a small click. We don't want them selecting a huge area
    if (math.abs(left_top.x -  right_bottom.x) < 1) and (math.abs(left_top.y -  right_bottom.y) < 1)  then
        local args = {}
        args.location = "[gps="..math.floor(left_top.x)..","..math.floor(left_top.y)..","..player.surface.name.."]"
        if icon_name == "poison-capsule" then
            Commands.call_strike(args,player)
        elseif icon_name == "explosive-rocket" then
            Commands.call_barrage(args,player)
        end
    end
end)
