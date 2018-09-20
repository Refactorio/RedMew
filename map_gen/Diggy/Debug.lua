-- dependencies

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
    if type(message) ~= 'string' and type(message) ~= 'number' then message = type(message) end
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
function Debug.printPosition(position, message)
    message = message or ''
    if type(message) ~= 'string' and type(message) ~= 'number' then message = type(message) end
    message_count = message_count + 1
    if (debug) then
        game.print('[' .. message_count .. '] {x=' .. position.x .. ', y=' .. position.y .. '} ' .. message)
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

return Debug
