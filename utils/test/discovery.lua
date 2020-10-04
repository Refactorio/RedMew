local include = require 'utils.test.include'

for name in pairs(_G.package.loaded) do
    include(name .. '_tests')
end
