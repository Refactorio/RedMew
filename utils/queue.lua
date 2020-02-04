local Queue = {}

function Queue.new()
    local queue = {_head = 1, _tail = 1}
    return queue
end

function Queue.size(queue)
    return queue._head - queue._tail
end

function Queue.push(queue, element)
    local index = queue._head
    queue[index] = element
    queue._head = index + 1
end

--- Pushes the element such that it would be the next element pop'ed.
function Queue.push_to_end(queue, element)
    local index = queue._tail - 1
    queue[index] = element
    queue._tail = index
end

function Queue.peek(queue)
    return queue[queue._tail]
end

function Queue.peek_start(queue)
    return queue[queue._head - 1]
end

function Queue.peek_index(queue, index)
    return queue[queue._tail + index - 1]
end

function Queue.pop(queue)
    local index = queue._tail

    local element = queue[index]
    queue[index] = nil

    if element then
        queue._tail = index + 1
    end

    return element
end

function Queue.to_array(queue)
    local n = 1
    local res = {}

    for i = queue._tail, queue._head - 1 do
        res[n] = queue[i]
        n = n + 1
    end

    return res
end

function Queue.pairs(queue)
    local index = queue._tail
    return function()
        local element = queue[index]

        if element then
            local old = index
            index = index + 1
            return old, element
        else
            return nil
        end
    end
end

return Queue
