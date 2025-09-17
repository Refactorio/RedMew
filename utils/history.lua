---@class History
--- A class that manages a history buffer with undo/redo capabilities.
local History = {}
History.__index = History

script.register_metatable('RedMew_HistoryClass', History)

local DEFAULT_SIZE = 100
local math_min = math.min
local math_max = math.max
local insert = table.insert
local remove = table.remove

--- Creates a new History instance.
---@param size number? Optional maximum size of the history buffer. Defaults to 100 if not provided or invalid.
---@return History
function History.new(size)
    return setmetatable({
        buffer = {},       -- Table storing the history elements
        index = 0,         -- Current position in the history buffer
        max_size = (size and size > 0 or DEFAULT_SIZE) -- Max number of items to store
    }, History)
end

--- Keeps only the elements within the specified range [left, right].
---@param self History The history object.
---@param left number The starting index of the range (1-based).
---@param right number The ending index of the range (1-based).
local function range(self, left, right)
    local result = {}
    local len = #self.buffer

    left = math_max(1, left)
    right = math_min(right, len)

    for i = left, right do
        insert(result, self.buffer[i])
    end

    self.buffer = result

    if self.index > #self.buffer then
        self.index = #self.buffer
    end
end

--- Returns the current size of the history buffer.
---@param self History The history object.
---@return number
function History:size()
    return #self.buffer
end

--- ADD a new element to the history buffer.
--- If the current position is not at the end, discards all "redo" states.
--- Ensures the buffer does not exceed max_size by trimming oldest entries.
---@param self History The history object.
---@param element any The element to add. Nil elements are ignored.
function History:add(element)
    if element == nil then
        return
    end

    if self.index ~= #self.buffer then
        range(self, 1, self.index)
    end

    insert(self.buffer, element)
    self.index = #self.buffer

    if #self.buffer > self.max_size then
        range(self, 1 + #self.buffer - self.max_size, #self.buffer)
    end
end

--- REMOVE the element at the specified index.
---@param self History The history object.
---@param index number? Optional index to remove; defaults to current index.
function History:remove(index)
    if index == nil then
        index = self.index
    end
    if not self.buffer[index] then
        return
    end
    -- Adjust index if removing current or previous
    if self.index >= index then
        self.index = self.index - 1
    end
    remove(self.buffer, index)
end

--- GET the element at the specified index.
--- If no index is provided, returns the current element.
---@param self History The history object.
---@param index number? Optional index to retrieve; defaults to current index.
---@return any
function History:get(index)
    if index == nil then
        index = self.index
    end
    return self.buffer[index]
end

--- GET the current position index in the history buffer.
---@param self History The history object.
---@return number The current index.
function History:get_index()
    return self.index
end

--- GET the previous element in the history without changing the current index.
---@param self History The history object.
---@return any|nil The previous element or nil if none exists.
function History:peek_previous()
    return self.buffer[self.index - 1]
end

--- GET the next element in the history without changing the current index.
---@param self History The history object.
---@return any|nil The next element or nil if none exists.
function History:peek_next()
    return self.buffer[self.index + 1]
end

--- MOVE to the previous history element, if possible.
--- Updates the current index and returns the element.
---@param self History The history object.
---@return any|nil The previous element, or nil if at the beginning.
function History:previous()
    if not self.buffer[self.index - 1] then
        return nil
    end
    self.index = self.index - 1
    return self.buffer[self.index]
end

--- MOVE to the next history element, if possible.
--- Updates the current index and returns the element.
---@param self History The history object.
---@return any|nil The next element, or nil if at the latest.
function History:next()
    if not self.buffer[self.index + 1] then
        return nil
    end
    self.index = self.index + 1
    return self.buffer[self.index]
end

--- CLEAR the entire history buffer and resets the current index.
---@param self History The history object.
function History:clear()
    self.buffer = {}
    self.index = 0
end

return History
