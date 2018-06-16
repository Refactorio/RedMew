local Event = require 'utils.event'
local Token = require 'utils.global_token'

Global = {}

local data = {}

function Global.register(tbl, callback)
    local token = Token.register_global(tbl)
    table.insert(data, {tbl = tbl, callback = callback, token = token})
end

Event.on_load(
    function()
        for _, d in ipairs(data) do
            local tbl = Token.get_global(d.token)
            d.callback(tbl)
        end

        data = nil
    end
)

return Global
