-- dependencies
local Inspect = require 'map_gen.Diggy.Inspect'

-- this
local Debug = {}

-- private state
local debug = false
local cheats = false

function Debug.enable_debug()
    debug = true
end

function Debug.disable_debug()
    debug = false
end

function Debug.enable_cheats()
    cheats = true
end

function Debug.disable_cheats()
    cheats = true
end

local message_count = 0

--[[--
    Shows the given message if _DEBUG == true.

    @param message string
]]
function Debug.print(message)
    message_count = message_count + 1
    if (debug) then
        game.print('[' .. message_count .. '] ' .. message)
    end
end

--[[--
    Shows the given message if _DEBUG == true for a given position.

    @param x number
    @param y number
    @param message string
]]
function Debug.printPosition(x, y, message)
    message_count = message_count + 1
    if (debug) then
        game.print('[' .. message_count .. '] {x=' .. x .. ', y=' .. y .. '} ' .. message)
    end
end

--[[--
    Executes the given callback if _DIGGY_CHEATS == true.

    @param callback function
]]
function Debug.cheat(callback)
    if (cheats) then
        callback()
    end
end

--[[--
    Inspects T and prints it.

    @param T any
]]
function Debug.inspect(T)
    if (debug) then
        game.print(Inspect.inspect(T))
    end
end

return Debug
