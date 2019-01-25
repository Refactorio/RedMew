local Event = require 'utils.event_core'
local Token = require 'utils.token'

local Global = {}

--- This registers a table to be called back on_load, creating the effect of persistent storage
-- @param tbl <table>
-- @param name <string> an optional identifier for the module registering data in the tokens table
-- @param callback <function>
function Global.register(tbl, callback, name)
    local token = Token.register_global(tbl, name)

    Event.on_load(
        function()
            callback(Token.get_global(token))
        end
    )
end

--- This registers a table to be called back on_load, creating the effect of persistent storage
-- This is different from register in that it runs the init_handler and callback function on_init,
-- creating an initial state for the data
-- @param tbl <table>
-- @param init_handler <function>
-- @param name <string> an optional identifier for the module registering data in the tokens table
-- @param callback <function>
function Global.register_init(tbl, init_handler, callback, name)
    local token = Token.register_global(tbl, name)

    Event.on_init(
        function()
            init_handler(tbl)
            callback(tbl)
        end
    )

    Event.on_load(
        function()
            callback(Token.get_global(token))
        end
    )
end

return Global
