-- This module allows to auto target strikes or barrages with a deconstruction planner in hand.
-- The deconstruction planner has to be set to deconstruct only "Big Rock", set to deconstruct tiles Never,
-- and must have either exp. rockets or poison capsules as the 1st and only icon in preview.
-- Already configured decon planners are available for free at the spawn market.
local Event = require 'utils.event'
local Commands = require 'map_gen.maps.crash_site.commands'

Event.add(defines.events.on_player_deconstructed_area, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    -- Only continue if they do a small click
    local left_top = event.area.left_top
    local right_bottom = event.area.right_bottom
    if (math.abs(left_top.x -  right_bottom.x) >= 1) or (math.abs(left_top.y -  right_bottom.y) >= 1)  then
        return
    end

    -- Get the deconstruction planner being used, from either the stack or record
    local stack = event.stack
    local record = event.record
    local planner = nil
    if stack and stack.valid and stack.valid_for_read and stack.name == "deconstruction-planner" then
        planner = stack
    elseif record and record.valid and record.type == "deconstruction-planner" then
        planner = record
    end

    if not planner then
        return
    end

    -- From here, planner contains either LuaItemStack or LuaRecord
    -- Only use functions or variables that are shared between the two.

    -- Determine if this is a special targeting planner.
    if planner.tile_selection_mode ~= defines.deconstruction_item.tile_selection_mode.never
       or not planner.entity_filters
       or #(planner.entity_filters) ~= 1
       or planner.entity_filters[1].name ~= 'big-rock'
       or not planner.preview_icons
       or #(planner.preview_icons) ~= 1
       or not planner.preview_icons[1].signal.name
       or (planner.preview_icons[1].signal.name ~= "poison-capsule" and planner.preview_icons[1].signal.name ~= "explosive-rocket") then
        return
    end

    -- Construct a call to strike or barrage
    local icon_name = planner.preview_icons[1].signal.name
    local args = {}
    args.location = "[gps="..math.floor(left_top.x)..","..math.floor(left_top.y)..","..player.surface.name.."]"
    if icon_name == "poison-capsule" then
        Commands.call_strike(args, player)
    elseif icon_name == "explosive-rocket" then
        Commands.call_barrage(args, player)
    end
end)
