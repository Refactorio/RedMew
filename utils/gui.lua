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
    if _DEBUG then
        -- https://stackoverflow.com/questions/48402876/getting-current-file-name-in-lua
        local filename = debug.getinfo(2, 'S').source:match('^.+/(.+)$'):sub(1, -5)
        return filename .. ',' .. Token.uid()
    else
        return tostring(Token.uid())
    end
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Gui.set_data(element, value)
    data[element.player_index * 0x100000000 + element.index] = value
end

return Gui
