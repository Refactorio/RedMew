-- In-game tests for the Teleport button on train stations. Discovered when the feature is on
-- (config.train_station_teleport.enabled, as on Diggy).
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local TrainStationTeleport = require 'features.train_station_teleport'

Declare.module({'features', 'train_station_teleport'}, function()
    -- uses a player's character, remote view and the train stop's GUI
    Declare.tags('skip-headless')

    Declare.test('the Teleport button on a station opened from the map moves the character there', function(context)
        -- Arrange: a station by the character and one far away, opened from the map
        local player = context.player
        local character = player.character
        local surface = character.surface
        local start = character.position
        local x, y = math.floor(start.x), math.floor(start.y)
        local near = surface.create_entity {name = 'train-stop', position = {x + 3, y + 3}, force = player.force}
        local far = surface.create_entity {name = 'train-stop', position = {x + 101, y + 3}, force = player.force}
        player.set_controller {type = defines.controllers.remote, position = far.position}
        player.opened = far
        context:add_teardown(function()
            player.opened = nil
            player.exit_remote_view()
            character.teleport(start)
            near.destroy()
            far.destroy()
        end)

        local frame
        context:next(function()
            frame = TrainStationTeleport.get('relative_gui')[player.index]
            Assert.valid(frame, 'opening the station should add the Teleport button')

            -- Act
            Helper.click(frame.children[1].children[1])
        end):next(function()
            -- Assert
            local radius = TrainStationTeleport.get('radius')
            local distance = math.sqrt((character.position.x - far.position.x) ^ 2 + (character.position.y - far.position.y) ^ 2)
            Assert.is_true(distance <= radius, 'the character should be by the far station, but is ' .. distance .. ' tiles from it')
            Assert.equal(defines.controllers.remote, player.controller_type, 'the player should still be in remote view')
        end)
    end)
end)
