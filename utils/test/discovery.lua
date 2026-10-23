local include = require 'utils.test.include'
local matching_path = '^__level__/(.+)$'

-- Includes the tests of every loaded module. Test files load modules of their own, whose tests
-- are then included on the next pass, until no new modules are loaded. The names are taken
-- before each pass, as including adds to package.loaded.
local seen = {}
repeat
    local names = {}
    for name in pairs(_G.package.loaded) do
        if not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    for _, name in pairs(names) do
        name = name:match(matching_path)
        if name then
            name = name:sub(1, -5)
            include(name .. '_tests')
        end
    end
until #names == 0
