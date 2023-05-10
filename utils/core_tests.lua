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
end)
