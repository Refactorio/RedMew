-- Module deprecated in 2.0, became a built-in feature
-- Functions to allow players to select a group of spidertrons with a deconstruction planner and then assign them to follow another spidertron
local Event = require 'utils.event'
local Global = require 'utils.global'

local spider_army = {}

Global.register(
    {spider_army = spider_army},
    function(tbl)
        spider_army = tbl.spider_army
    end
)

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
    if #filters ~= 1 or filters[1] ~= 'big-rock' then
        return false
    end

    -- check if the player has given the deconstruction planner an icon. This is how  we will determine  their intention
    if not cursor_stack.preview_icons or not cursor_stack.preview_icons[1] or not cursor_stack.preview_icons[1].signal.name then
        return false
    end

    local icon_name = cursor_stack.preview_icons[1].signal.name
    if icon_name ~= "spidertron" then
        return false
    end

    return true
end

Event.add(defines.events.on_player_deconstructed_area , function(event)
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    if not player or not player.valid then
        return
    end

    -- check they actually have a decon planner in their cursor that is setup to be a targetting deconstruction planner.
    if not is_targetting_deconstruction_planner(cursor_stack) then
        return
    end

    local left_top = event.area.left_top
    local right_bottom = event.area.right_bottom
    local width = math.abs(left_top.x -  right_bottom.x)
    local height = math.abs(left_top.y -  right_bottom.y)

    -- A single (small area) click is interpretted as instruction to assign a group of spiders to follow a spider
    if width <= 1 and height <= 1  then
        local spidertrons = spider_army[player.name]
        if not spidertrons then
            player.create_local_flying_text {
                text = {'spidertron_group_control.none_selected'},
                position = left_top,
            }
            return
        end
        local target_spider = player.surface.find_entities_filtered{name="spidertron", area={{left_top.x-1,left_top.y-1}, {right_bottom.x+1,right_bottom.y+1}}, limit=1}
        if #target_spider == 1 then
            for i, spidertron in pairs(spidertrons) do
                if spidertron and spidertron.valid then
                    spidertron.follow_target = target_spider[1]
                end
            end
            spider_army[player.name] = {} -- clear spidertrons from table once they've been assigned to follow another spidey lad
            cursor_stack.label = "No [img=item.spidertron] selected. Drag the planner over [img=item.spidertron] you own."
        else
            player.create_local_flying_text {
                text = {'spidertron_group_control.none_found'},
                position = left_top,
            }
        end
    else -- else the area is bigger than 1x1 and so we assume the player is selecting which spiders to assign
        local spidertrons = player.surface.find_entities_filtered{area = {left_top, right_bottom}, name="spidertron"}
        local spidertrons_valid = {}
        if #spidertrons > 0 then
            for i, spidertron in pairs(spidertrons) do
                if spidertron.last_user.name == player.name then
                    spidertrons_valid[#spidertrons_valid + 1] = spidertron
                    -- Draw a circle over the spidertron's body to show it's part of the selection.
                    rendering.draw_circle {
                        color = {r = 0.5, g = 0, b = 0, a = 1},
                        radius = 0.5,
                        width = 3,
                        filled = false,
                        target = {spidertron.position.x,spidertron.position.y-2},
                        surface = spidertron.surface,
                        time_to_live = 60*4,
                        players = {player.name}
                    }
                end
            end

            spider_army[player.name] = spidertrons_valid
            cursor_stack.label = #spidertrons_valid..' selected. Click a spidertron for them to follow.'
        else
            cursor_stack.label = "Select a group of spidertrons that belong to you! 0 selected."
        end
        -- Flying text to appear at top left of selection area showing player how many spidertrons they selected
        player.create_local_flying_text {
            text = {'spidertron_group_control.spidertrons_selected', #spidertrons_valid},
            position = left_top,
        }
    end
end)

Event.add(defines.events.on_pre_player_removed, function(event)
    local player = game.get_player(event.player_index)
    if player then
        spider_army[player.name] = nil
    end
end)
