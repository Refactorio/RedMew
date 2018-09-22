local Event = require 'utils.event'
local Token = require 'utils.global_token'

local Global = {}

local load_data = {}
local init_data = {}

function Global.register(tbl, callback)
    local token = Token.register_global(tbl)
    table.insert(load_data, {callback = callback, token = token})
end

function Global.register_init(tbl, init_handler, callback)
    local token = Token.register_global(tbl)
    table.insert(load_data, {callback = callback, token = token})

    table.insert(init_data, {token = token, init_handler = init_handler, callback = callback})
end

Event.on_load(
    function()
        for _, d in ipairs(load_data) do
            local tbl = Token.get_global(d.token)
            d.callback(tbl)
        end

        load_data = nil
        init_data = nil
    end
)

Event.on_init(
    function()
        for _, d in ipairs(init_data) do
            local tbl = Token.get_global(d.token)
            d.init_handler(tbl)
            d.callback(tbl)
        end

        load_data = nil
        init_data = nil
    end
)

return Global
