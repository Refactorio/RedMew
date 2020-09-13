local Global = require 'utils.global'

local Public = {
    data = {}
}

_G.danger_ore_shared_globals = Public.data

Global.register(
    Public.data,
    function(tbl)
        Public.data = tbl
        _G.danger_ore_shared_globals = tbl
    end
)

return Public
