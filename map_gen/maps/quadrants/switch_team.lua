local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'
local abs = math.abs
local Color = require 'resources.color_presets'
local Popup = require 'features.gui.popup'
local RS = require 'map_gen.shared.redmew_surface'
local Item_to_chest = require 'map_gen.maps.quadrants.item_to_chest'
local Global = require 'utils.global'

local gui = {}

local spawn_locations = {
    quadrant_1 = {64, -64},
    quadrant_2 = {-64, -64},
    quadrant_3 = {-64, 64},
    quadrant_4 = {64, 64}
}

local toggle_chest_status = {}

Global.register(
    {
        toggle_chest_status = toggle_chest_status
    },
    function(tbl)
        toggle_chest_status = tbl.toggle_chest_status
    end
)

local quadrant_message = {
    {
        title = {'quadrants.popup_quadrant1_title'},
        msg = {'quadrants.popup_quadrant1'}
    },
    {
        title = {'quadrants.popup_quadrant2_title'},
        msg = {'quadrants.popup_quadrant2'}
    },
    {
        title = {'quadrants.popup_quadrant3_title'},
        msg = {'quadrants.popup_quadrant3'}
    },
    {
        title = {'quadrants.popup_quadrant4_title'},
        msg = {'quadrants.popup_quadrant4'}
    }
}

local function teleport(event, quadrant)
    local player = event.player
    local toggle_status = toggle_chest_status[player.index]
    if
        (abs(player.position.x) <= 4 and abs(player.position.y) <= 4) or
            (player.get_inventory(defines.inventory.player_main).is_empty() and
                player.get_inventory(defines.inventory.player_trash).is_empty()) or
            ((abs(player.position.x) >= 23 and (abs(player.position.y) >= 23)) and toggle_status and
                Item_to_chest.transfer_inventory(
                    player.index,
                    {defines.inventory.player_main, defines.inventory.player_trash}
                ))
     then
        local pos =
            RS.get_surface().find_non_colliding_position('player', spawn_locations['quadrant_' .. quadrant], 5, 1)
        player.teleport(pos)
        player.force = game.forces['quadrant' .. quadrant]
        Popup.player(
            player,
            quadrant_message[quadrant].msg,
            quadrant_message[quadrant].title,
            nil,
            'Quadrants.quadrant_description'
        )
    else
        player.print({'quadrants.switch_notice1'}, Color.red)
        player.print({'quadrants.switch_notice1'}, Color.red)
    end
end

local function redraw_quadrant_button(data)
    local left_flow = data.left_flow_btn1
    local right_flow = data.right_flow_btn1
    Gui.clear(left_flow)
    Gui.clear(right_flow)

    left_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.2',
            caption = {'quadrants.switch_quadrant2', #game.forces['quadrant2'].connected_players},
            tooltip = {'quadrants.switch_quadrant2_tip'}
        }
    )
    right_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.1',
            caption = {'quadrants.switch_quadrant1', #game.forces['quadrant1'].connected_players},
            tooltip = {'quadrants.switch_quadrant1_tip'}
        }
    )

    left_flow = data.left_flow_btn2
    right_flow = data.right_flow_btn2
    Gui.clear(left_flow)
    Gui.clear(right_flow)

    left_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.3',
            caption = {'quadrants.switch_quadrant3', #game.forces['quadrant3'].connected_players},
            tooltip = {'quadrants.switch_quadrant3_tip'}
        }
    )
    right_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.4',
            caption = {'quadrants.switch_quadrant4', #game.forces['quadrant4'].connected_players},
            tooltip = {'quadrants.switch_quadrant4_tip'}
        }
    )
end

local function redraw_chest_button(data, player)
    local left_flow = data.chest_button_left_flow
    local toggle_status = toggle_chest_status[player.index] and {'quadrants.on'} or {'quadrants.off'}
    Gui.clear(left_flow)

    local button =
        left_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.Toggle',
            caption = {'quadrants.switch_chest', toggle_status},
            tooltip = {'quadrants.switch_chest_tip'}
        }
    )
    button.style.font = 'default'
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left['Quadrants.Switch_Team']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        local data = Gui.get_data(frame)
        redraw_quadrant_button(data, player)
        redraw_chest_button(data, player)
        return
    end

    frame = left.add({name = 'Quadrants.Switch_Team', type = 'frame', direction = 'vertical'})

    local content_flow = frame.add {type = 'flow', direction = 'vertical'}
    local label_flow = content_flow.add {type = 'flow'}

    label_flow.style.horizontally_stretchable = false
    local label = label_flow.add {type = 'label', caption = {'quadrants.switch_welcome'}}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    label_flow = content_flow.add {type = 'flow'}
    label = label_flow.add {type = 'label', caption = {'quadrants.switch_desc'}}
    label.style.single_line = false
    label.style.font = 'default'

    label_flow = content_flow.add {type = 'flow'}
    label = label_flow.add {type = 'label', caption = {'quadrants.switch_msg'}}
    label.style.single_line = false
    label.style.font = 'default'

    content_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow_btn1 = content_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow_btn1.style.horizontal_align = 'left'
    left_flow_btn1.style.horizontally_stretchable = false

    local right_flow_btn1 = content_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow_btn1.style.horizontal_align = 'right'
    right_flow_btn1.style.horizontally_stretchable = false

    content_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow_btn2 = content_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow_btn2.style.horizontal_align = 'left'
    left_flow_btn2.style.horizontally_stretchable = false

    local right_flow_btn2 = content_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow_btn2.style.horizontal_align = 'right'
    right_flow_btn2.style.horizontally_stretchable = false

    content_flow = frame.add {type = 'flow', direction = 'horizontal'}
    local chest_button_left_flow = content_flow.add {type = 'flow', direction = 'horizontal'}
    chest_button_left_flow.style.horizontal_align = 'left'
    chest_button_left_flow.style.horizontally_stretchable = false
    chest_button_left_flow.style.top_padding = 12

    local data = {
        frame = frame,
        left_flow_btn1 = left_flow_btn1,
        right_flow_btn1 = right_flow_btn1,
        left_flow_btn2 = left_flow_btn2,
        right_flow_btn2 = right_flow_btn2,
        chest_button_left_flow = chest_button_left_flow
    }

    redraw_quadrant_button(data)
    redraw_chest_button(data, player)

    Gui.set_data(frame, data)
end

local function update_gui(force_update)
    local players = game.connected_players
    for i = #players, 1, -1 do
        local p = players[i]
        local frame = p.gui.left['Quadrants.Switch_Team']
        local data = {player = p}

        if frame and frame.valid and (abs(p.position.x) >= 160 or abs(p.position.y) >= 160) then
            toggle(data)
        elseif not frame and not (abs(p.position.x) > 160 or abs(p.position.y) > 160) then
            toggle(data)
        elseif frame and frame.valid and force_update then
        data['trigger'] = true
            toggle(data)
        end
    end
end

local function toggle_chest(event)
    local toggle_status = toggle_chest_status[event.player.index]
    if not toggle_status then
        toggle_chest_status[event.player.index] = true
    else
        toggle_chest_status[event.player.index] = false
    end
    event.trigger = true
    toggle(event)
end

Gui.on_click(
    'Quadrants.Button.1',
    function(event)
        teleport(event, 1)
    end
)
Gui.on_click(
    'Quadrants.Button.2',
    function(event)
        teleport(event, 2)
    end
)
Gui.on_click(
    'Quadrants.Button.3',
    function(event)
        teleport(event, 3)
    end
)
Gui.on_click(
    'Quadrants.Button.4',
    function(event)
        teleport(event, 4)
    end
)
Gui.on_click(
    'Quadrants.Button.Toggle',
    function(event)
        toggle_chest(event)
    end
)

local function on_player_created(event)
    event.player = Game.get_player_by_index(event.player_index)
    toggle_chest_status[event.player_index] = true
    toggle(event)
end


local function changed_force()
        update_gui(true)
end


Event.add(defines.events.on_player_created, on_player_created)
Event.on_nth_tick(61, update_gui)
Event.add(defines.events.on_player_changed_force, changed_force)

return gui
