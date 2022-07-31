local floor = math.floor
local getmetatable = getmetatable
local setmetatable = setmetatable

local PriorityQueue = {}

local function default_comparator(a, b)
    return a < b
end

--- Min heap implementation of a priority queue. Smaller elements, as determined by the comparator,
-- have a higher priority.
-- @param comparator <function|nil> the comparator function used to compare elements, if nil the
-- deafult comparator is used.
-- @usage
-- local PriorityQueue = require 'utils.priority_queue'
--
-- local queue = PriorityQueue.new()
-- PriorityQueue.push(queue, 4)
-- PriorityQueue.push(queue, 7)
-- PriorityQueue.push(queue, 2)
--
-- game.print(PriorityQueue.pop(queue)) -- 2
-- game.print(PriorityQueue.pop(queue)) -- 4
-- game.print(PriorityQueue.pop(queue)) -- 7
function PriorityQueue.new(comparator)
    if comparator == nil then
        comparator = default_comparator
    end

    local mt = {comparator = comparator}

    return setmetatable({}, mt)
end

function PriorityQueue.load(self, comparator)
    if comparator == nil then
        comparator = default_comparator
    end

    local mt = {comparator = comparator}

    return setmetatable(self or {}, mt)
end

local function get_comparator(self)
    local mt = getmetatable(self)
    return mt.comparator
end

local function heapify_from_end_to_start(self)
    local comparator = get_comparator(self)
    local pos = #self
    while pos > 1 do
        local parent = floor(pos * 0.5)
        local a, b = self[pos], self[parent]
        if comparator(a, b) then
            self[pos], self[parent] = b, a
            pos = parent
        else
            break
        end
    end
end

local function heapify_from_start_to_end(self)
    local comparator = get_comparator(self)
    local parent = 1
    local smallest = 1
    local count = #self
    while true do
        local child = parent * 2
        if child > count then
            break
        end
        if comparator(self[child], self[parent]) then
            smallest = child
        end
        child = child + 1
        if child <= count and comparator(self[child], self[smallest]) then
            smallest = child
        end

        if parent ~= smallest then
            self[parent], self[smallest] = self[smallest], self[parent]
            parent = smallest
        else
            break
        end
    end
end

--- Returns the number of the number of elements in the priority queue.
function PriorityQueue.size(self)
    return #self
end

-- Inserts an element into the priority queue.
function PriorityQueue.push(self, element)
    self[#self + 1] = element
    heapify_from_end_to_start(self)
end

-- Removes and returns the highest priority element from the priority queue.
-- If the priority queue is empty returns nil.
function PriorityQueue.pop(self)
    local element = self[1]

    self[1] = self[#self]
    self[#self] = nil
    heapify_from_start_to_end(self)

    return element
end

-- Returns, without removing, the highest priority element from the priority queue.
-- If the priority queue is empty returns nil.
function PriorityQueue.peek(self)
    return self[1]
end

return PriorityQueue
