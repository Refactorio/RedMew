local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local RestartMessage = require 'utils.restart_message'

Declare.module({'utils', 'RestartMessage'}, function()
    Declare.test('format_count adds thousands separators', function()
        Assert.equal('58,783', RestartMessage.format_count(58783))
        Assert.equal('1,234,567', RestartMessage.format_count(1234567))
        Assert.equal('999', RestartMessage.format_count(999))
    end)

    Declare.test('format_count drops fractions', function()
        Assert.equal('1,725', RestartMessage.format_count(1725.9))
    end)

    Declare.test('statistic bolds the value', function()
        Assert.equal('- Players: **27**', RestartMessage.statistic('Players', 27))
    end)

    Declare.module('award', function()
        Declare.test('names the player with the most', function()
            local players = {{name = 'a', deaths = 2}, {name = 'b', deaths = 5}, {name = 'c', deaths = 1}}
            Assert.equal('- Most deaths: **b** (5)', RestartMessage.award('Most deaths', players, 'deaths'))
        end)

        Declare.test('is nil when nobody has any', function()
            local players = {{name = 'a', deaths = 0}, {name = 'b', deaths = 0}}
            Assert.is_nil(RestartMessage.award('Most deaths', players, 'deaths'))
            Assert.is_nil(RestartMessage.award('Most deaths', {}, 'deaths'))
        end)

        Declare.test('names everyone who ties', function()
            local players = {{name = 'a', deaths = 5}, {name = 'b', deaths = 1}, {name = 'c', deaths = 5}}
            Assert.equal('- Most deaths: **a, c** (5)', RestartMessage.award('Most deaths', players, 'deaths'))
        end)

        Declare.test('names three who tie and counts the rest', function()
            local players = {}
            for i = 1, 5 do
                players[i] = {name = 'p' .. i, deaths = 3}
            end
            Assert.equal('- Most deaths: **p1, p2, p3** and 2 more (3)', RestartMessage.award('Most deaths', players, 'deaths'))
        end)

        Declare.test('escapes markdown in names', function()
            local players = {{name = 'some_name_here', deaths = 1}}
            Assert.equal('- Most deaths: **some\\_name\\_here** (1)', RestartMessage.award('Most deaths', players, 'deaths'))
        end)

        Declare.test('formats the value', function()
            local players = {{name = 'a', walked = 12345.6}}
            Assert.equal('- Furthest walked: **a** (12,345)', RestartMessage.award('Furthest walked', players, 'walked'))

            local format = function(value)
                return value .. ' fish'
            end
            players = {{name = 'a', fish = 3}}
            Assert.equal('- Seafood lover: **a** (3 fish)', RestartMessage.award('Seafood lover', players, 'fish', format))
        end)
    end)

    Declare.test('build puts sections under bold headings and the footer last', function()
        local message = RestartMessage.build('Title', {
            {name = 'Statistics', lines = {'- one', '- two'}},
            {name = 'Awards', lines = {'- three'}}
        }, 'Footer')

        Assert.equal('Title\\n\\n**Statistics**\\n- one\\n- two\\n\\n**Awards**\\n- three\\n\\nFooter', message)
    end)

    Declare.test('build leaves out empty sections', function()
        local message = RestartMessage.build('Title', {
            {name = 'Statistics', lines = {'- one'}},
            {name = 'Awards', lines = {}}
        })

        Assert.equal('Title\\n\\n**Statistics**\\n- one', message)
    end)
end)
