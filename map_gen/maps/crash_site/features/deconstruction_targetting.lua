local Event = require 'utils.event'
local Commands = require 'map_gen.maps.crash_site.commands'

Event.add(defines.events. on_player_deconstructed_area , function(event)

    local player = game.get_player(event.player_index)
    if not player or not player.valid or not player.cursor_stack or not player.cursor_stack.valid then
        return
    end

    -- check they actually have a decon planner in their cursor
    local item_name = player.cursor_stack.name
    if item_name ~= "deconstruction-planner" then
        return
    end

    -- check if the player has given the decon planner an icon. This is how  we will determine  their intention
    if not player.cursor_stack.blueprint_icons or not player.cursor_stack.blueprint_icons[1].signal.name then
        return
    end

    local icon_name = player.cursor_stack.blueprint_icons[1].signal.name
    local left_top = event.area.left_top
    local right_bottom = event.area.right_bottom

    local cancel_area = {{left_top.x-1,left_top.y-1 },{right_bottom.x+1,right_bottom.y+1 }} -- make the cancel area bigger so it's min size of 1x1
    player.surface.cancel_deconstruct_area{area=cancel_area, force=player.force} -- to stop them accidentally marking trees, tiles enemy chests for deconstruction

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
