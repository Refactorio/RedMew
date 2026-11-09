-- In-game tests for the admin commands that teleport.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Command = require 'utils.command'

Declare.module({'features', 'admin_commands'}, function()
    -- uses an admin player's character, remote view and selection
    Declare.tags('skip-headless')

    Declare.test('/tp moves the character to the entity selected on the map', function(context)
        -- Arrange: a chest selected from the map, far from the character
        local player = context.player
        local character = player.character
        local surface = character.surface
        local start = character.position
        local chest = surface.create_entity {
            name = 'wooden-chest',
            position = {math.floor(start.x) + 90.5, math.floor(start.y) + 0.5},
            force = player.force
        }
        player.set_controller {type = defines.controllers.remote, position = chest.position}
        player.selected = chest
        context:add_teardown(function()
            player.exit_remote_view()
            character.teleport(start)
            chest.destroy()
        end)

        -- Act
        Command._raise_command('tp', player.index, '')

        -- Assert
        local distance = math.sqrt((character.position.x - chest.position.x) ^ 2 + (character.position.y - chest.position.y) ^ 2)
        Assert.is_true(distance < 5, 'the character should be by the chest, but is ' .. distance .. ' tiles from it')
        Assert.equal(defines.controllers.remote, player.controller_type, 'the player should still be in remote view')
    end)
end)
