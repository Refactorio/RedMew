local Declare = require 'utils.test.declare'
local PollUtils = require 'utils.poll_utils'
local Assert = require 'utils.test.assert'

Declare.module({
    'utils',
    'poll_utils',
    'get_poll_winner'
}, function()
    Declare.test('picks most voted answer', function()
        -- Arrange
        local answers = {
            {
                voted_count = 0
            },
            {
                voted_count = 3
            },
            {
                voted_count = 1
            }
        }

        -- Act
        local actual = PollUtils.get_poll_winner(answers)

        -- Assert
        Assert.equal(2, actual)
    end)

    Declare.test('picks from tied answers', function()
        -- Arrange
        local answers = {
            {
                voted_count = 0
            },
            {
                voted_count = 3
            },
            {
                voted_count = 1
            },
            {
                voted_count = 3
            }
        }

        local rng = function(count)
            Assert.equal(2, count)
            return 2 -- pick last.
        end

        -- Act
        local actual = PollUtils.get_poll_winner(answers, rng)

        -- Assert
        Assert.equal(4, actual)
    end)

    Declare.test('picks from tied answers all zero', function()
        -- Arrange
        local answers = {
            {
                voted_count = 0
            },
            {
                voted_count = 0
            },
            {
                voted_count = 0
            }
        }

        local rng = function(count)
            Assert.equal(3, count)
            return 2 -- pick middle.
        end

        -- Act
        local actual = PollUtils.get_poll_winner(answers, rng)

        -- Assert
        Assert.equal(2, actual)
    end)

    Declare.test('returns nil when no answers', function()
        -- Arrange
        local answers = {}

        -- Act
        local actual = PollUtils.get_poll_winner(answers)

        -- Assert
        Assert.equal(nil, actual)
    end)
end)
