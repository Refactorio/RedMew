local include = require 'utils.test.include'
local matching_path = '^__level__/(.+)$'

for name in pairs(_G.package.loaded) do
    name = name:match(matching_path)
    if name then
        name = name:sub(1, -5)
        include(name .. '_tests')
    end
end
