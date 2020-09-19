local error = error
local concat = table.concat

local Public = {}

function Public.equal(a, b, optional_message)
    if a == b then
        return
    end

    local message = concat {tostring(a), ' ~= ', tostring(b)}
    if optional_message then
        message[message + 1] = ' - '
        message[message + 1] = optional_message
    end
    error(message, 2)
end

return Public
