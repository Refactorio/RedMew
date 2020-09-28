local require = require
local pcall = pcall

function find_all_tests()
    local loaded = _G.package.loaded

    for name in pairs(loaded) do
        pcall(require, name .. '_test')
        pcall(require, name .. '_tests')
    end
end

find_all_tests()
