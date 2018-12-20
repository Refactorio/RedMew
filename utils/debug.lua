-- dependencies
local format = string.format
local serialize = serpent.line
local debug_getupvalue = debug.getupvalue

-- this
local Debug = {}

global.debug_message_count = 0

---@return number next index
local function increment()
    local next = global.debug_message_count + 1
    global.debug_message_count = next

    return next
end

---Shows the given message if debug is enabled. Uses serpent to print non scalars.
---@param message table
function Debug.print(message)
    if not _DEBUG then
        return
    end

    if type(message) ~= 'string' and type(message) ~= 'number' and type(message) ~= 'boolean' then
        message = serialize(message)
    end

    message = format('[%d] %s', increment(), tostring(message))
    game.print(message)
    log(message)
end

---Shows the given message if debug is on.
---@param position Position
---@param message string
function Debug.print_position(position, message)
    Debug.print(format('%s %s', serialize(position), message))
end

---Executes the given callback if cheating is enabled.
---@param callback function
function Debug.cheat(callback)
    if _CHEATS then
        callback()
    end
end

--- Returns true if the function is a closure, false otherwise.
-- A closure is a function that contains 'upvalues' or in other words
-- has a reference to a local variable defined outside the function's scope.
-- @param  func<function>
-- @return boolean
function Debug.is_closure(func)
    -- debug_getupvalue returns two values, we only want the first, hence the == true check
    return debug_getupvalue(func, 1) == true 
end

return Debug
