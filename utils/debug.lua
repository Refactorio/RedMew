-- localised functions
local format = string.format
local match = string.match
local gsub = string.gsub
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

--- Takes the table output from debug.getinfo and pretties it
local function cleanup_debug(debug_table)
    local short_src = match(debug_table.source, '/[^/]*/[^/]*$')
    -- require will not return a valid string so short_src may be nil here
    if short_src then
        short_src = gsub(short_src, '%.lua', '')
    end

    return format('[function: %s file: %s line number: %s]', debug_table.name, short_src, debug_table.currentline)
end

---Shows the given message if debug is enabled. Uses serpent to print non scalars.
-- @param message <table|string|number|boolean>
-- @param stack_traceback <number|nil> levels of stack trace to give, defaults to 1 level if nil
function Debug.print(message, trace_levels)
    if not _DEBUG then
        return
    end

    if not trace_levels then
        trace_levels = 2
    else
        trace_levels = trace_levels + 1
    end

    local traceback_string = ''
    if type(message) ~= 'string' and type(message) ~= 'number' and type(message) ~= 'boolean' then
        message = serialize(message)
    end

    message = format('[%d] %s', increment(), tostring(message))

    if trace_levels >= 2 then
        for i = 2, trace_levels do
            local debug_table = debug.getinfo(i)
            if debug_table then
                traceback_string = format('%s -> %s', traceback_string, cleanup_debug(debug_table))
            else
                break
            end
        end
        message = format('%s - Traceback%s', message, traceback_string)
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
