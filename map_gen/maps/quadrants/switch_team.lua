local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'
local abs = math.abs
local Color = require 'resources.color_presets'
local Popup = require 'features.gui.popup'

local gui = {}

local spawn_locations = {
    quadrant_1 = {64, -64},
    quadrant_2 = {-64, -64},
    quadrant_3 = {-64, 64},
    quadrant_4 = {64, 64}
}

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
    },
}

local function teleport(event, quadrant)
    local player = event.player

    if (abs(player.position.x) <= 4 and abs(player.position.y) <= 4) or (player.get_inventory(1).is_empty() and player.get_inventory(2).is_empty() and (player.get_inventory(8) or player.get_inventory(3).is_empty())) then
        player.teleport(spawn_locations['quadrant_'..quadrant])
        player.force = game.forces['quadrant'..quadrant]
        Popup.player(player, quadrant_message[quadrant].msg, quadrant_message[quadrant].title, nil, 'Quadrants.quadrant_description')
    else
        local text = '## - You are too heavy for teleportation! Empty your inventory before switching quadrant!'
        player.print(text, Color.red)
    end
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left['Quadrants.Switch_Team']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        return
    end

    frame = left.add({name = 'Quadrants.Switch_Team', type = 'frame', direction = 'vertical'})

    local content_flow = frame.add {type = 'flow', direction = 'vertical'}
    local label_flow = content_flow.add {type = 'flow'}

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = "Welcome to Redmew - Quadrants!"}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    local label_flow = content_flow.add {type = 'flow'}
    local label = label_flow.add {type = 'label', caption = "While in spawn, you can switch quadrant!"}
    label.style.single_line = false
    label.style.font = 'default'

    local label_flow = content_flow.add {type = 'flow'}
    local label = label_flow.add {type = 'label', caption = "Go ahead and pick a quadrant you'd like to help out!"}
    label.style.single_line = false
    label.style.font = 'default'

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = content_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    local right_flow = content_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.align = 'right'
    right_flow.style.horizontally_stretchable = true

    left_flow.add({type = 'button', name = 'Quadrants.Button.2', caption = 'Intermediate and Mining'})
    right_flow.add({type = 'button', name = 'Quadrants.Button.1', caption = 'Science and Military'})

    local content_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = content_flow.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    local right_flow = content_flow.add {type = 'flow', direction = 'horizontal'}
    right_flow.style.align = 'right'
    right_flow.style.horizontally_stretchable = true

    left_flow.add({type = 'button', name = 'Quadrants.Button.3', caption = 'Oil and High Tech'})
    right_flow.add({type = 'button', name = 'Quadrants.Button.4', caption = 'Logistics and Transport'})

    local data = {
        frame = frame,
    }

    Gui.set_data(frame, data)
end

Gui.on_click('Quadrants.Button.1', function(event) teleport(event, 1) end)
Gui.on_click('Quadrants.Button.2', function(event) teleport(event, 2) end)
Gui.on_click('Quadrants.Button.3', function(event) teleport(event, 3) end)
Gui.on_click('Quadrants.Button.4', function(event) teleport(event, 4) end)


local function on_player_created(event)
    event.player = Game.get_player_by_index(event.player_index)
    toggle(event)
end

local function update_gui()
    local players = game.connected_players
    for i = #players, 1, -1 do
        local p = players[i]
        local frame = p.gui.left['Quadrants.Switch_Team']
        local data = {player = p}

        if frame and frame.valid and (abs(p.position.x) >= 128 or abs(p.position.y) >= 128) then
            toggle(data)
        elseif not frame and not (abs(p.position.x) > 128 or abs(p.position.y) > 128) then
            toggle(data)
        end
    end
end

Event.add(defines.events.on_player_created, on_player_created)
Event.on_nth_tick(61, update_gui)

return gui
