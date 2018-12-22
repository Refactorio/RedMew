local Token = require 'utils.token'
local Global = require 'utils.global'

local Gui = {}

local data = {}

Global.register(
    data,
    function(tbl)
        data = tbl
    end
)

function Gui.uid_name()
    return tostring(Token.uid())
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Gui.set_data(element, value)
    return
end

return Gui
