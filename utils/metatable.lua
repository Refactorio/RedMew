local Event = require 'utils.event'

--this
local Metatable = {}

global.metatables = {}

function Metatable.set(tbl, mt)
    setmetatable(tbl, mt)
    table.insert(global.metatables, {tbl = tbl, mt = mt})
end


local function on_load()
  for _,obj in pairs(global.metatables) do
    setmetatable(obj.tbl, obj.mt)
  end
end
Event.on_init(on_load)
Event.on_load(on_load)


return Metatable
