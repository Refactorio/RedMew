local PriorityQueue = {}

function PriorityQueue.new()
    return {}
end

local function default_comp(a, b)
    return a < b
end

local function HeapifyFromEndToStart(queue, comp)
    comp = comp or default_comp
    local pos = #queue
    while pos > 1 do
        local parent = bit32.rshift(pos, 1) -- integer division by 2
        if comp(queue[pos], queue[parent]) then
            queue[pos], queue[parent] = queue[parent], queue[pos]
            pos = parent
        else
            break
        end
    end
end

local function HeapifyFromStartToEnd(queue, comp)
    comp = comp or default_comp
    local parent = 1
    local smallest = 1
    while true do
        local child = parent * 2
        if child > #queue then
            break
        end
        if comp(queue[child], queue[parent]) then
            smallest = child
        end
        child = child + 1
        if child <= #queue and comp(queue[child], queue[smallest]) then
            smallest = child
        end

        if parent ~= smallest then
            queue[parent], queue[smallest] = queue[smallest], queue[parent]
            parent = smallest
        else
            break
        end
    end
end

function PriorityQueue.size(queue)
    return #queue
end

function PriorityQueue.push(queue, element, comp)
    table.insert(queue, element)
    HeapifyFromEndToStart(queue, comp)
end

function PriorityQueue.pop(queue, comp)
    local element = queue[1]

    queue[1] = queue[#queue]
    queue[#queue] = nil
    HeapifyFromStartToEnd(queue, comp)

    return element
end

function PriorityQueue.peek(queue)
    return queue[1]
end

return PriorityQueue
