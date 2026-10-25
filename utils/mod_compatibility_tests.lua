-- In-game tests for the mod compatibility checker. These run whenever mod_compatibility.lua is
-- loaded, i.e. on the maps that need mods. They check what combine() keeps and what check()
-- refuses, using `base` as the one mod every game has and a made-up name for a missing one.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local ModCompatibility = require 'utils.mod_compatibility'

local MISSING = 'redmew-test-no-such-mod'

-- The error check() raises, or nil if it passes.
local function check_error(args)
    local ok, message = pcall(ModCompatibility.check, args)
    if ok then
        return nil
    end
    return message
end

local function contains(text, part)
    return text ~= nil and text:find(part, 1, true) ~= nil
end

Declare.module(
    {'utils', 'mod compatibility'},
    function()
        Declare.test(
            'combine keeps every mod from every list',
            function()
                -- Act
                local combined = ModCompatibility.combine(
                    {dependencies = {{name = 'a'}, {name = 'b'}}},
                    {dependencies = {{name = 'c'}}, incompatibles = {{name = 'd'}}}
                )

                -- Assert
                Assert.equal(3, #combined.dependencies, 'dependencies')
                Assert.equal(1, #combined.incompatibles, 'incompatibles')
                Assert.equal(0, #combined.recommended, 'recommended')
                Assert.equal(0, #combined.discouraged, 'discouraged')
            end
        )

        Declare.test(
            'combine keeps a mod once, at the highest version asked for',
            function()
                -- Act
                local combined = ModCompatibility.combine(
                    {dependencies = {{name = 'a'}, {name = 'b', version = '2.0.0'}}},
                    {dependencies = {{name = 'a', version = '1.0.0'}, {name = 'b', version = '1.5.0'}}}
                )

                -- Assert
                local deps = combined.dependencies
                Assert.equal(2, #deps, 'dependencies')
                Assert.equal('a', deps[1].name, 'first')
                Assert.equal('1.0.0', deps[1].version, 'a version given wins over none')
                Assert.equal('2.0.0', deps[2].version, 'the higher version wins')
            end
        )

        Declare.test(
            'check passes when every dependency is there at a high enough version',
            function()
                -- Act / Assert
                Assert.is_nil(check_error {dependencies = {{name = 'base'}, {name = 'base', version = '1.0.0'}}})
            end
        )

        Declare.test(
            'check refuses a missing dependency and names it',
            function()
                -- Act
                local message = check_error {dependencies = {{name = 'base'}, {name = MISSING, version = '1.2.3'}}}

                -- Assert
                Assert.is_true(contains(message, 'Missing dependencies'), 'message: ' .. tostring(message))
                Assert.is_true(contains(message, MISSING .. ' >= 1.2.3'), 'message: ' .. tostring(message))
                Assert.is_true(not contains(message, '- base'), 'names base, which is there: ' .. tostring(message))
            end
        )

        Declare.test(
            'check refuses a dependency older than asked for',
            function()
                -- Act
                local message = check_error {dependencies = {{name = 'base', version = '99.0.0'}}}

                -- Assert
                Assert.is_true(contains(message, 'base >= 99.0.0'), 'message: ' .. tostring(message))
            end
        )

        Declare.test(
            'check refuses an incompatible mod that is there, and not one that is not',
            function()
                -- Act
                local present = check_error {incompatibles = {{name = 'base'}}}
                local absent = check_error {incompatibles = {{name = MISSING}}}

                -- Assert
                Assert.is_true(contains(present, 'Incompatible mods'), 'message: ' .. tostring(present))
                Assert.is_true(contains(present, '- base'), 'message: ' .. tostring(present))
                Assert.is_nil(absent)
            end
        )
    end
)
