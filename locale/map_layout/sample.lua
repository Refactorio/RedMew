--[[
This is a sample file for a map style. You may register new events, but not on_chunk_generated.

Author: Valansch
]]--


--This is contains the module (Do not remove)
local module = {}

local example_variable = "foo"

local function helper_function()
  --helper function code here
end

--This function is called by the framework if the style is enabled.
function module.on_chunk_generated(event)
  game.print("Chunk was generated")
end



--(Do not remove)
return module
--any code past this point will obviously not be executed
