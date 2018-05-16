local Token = {}

local tokens = {}

local counter = 1

function Token.register(var)
    local c = counter

    tokens[c] = var
    counter = c + 1

    return c
end

function Token.get(token_id)
    return tokens[token_id]
end

global.tokens = {}

function Token.register_global(var)
    local c = #global.tokens + 1

    global.tokens[c] = var

    return c
end

function Token.get_global(token_id)
    return global.tokens[token_id]
end

return Token