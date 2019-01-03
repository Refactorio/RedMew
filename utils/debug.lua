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

--- Takes the output from debug.getinfo and strips the function and full source names
local function cleanup_debug(debug_table)
    return format('caller details: name: %s file: %s, line number: %s', debug_table.name, debug_table.short_src, debug_table.currentline)
end

---Shows the given message if debug is enabled. Uses serpent to print non scalars.
-- @param message <table|string|number|boolean>
-- @param no_source <boolean> if true, will omit the source of the debug message
function Debug.print(message, no_source)
    if not _DEBUG then
        return
    end

    if type(message) ~= 'string' and type(message) ~= 'number' and type(message) ~= 'boolean' then
        message = serialize(message)
    end

    message = format('[%d] %s', increment(), tostring(message))
    if not no_source then
        message = format('%s -- %s', message, cleanup_debug(debug.getinfo(2)))
    end
    if game then
        game.print(message)
    end
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
    local i = 1
    while true do
        local n = debug_getupvalue(func, i)

        if n == nil then
            return false
        elseif n ~= '_ENV' then
            return true
        end

        i = i + 1
    end
end

return Debug
