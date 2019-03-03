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

local player_switched_force = script.generate_event_name()

local quadrant_message = {
    {
        title = 'Research and command center',
        msg = [[
                Our main objective is to provide the region with new scientific discoveries

                Secondary we are the central command hub
                We provide the region with military equipment
        ]]
    },
    {
        title = 'Intermediate production and mining',
        msg = [[
                Our main objective is to provide the region with intermediate products

                We primarily supply electronic circuits in various densities
                We're also the area with the highest quality steel!

                Initial survey shows increased resources in this area
        ]]
    },
    {
        title = 'Oil and high tech production',
        msg = [[
                Our main objective is to provide the region with oil based products

                Secondary we are the regions technological leader
                We provide the region with various high technology (and radioactive) products
        ]]
    },
    {
        title = 'Logistical production',
        msg = [[
                Our main objective is to provide the region with logistical solutions

                We primarily supply belt and bot based solutions
                We're also specialized in high performance train networks!
        ]]
    }
}

local function teleport(event, quadrant)
    local player = event.player
    local toggle_status = toggle_chest_status[player.index]
    if
        (abs(player.position.x) <= 4 and abs(player.position.y) <= 4) or
            (player.get_inventory(defines.inventory.player_main).is_empty() and
                player.get_inventory(defines.inventory.player_trash).is_empty()) or
            ((abs(player.position.x) >= 23 and (abs(player.position.y) >= 23)) and toggle_status == 'ON' and
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
        script.raise_event(player_switched_force, {extra = 'data'})
    else
        local text = '## - You are too heavy for teleportation! Empty your inventory before switching quadrant!'
        player.print(text, Color.red)
        text = '## - You may need to move of the bridge'
        player.print(text, Color.red)
    end
end

local function redraw_quadrant_button(data, player)
    local left_flow = data.left_flow_btn1
    local right_flow = data.right_flow_btn1
    Gui.clear(left_flow)
    Gui.clear(right_flow)

    left_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.2',
            caption = 'Intermediate and Mining (' .. #game.forces['quadrant2'].players .. ')'
        }
    )
    right_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.1',
            caption = 'Science and Military (' .. #game.forces['quadrant1'].players .. ')'
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
            caption = 'Oil and High Tech (' .. #game.forces['quadrant3'].players .. ')'
        }
    )
    right_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.4',
            caption = 'Logistics and Transport (' .. #game.forces['quadrant4'].players .. ')'
        }
    )
end

local function redraw_chest_button(data, player)
    local left_flow = data.chest_button_left_flow
    local toggle_status = toggle_chest_status[player.index]
    Gui.clear(left_flow)

    local button =
        left_flow.add(
        {
            type = 'button',
            name = 'Quadrants.Button.Toggle',
            caption = 'Toggle inventory empty to chest. Currently: ' .. toggle_status,
            tooltip = 'If on:\nYour inventory will be emptied in a chest, when you switch quadrant'
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
    local label = label_flow.add {type = 'label', caption = 'Welcome to Redmew - Quadrants!'}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    label_flow = content_flow.add {type = 'flow'}
    label = label_flow.add {type = 'label', caption = 'While in spawn, you can switch quadrant!'}
    label.style.single_line = false
    label.style.font = 'default'

    label_flow = content_flow.add {type = 'flow'}
    label = label_flow.add {type = 'label', caption = "Go ahead and pick a quadrant you'd like to help out!"}
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

    redraw_quadrant_button(data, player)
    redraw_chest_button(data, player)

    Gui.set_data(frame, data)
end

local function update_gui(_, force_update)
    local players = game.connected_players
    for i = #players, 1, -1 do
        local p = players[i]
        local frame = p.gui.left['Quadrants.Switch_Team']
        local data = {player = p}

        if frame and frame.valid and (abs(p.position.x) >= 128 or abs(p.position.y) >= 128) then
            toggle(data)
        elseif not frame and not (abs(p.position.x) > 128 or abs(p.position.y) > 128) then
            toggle(data)
        elseif force_update then
        data['trigger'] = true
            toggle(data)
        end
    end
end

local function toggle_chest(event)
    local toggle_status = toggle_chest_status[event.player.index]
    if toggle_status == 'OFF' then
        toggle_chest_status[event.player.index] = 'ON'
    else
        toggle_chest_status[event.player.index] = 'OFF'
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
    toggle_chest_status[event.player_index] = 'OFF'
    toggle(event)
end

Event.add(
    player_switched_force,
    function(event)
        update_gui(nil, true)
    end
)

Event.add(defines.events.on_player_created, on_player_created)
Event.on_nth_tick(61, update_gui)

return gui
