local Token = {}

global.tokens = {}

function Token.register_global(var)
    local c = #global.tokens + 1

    global.tokens[c] = var

    return c
end

local uid_counter = 0

function Token.uid()
    uid_counter = uid_counter + 1

    return uid_counter
end

return Token
