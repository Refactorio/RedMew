local Queue = {}

function Queue.new()
    local queue = {_head = 0, _tail = 0}
    return queue
end

function Queue.size(queue)
    return queue._tail - queue._head
end

function Queue.push(queue, element)
    local index = queue._head
    queue[index] = element
    queue._head = index - 1
end

function Queue.peek(queue)
    return queue[queue._tail]
end

function Queue.pop(queue)
    local index = queue._tail

    local element = queue[index]
    queue[index] = nil

    if element then
        queue._tail = index - 1
    end
    return element
end

return Queue
