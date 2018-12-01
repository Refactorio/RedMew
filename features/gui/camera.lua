--[[
Camera, used under MIT license.
Copyright 2018 angelickite

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local Event = require 'utils.event'
local mod_gui = require 'mod-gui'
local Command = require 'utils.command'
local Game = require 'utils.game'
global.camera_users = {}

local zoomlevels = {1.00, 0.75, 0.50, 0.40, 0.30, 0.25, 0.20, 0.15, 0.10, 0.05}
local zoomlevellabels = {'100%', '75%', '50%', '40%', '30%', '25%', '20%', '15%', '10%', '5%'}
local sizelevels = {0, 100, 200, 250, 300, 350, 400, 450, 500}
local sizelevellabels = {'hide', '100x100', '200x200', '250x250', '300x300', '350x350', '400x400', '450x450', '500x500'}

local function update_camera_render(target, targetframe, zoom, size, visible)
    local position = {x = target.position.x, y = target.position.y - 0.5}
    local surface_index = target.surface.index
    local preview_size = size

    local camera = targetframe.camera

    if not camera then
        camera = targetframe.add {type = 'camera', name = 'camera', position = position, surface_index = surface_index, zoom = zoom}
    end

    camera.position = position
    camera.surface_index = surface_index
    camera.zoom = zoom

    camera.style.visible = visible

    camera.style.minimal_width = preview_size
    camera.style.minimal_height = preview_size
    camera.style.maximal_width = preview_size
    camera.style.maximal_height = preview_size
end

local function update_camera_playerselection(targetframe, playerlist)
    local playerselection = targetframe.playerselection

    local playerlabels = {}
    for i = 1, #playerlist do
        local player = playerlist[i]
        playerlabels[i] = {player.name}
    end

    if playerselection then
        playerselection.items = playerlabels
    else
        playerselection = targetframe.add {type = 'drop-down', name = 'playerselection', items = playerlabels, selected_index = 1}
    end

    local target = playerlist[playerselection.selected_index]
    if not target.connected then
        local done = false
        for i = 1, #playerlist do
            if not done then
                local player = playerlist[i]
                -- note(angelickite): there should always be at least one player that is connected, namely the active player itself!
                if player.connected then
                    playerselection.selected_index = i
                    done = true
                end
            end
        end
    end

    return playerselection.selected_index
end

local function update_camera_zoom(targetframe)
    local zoomselection = targetframe.zoomselection

    local zoomlabels = {}
    for i = 1, #zoomlevellabels do
        zoomlabels[i] = {'', '' .. zoomlevellabels[i]}
    end

    if zoomselection then
        zoomselection.items = zoomlabels
    else
        zoomselection = targetframe.add {type = 'drop-down', name = 'zoomselection', items = zoomlabels, selected_index = 3}
    end

    local zoom = zoomlevels[zoomselection.selected_index]
    return zoom
end

local function update_camera_size(targetframe)
    local sizeselection = targetframe.sizeselection

    local sizelabels = {}
    for i = 1, #sizelevellabels do
        sizelabels[i] = {'', '' .. sizelevellabels[i]}
    end

    if sizeselection then
        sizeselection.items = sizelabels
    else
        sizeselection = targetframe.add {type = 'drop-down', name = 'sizeselection', items = sizelabels, selected_index = 4}
    end

    local size = sizelevels[sizeselection.selected_index]
    local visible = (size ~= 0)

    return size, visible
end

local function on_tick()
    for _, player_index in pairs(global.camera_users) do
        local player = Game.get_player_by_index(player_index)
        local mainframeflow = mod_gui.get_frame_flow(player)
        local mainframeid = 'mainframe_' .. player_index
        local mainframe = mainframeflow[mainframeid]
        local headerframe = mainframe.headerframe
        local cameraframe = mainframe.cameraframe
        local selected_target_index = update_camera_playerselection(headerframe, game.connected_players)
        local zoom = update_camera_zoom(headerframe)
        local size, visible = update_camera_size(headerframe)

        update_camera_render(Game.get_player_by_index(selected_target_index), cameraframe, zoom, size, visible)
    end
end

local function camera(_, player)
    local player_index = player.index
    local table_index = table.index_of(global.camera_users, player_index)
    local mainframeflow = mod_gui.get_frame_flow(player)
    local mainframeid = 'mainframe_' .. player_index
    local mainframe = mainframeflow[mainframeid]

    if table_index > 0 then
        mainframe.destroy()
        global.camera_users[table_index] = nil
    else
        if not mainframe then
            mainframe = mainframeflow.add {type = 'frame', name = mainframeid, direction = 'vertical', style = 'captionless_frame'}
            mainframe.style.visible = true
        end

        local headerframe = mainframe.headerframe
        if not headerframe then
            mainframe.add {type = 'frame', name = 'headerframe', direction = 'horizontal', style = 'captionless_frame'}
        end

        local cameraframe = mainframe.cameraframe
        if not cameraframe then
            mainframe.add {type = 'frame', name = 'cameraframe', style = 'captionless_frame'}
        end
        table.insert(global.camera_users, player_index)
    end
end

Command.add('camera', {description = 'Allows you to watch other players', admin_only = false, debug_only = false}, camera)
Event.add(defines.events.on_tick, on_tick)
