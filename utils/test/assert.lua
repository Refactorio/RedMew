local error = error
local concat = table.concat

local Public = {}

function Public.equal(a, b, optional_message)
    if a == b then
        return
    end

    local message = {tostring(a), ' ~= ', tostring(b)}
    if optional_message then
        message[#message + 1] = ' - '
        message[#message + 1] = optional_message
    end

    message = concat(message)
    error(message, 2)
end

function Public.is_true(condition, optional_message)
    if not condition then
        error(optional_message or 'condition was not true', 2)
    end
end

return Public
