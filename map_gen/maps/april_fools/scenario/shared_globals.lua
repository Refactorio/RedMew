local Global = require 'utils.global'

local Public = {
    data = {}
}

_G.april_fools_shared_globals = Public.data

Global.register(
    Public.data,
    function(tbl)
        Public.data = tbl
        _G.april_fools_shared_globals = tbl
    end
)

return Public
