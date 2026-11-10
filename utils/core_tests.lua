local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Core = require 'utils.core'

local non_breaking_space = '​' -- This is \u200B an invisible space charcater.

Declare.module({
    'utils',
    'Core'
}, function()
    Declare.module('sanitise_string_for_discord', function()
        Declare.test('escapes markdown', function()
            local actual = Core.sanitise_string_for_discord('**a**_b_~c~`d`|e|>f')
            Assert.equal('\\*\\*a\\*\\*\\_b\\_\\~c\\~\\`d\\`\\|e\\|\\>f', actual)
        end)

        -- This test is making sure backslash '\' is escaped first, else there would be a different number of backslashes.
        Declare.test('escapes backslash', function()
            local actual = Core.sanitise_string_for_discord('\\*abc\\*')
            Assert.equal('\\\\\\*abc\\\\\\*', actual)
        end)

        Declare.test('escapes mention', function()
            local actual = Core.sanitise_string_for_discord('@grilledham')
            Assert.equal('@' .. non_breaking_space .. 'grilledham', actual)
        end)
    end)

    Declare.module('format_time', function()
        local test_cases = {
            {
                name = '0 seconds',
                ticks = 0,
                include_seconds = true,
                expected = '0 seconds'
            },
            {
                name = '1 second',
                ticks = 60,
                include_seconds = true,
                expected = '1 second'
            },
            {
                name = '2 seconds',
                ticks = 60 * 2,
                include_seconds = true,
                expected = '2 seconds'
            },
            {
                name = '0 minutes',
                ticks = 0,
                include_seconds = nil,
                expected = '0 minutes'
            },
            {
                name = '1 minute',
                ticks = 60 * 60,
                include_seconds = nil,
                expected = '1 minute'
            },
            {
                name = '2 minutes',
                ticks = 60 * 60 * 2,
                include_seconds = nil,
                expected = '2 minutes'
            },
            {
                name = '1 minute 1 second',
                ticks = 61 * 60,
                include_seconds = true,
                expected = '1 minute 1 second'
            },
            {
                name = '1 minute 5 seconds',
                ticks = 65 * 60,
                include_seconds = true,
                expected = '1 minute 5 seconds'
            },
            {
                name = '1 minute no seconds',
                ticks = 65 * 60,
                include_seconds = false,
                expected = '1 minute'
            },
            {
                name = '1 minute no seconds (include seconds)',
                ticks = 60 * 60,
                include_seconds = true,
                expected = '1 minute'
            },
            {
                name = '59 minutes',
                ticks = 60 * (60 * 59 + 59),
                include_seconds = nil,
                expected = '59 minutes'
            },
            {
                name = '59 minutes 59 seconds',
                ticks = 60 * (60 * 59 + 59),
                include_seconds = true,
                expected = '59 minutes 59 seconds'
            },
            {
                name = '1 hour',
                ticks = 60 * 60 * 60,
                include_seconds = nil,
                expected = '1 hour'
            },
            {
                name = '1 hour (include seconds)',
                ticks = 60 * 60 * 60,
                include_seconds = true,
                expected = '1 hour'
            },
            {
                name = '2 hours',
                ticks = 60 * 60 * 60 * 2,
                include_seconds = nil,
                expected = '2 hours'
            },
            {
                name = '1 hour 1 minute',
                ticks = 60 * 61 * 60,
                include_seconds = nil,
                expected = '1 hour 1 minute'
            },
            {
                name = '1 hour 2 minutes',
                ticks = 60 * 62 * 60,
                include_seconds = nil,
                expected = '1 hour 2 minutes'
            },
            {
                name = '1 hour 1 minute (include seconds)',
                ticks = 60 * 61 * 60,
                include_seconds = true,
                expected = '1 hour 1 minute'
            },
            {
                name = '1 hour 1 minute 1 second',
                ticks = 60 * (61 * 60 + 1),
                include_seconds = true,
                expected = '1 hour 1 minute 1 second'
            },
            {
                name = '1 hour 1 minute 2 seconds',
                ticks = 60 * (61 * 60 + 2),
                include_seconds = true,
                expected = '1 hour 1 minute 2 seconds'
            },
            {
                name = '1 hour 1 minute no seconds',
                ticks = 60 * (61 * 60 + 1),
                include_seconds = false,
                expected = '1 hour 1 minute'
            },
            {
                name = '1 hour 1 second',
                ticks = 60 * (60 * 60 + 1),
                include_seconds = true,
                expected = '1 hour 1 second'
            },
            {
                name = '1 hour 2 seconds',
                ticks = 60 * (60 * 60 + 2),
                include_seconds = true,
                expected = '1 hour 2 seconds'
            },
            {
                name = '1 hour no seconds',
                ticks = 60 * (60 * 60 + 1),
                include_seconds = false,
                expected = '1 hour'
            }
        }

        for _, case in pairs(test_cases) do
            Declare.test(case.name, function()
                local actual = Core.format_time(case.ticks, case.include_seconds)
                Assert.equal(case.expected, actual)
            end)
        end
    end)

    Declare.module('teleport_player', function()
        -- uses a player's character and remote view
        Declare.tags('skip-headless')

        Declare.test('moves the character in remote view and leaves the view where it is', function(context)
            -- Arrange: looking at the map somewhere else, as when a station is opened from the map
            local player = context.player
            local character = player.character
            local start = character.position
            local destination = {x = math.floor(start.x) + 30.5, y = math.floor(start.y) + 0.5}
            local view = {x = math.floor(start.x) + 80.5, y = math.floor(start.y) + 80.5}
            player.set_controller {type = defines.controllers.remote, position = view}
            context:add_teardown(function()
                player.exit_remote_view()
                character.teleport(start)
            end)

            -- Act
            local teleported = Core.teleport_player(player, destination)

            -- Assert
            local where = serpent.line(character.position)
            Assert.is_true(teleported, 'teleport_player should say it teleported the player')
            Assert.equal(destination.x, character.position.x, 'the character should be at the destination, not ' .. where)
            Assert.equal(destination.y, character.position.y, 'the character should be at the destination, not ' .. where)
            Assert.equal(defines.controllers.remote, player.controller_type, 'the player should still be in remote view')
            Assert.equal(view.x, player.position.x, 'the view should not have moved')
        end)

        Declare.test('moves the character to another surface in remote view', function(context)
            -- Arrange: looking at the map, as a Frontier player may be when a round ends
            local player = context.player
            local character = player.character
            local start, start_surface = character.position, character.surface
            local other = game.create_surface('teleport_player_test')
            player.set_controller {type = defines.controllers.remote, position = {start.x + 80, start.y + 80}}
            context:add_teardown(function()
                player.exit_remote_view()
                character.teleport(start, start_surface)
                game.delete_surface(other)
            end)

            -- Act
            local teleported = Core.teleport_player(player, {0, 0}, other)

            -- Assert
            Assert.is_true(teleported, 'teleport_player should say it teleported the player')
            Assert.equal(other.name, character.surface.name, 'the character should be on the other surface')
        end)

        Declare.test('teleports a player who has no character', function(context)
            -- Arrange: a player without a character, as in god mode
            local player = context.player
            local character = player.character
            local start = character.position
            local destination = {x = math.floor(start.x) + 30.5, y = math.floor(start.y) + 0.5}
            player.set_controller {type = defines.controllers.god}
            context:add_teardown(function()
                player.set_controller {type = defines.controllers.character, character = character}
            end)

            -- Act
            local teleported = Core.teleport_player(player, destination)

            -- Assert
            local where = serpent.line(player.position)
            Assert.is_true(teleported, 'teleport_player should say it teleported the player')
            Assert.equal(destination.x, player.position.x, 'the player should be at the destination, not ' .. where)
            Assert.equal(destination.y, player.position.y, 'the player should be at the destination, not ' .. where)
        end)
    end)
end)
