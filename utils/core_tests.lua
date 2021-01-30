local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Core = require 'utils.core'

local non_breaking_space = '​' -- This is \u200B an invisible space charcater.

Declare.module({'utils', 'Core'}, function()
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
end)